import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:nova_alianca_core/nova_alianca_core.dart';

import 'usuario_model.dart';

class AuthService {
  // Dependências resolvidas sob demanda. Além de evitar trabalho antes de uma
  // ação de autenticação, isto permite que os testes do RootGate substituam o
  // serviço sem inicializar um app Firebase real.
  FirebaseAuth get _auth => FirebaseAuth.instance;
  FirebaseFirestore get _db => FirebaseFirestore.instance;

  GoogleSignIn? _googleSignInInstancia;
  GoogleSignIn get _googleSignIn => _googleSignInInstancia ??= GoogleSignIn();

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get usuarioFirebase => _auth.currentUser;

  Future<UserCredential> login(String email, String senha) {
    return _auth.signInWithEmailAndPassword(email: email, password: senha);
  }

  /// Cadastro por e-mail vinculado a uma igreja.
  ///
  /// Cria dois documentos em UM batch:
  ///   `usuarios/{uid}`                     — identidade (sem autorização);
  ///   `igrejas/{igrejaId}/membros/{uid}`   — vínculo PENDENTE.
  ///
  /// Os dois precisam nascer juntos: um usuário sem vínculo não aparece em
  /// "Cadastros pendentes" de nenhuma unidade e fica invisível para a
  /// liderança — cadastro perdido, sem erro visível.
  ///
  /// `perfil` e `status` NÃO vão para `usuarios/{uid}`: as Rules recusam
  /// (`hasOnly`) e autorização pertence ao vínculo da unidade.
  Future<UserCredential> cadastrar({
    required String email,
    required String senha,
    required String nome,
    required String telefone,
    required IgrejaId igrejaId,
    QualificacaoUsuario? qualificacao,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: senha,
    );

    final uid = credential.user!.uid;

    try {
      await _provisionar(
        uid: uid,
        nome: nome,
        email: email,
        telefone: telefone,
        igrejaId: igrejaId,
        qualificacao: qualificacao,
      );
    } catch (erro) {
      // A conta do Auth já existe, mas sem os documentos ela não serve para
      // nada e também bloquearia uma nova tentativa com "e-mail já em uso".
      // Como acabou de ser criada, a autenticação é recente e `delete()` deve
      // ser permitido. Mesmo se a limpeza remota falhar, encerramos a sessão
      // para não prender a pessoa numa conta parcialmente provisionada.
      try {
        await credential.user?.delete();
      } catch (_) {
        // Preserva o erro original do provisionamento. Uma conta residual
        // ainda pode ser removida pelo fluxo explícito de recuperação.
      } finally {
        await _auth.signOut();
      }
      rethrow;
    }

    return credential;
  }

  /// Escreve identidade e vínculo pendente num único batch.
  Future<void> _provisionar({
    required String uid,
    required String nome,
    required String email,
    required String telefone,
    required IgrejaId igrejaId,
    String? fotoUrl,
    QualificacaoUsuario? qualificacao,
  }) async {
    final batch = _db.batch();

    batch.set(
      _db.collection('usuarios').doc(uid),
      mapaDeCriacaoUsuario(
        nome: nome,
        email: email,
        telefone: telefone,
        igrejaPrincipalId: igrejaId.valor,
        fotoUrl: fotoUrl,
        dadosPessoais: qualificacao?.toMap(),
      ),
    );

    // Espelha exatamente o que as Rules aceitam no autocadastro: sempre
    // pendente, sempre membro, sempre sem funções administrativas.
    batch.set(
      _db
          .collection('igrejas')
          .doc(igrejaId.valor)
          .collection('membros')
          .doc(uid),
      {
        'perfil': PerfilComunitario.membro.valor,
        'status': StatusVinculo.pendente.valor,
        'funcoes_admin': <String>[],
        'ministerio_ids': <String>[],
        'criado_em': FieldValue.serverTimestamp(),
      },
    );

    await batch.commit();
  }

  /// Login/cadastro com Google.
  ///
  /// Retorna `null` se o usuário cancelar. No PRIMEIRO acesso é obrigatório
  /// informar [igrejaId] — sem unidade não há vínculo, e sem vínculo o
  /// cadastro não chega a lugar nenhum. Em acessos seguintes o parâmetro é
  /// ignorado.
  Future<UserCredential?> entrarComGoogle({IgrejaId? igrejaId}) async {
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) return null; // cancelado pelo usuário

    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final userCred = await _auth.signInWithCredential(credential);
    final user = userCred.user!;

    final jaExiste =
        (await _db.collection('usuarios').doc(user.uid).get()).exists;
    if (jaExiste) return userCred;

    if (igrejaId == null) {
      // Não deixa uma conta autenticada sem documento: a próxima tela ficaria
      // em "Preparando sua conta..." para sempre.
      await _auth.signOut();
      throw const IgrejaObrigatoriaNoCadastro();
    }

    try {
      await _provisionar(
        uid: user.uid,
        nome: user.displayName ?? '',
        email: user.email ?? '',
        telefone: user.phoneNumber ?? '',
        igrejaId: igrejaId,
        fotoUrl: user.photoURL,
      );
    } catch (erro) {
      await _auth.signOut();
      rethrow;
    }

    return userCred;
  }

  /// `true` quando a conta autenticada ainda não tem `usuarios/{uid}` — ou
  /// seja, é um primeiro acesso que precisa escolher a igreja.
  Future<bool> precisaEscolherIgreja() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return false;
    return !(await _db.collection('usuarios').doc(uid).get()).exists;
  }

  /// Garante um usuário (uid) para ações abertas a visitantes, como enviar
  /// pedido de oração. Se já houver sessão, reaproveita; senão entra de forma
  /// anônima. Requer "Autenticação anônima" habilitada no Firebase.
  Future<String> garantirUsuario() async {
    final atual = _auth.currentUser;
    if (atual != null) return atual.uid;
    final cred = await _auth.signInAnonymously();
    return cred.user!.uid;
  }

  Future<void> esqueciSenha(String email) {
    return _auth.sendPasswordResetEmail(email: email);
  }

  /// `true` se a conta atual já possui login por e-mail/senha (provedor
  /// `password`). Contas criadas só com Google retornam `false` até definirem
  /// uma senha.
  bool get possuiSenhaEmail {
    final user = _auth.currentUser;
    if (user == null) return false;
    return user.providerData.any((p) => p.providerId == 'password');
  }

  /// Adiciona (vincula) login por e-mail/senha à conta atual sem remover o
  /// Google — assim o usuário passa a entrar dos dois jeitos. Usa o e-mail da
  /// própria conta. Requer sessão recente (pode lançar `requires-recent-login`).
  Future<void> definirSenha(String senha) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'no-current-user',
        message: 'Nenhuma sessão ativa.',
      );
    }
    final email = user.email;
    if (email == null || email.isEmpty) {
      throw FirebaseAuthException(
        code: 'invalid-email',
        message: 'A conta não tem e-mail para vincular a senha.',
      );
    }
    final credential = EmailAuthProvider.credential(
      email: email,
      password: senha,
    );
    await user.linkWithCredential(credential);
  }

  Future<void> logout() async {
    // Desconecta também do Google para permitir trocar de conta no próximo
    // acesso. Falha/lentidão aqui NUNCA deve impedir o logout do Firebase.
    try {
      await _googleSignIn.signOut().timeout(
        const Duration(seconds: 3),
        onTimeout: () => null,
      );
    } catch (_) {}
    await _auth.signOut();
  }

  /// Recupera uma conta cuja credencial existe no Firebase Auth, mas cujo
  /// cadastro atômico no Firestore não foi concluído.
  ///
  /// Não tentamos inventar perfil, igreja ou vínculo: antes de excluir a
  /// credencial, uma leitura obrigatoriamente feita no servidor confirma que
  /// `usuarios/{uid}` continua ausente. Se o documento já apareceu (por
  /// exemplo, após uma demora de rede), preservamos a conta e o RootGate pode
  /// recarregá-la normalmente.
  ///
  /// Falhas de rede, permissão ou exclusão são propagadas. Nesse caso a sessão
  /// permanece aberta na tela segura de recuperação, permitindo tentar de
  /// novo ou simplesmente sair.
  Future<RecuperacaoCadastroIncompleto> recuperarCadastroIncompleto() async {
    final user = _auth.currentUser;
    if (user == null || user.isAnonymous) {
      throw const SessaoInvalidaParaRecuperacao();
    }

    final usuario = await _db
        .collection('usuarios')
        .doc(user.uid)
        .get(const GetOptions(source: Source.server));

    if (usuario.exists) {
      return RecuperacaoCadastroIncompleto.cadastroEncontrado;
    }

    // O login que levou a esta tela é recente, então normalmente o Auth
    // permite a exclusão. Se ainda assim exigir nova autenticação, não
    // mascaramos a falha nem liberamos qualquer acesso sem vínculo.
    await user.delete();

    // `delete()` encerra a sessão atual, mas o sign-out explícito mantém o
    // comportamento consistente entre plataformas e também solta a conta do
    // Google para que a pessoa possa refazer o cadastro com outra escolha.
    await logout();
    return RecuperacaoCadastroIncompleto.credencialRemovida;
  }

  Future<UsuarioModel?> getUsuarioAtual() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return null;
    final doc = await _db.collection('usuarios').doc(uid).get();
    if (!doc.exists) return null;
    return UsuarioModel.fromFirestore(doc);
  }

  Stream<UsuarioModel?> streamUsuarioAtual() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return Stream.value(null);
    return _db
        .collection('usuarios')
        .doc(uid)
        .snapshots()
        .map((doc) => doc.exists ? UsuarioModel.fromFirestore(doc) : null);
  }
}

/// Primeiro acesso com Google sem igreja escolhida.
///
/// Não é erro de rede nem de credencial: o fluxo precisa voltar à seleção de
/// igreja antes de concluir o cadastro.
class IgrejaObrigatoriaNoCadastro implements Exception {
  const IgrejaObrigatoriaNoCadastro();

  @override
  String toString() => 'Escolha uma igreja para concluir seu cadastro.';
}

/// Resultado seguro da recuperação de uma conta parcialmente provisionada.
enum RecuperacaoCadastroIncompleto {
  /// O documento apareceu no servidor; nada foi removido.
  cadastroEncontrado,

  /// Somente a credencial órfã foi removida; o cadastro pode ser refeito.
  credencialRemovida,
}

/// A recuperação só é válida para uma conta real autenticada.
class SessaoInvalidaParaRecuperacao implements Exception {
  const SessaoInvalidaParaRecuperacao();

  @override
  String toString() => 'Não há uma conta autenticada para recuperar.';
}
