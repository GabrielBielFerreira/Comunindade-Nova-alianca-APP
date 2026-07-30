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
}
