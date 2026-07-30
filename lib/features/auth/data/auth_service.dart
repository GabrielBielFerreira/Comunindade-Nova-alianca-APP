import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'usuario_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

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

  Future<void> esqueciSenha(String email) {
    return _auth.sendPasswordResetEmail(email: email);
  }

  Future<void> logout() {
    return _auth.signOut();
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
