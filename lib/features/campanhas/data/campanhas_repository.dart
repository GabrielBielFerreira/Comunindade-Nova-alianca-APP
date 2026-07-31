import 'package:cloud_firestore/cloud_firestore.dart';

import 'campanha_model.dart';

/// Acesso ao Firestore para campanhas (coleção `campanhas`). Filtra ativas e
/// ordena no cliente para evitar índices compostos. Escrita é restrita à
/// liderança pelas regras.
class CampanhasRepository {
  CampanhasRepository({FirebaseFirestore? db})
      : _col = (db ?? FirebaseFirestore.instance).collection('campanhas');

  final CollectionReference<Map<String, dynamic>> _col;

  Stream<List<CampanhaModel>> streamAtivas() {
    return _col
        .where('status', isEqualTo: 'ativa')
        .snapshots()
        .map((snap) {
      final lista = snap.docs.map(CampanhaModel.fromFirestore).toList()
        ..sort((a, b) => b.dataInicio.compareTo(a.dataInicio));
      return lista;
    });
  }
}
