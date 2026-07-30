import 'package:cloud_firestore/cloud_firestore.dart';

import '../../avisos/data/ministerio_model.dart';

/// Acesso ao Firestore para ministérios (coleção `ministerios`).
class MinisteriosRepository {
  MinisteriosRepository({FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  Future<MinisterioModel?> obter(String id) async {
    final doc = await _db.collection('ministerios').doc(id).get();
    return doc.exists ? MinisterioModel.fromFirestore(doc) : null;
  }

  Stream<List<MinisterioModel>> stream() {
    return _db
        .collection('ministerios')
        .where('ativo', isEqualTo: true)
        .snapshots()
        .map((snap) {
      final lista = snap.docs.map(MinisterioModel.fromFirestore).toList();
      lista.sort((a, b) => a.nome.compareTo(b.nome));
      return lista;
    });
  }

  /// Registra interesse do usuário em participar de um ministério.
  Future<void> registrarInteresse({
    required String uid,
    required String nome,
    String? ministerioId,
    String? ministerioNome,
  }) async {
    await _db.collection('interesses_ministerio').add({
      'usuario_id': uid,
      'usuario_nome': nome,
      'ministerio_id': ministerioId,
      'ministerio_nome': ministerioNome,
      'status': 'novo',
      'criado_em': FieldValue.serverTimestamp(),
    });
  }
}
