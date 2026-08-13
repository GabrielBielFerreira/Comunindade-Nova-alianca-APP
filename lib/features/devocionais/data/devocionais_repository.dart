import 'package:cloud_firestore/cloud_firestore.dart';

import 'devocional_model.dart';

/// Acesso ao Firestore para devocionais (coleção `devocionais`).
class DevocionaisRepository {
  DevocionaisRepository({FirebaseFirestore? db})
      : _col = (db ?? FirebaseFirestore.instance).collection('devocionais');

  final CollectionReference<Map<String, dynamic>> _col;

  Stream<List<DevocionalModel>> stream() {
    return _col.snapshots().map((snap) {
      final lista = snap.docs.map(DevocionalModel.fromFirestore).toList();
      lista.sort((a, b) => b.data.compareTo(a.data));
      return lista;
    });
  }

  /// Cria um novo devocional. Retorna o id gerado.
  Future<String> criar(DevocionalModel devocional) async {
    final ref = await _col.add(devocional.toMap());
    return ref.id;
  }

  /// Atualiza um devocional existente.
  Future<void> atualizar(DevocionalModel devocional) {
    return _col.doc(devocional.id).update(devocional.toMap());
  }

  /// Remove definitivamente um devocional.
  Future<void> excluir(String id) {
    return _col.doc(id).delete();
  }
}
