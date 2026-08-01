import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'usuario_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get usuarioFirebase => _auth.currentUser;

  Future<UserCredential> login(String email, String senha) {
    return _auth.signInWithEmailAndPassword(email: email, password: senha);
  }

  Future<UserCredential> cadastrar({
    required String email,
    required String senha,
    required String nome,
    required String telefone,
    QualificacaoUsuario? qualificacao,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: senha,
    );

    final uid = credential.user!.uid;

    final usuario = UsuarioModel(
      uid: uid,
      nome: nome,
      email: email,
      telefone: telefone,
      dataCadastro: DateTime.now(),
      perfil: PerfilUsuario.membro,
      status: StatusUsuario.pendente,
      qualificacao: qualificacao,
    );

    await _db.collection('usuarios').doc(uid).set(usuario.toMap());
    return credential;
  }

  /// Login/cadastro com Google. Retorna `null` se o usuário cancelar.
  /// Se for o primeiro acesso, provisiona `usuarios/{uid}` como membro pendente
  /// (mesma esteira de aprovação do cadastro por e-mail).
  Future<UserCredential?> entrarComGoogle() async {
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) return null; // cancelado pelo usuário

    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final userCred = await _auth.signInWithCredential(credential);
    await _garantirDocumentoUsuario(userCred.user!);
    return userCred;
  }

  /// Cria o documento do usuário na primeira vez (perfil membro, status
  /// pendente). Se já existir, não altera nada.
  Future<void> _garantirDocumentoUsuario(User user) async {
    final ref = _db.collection('usuarios').doc(user.uid);
    final doc = await ref.get();
    if (doc.exists) return;

    final usuario = UsuarioModel(
      uid: user.uid,
      nome: user.displayName ?? '',
      email: user.email ?? '',
      telefone: user.phoneNumber ?? '',
      fotoUrl: user.photoURL,
      dataCadastro: DateTime.now(),
      perfil: PerfilUsuario.membro,
      status: StatusUsuario.pendente,
    );
    await ref.set(usuario.toMap());
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

  Future<void> logout() async {
    // Desconecta também do Google para permitir trocar de conta no próximo
    // acesso. Falha/lentidão aqui NUNCA deve impedir o logout do Firebase.
    try {
      await _googleSignIn
          .signOut()
          .timeout(const Duration(seconds: 3), onTimeout: () => null);
    } catch (_) {}
    await _auth.signOut();
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
