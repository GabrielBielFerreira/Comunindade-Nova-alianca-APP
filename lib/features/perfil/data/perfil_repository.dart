import 'package:cloud_firestore/cloud_firestore.dart';

/// Leitura/escrita do perfil do usuário no Firestore (coleção `usuarios`).
///
/// Os dados cadastrais estendidos (sexo, estado civil, batismo, endereço, etc.)
/// ficam sob o campo `dados_pessoais`. As regras permitem que o próprio usuário
/// atualize seu documento desde que NÃO altere `perfil`/`status`.
class PerfilRepository {
  PerfilRepository({FirebaseFirestore? db})
    : _db = db ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  DocumentReference<Map<String, dynamic>> _doc(String uid) =>
      _db.collection('usuarios').doc(uid);

  Future<Map<String, dynamic>> carregar(String uid) async {
    final snap = await _doc(uid).get();
    return snap.data() ?? <String, dynamic>{};
  }

  Future<void> salvar(
    String uid, {
    required String nome,
    required String telefone,
    required Map<String, dynamic> dadosPessoais,
  }) async {
    await _doc(uid).set({
      'nome': nome,
      'telefone': telefone,
      'dados_pessoais': dadosPessoais,
      'atualizado_em': Timestamp.now(),
    }, SetOptions(merge: true));
  }
}
