import 'package:cloud_firestore/cloud_firestore.dart';

import 'evento_model.dart';

/// Acesso ao Firestore para eventos/programação (coleção `eventos`).
/// Ordenação e filtro de data no cliente para evitar índices compostos.
class EventosRepository {
  EventosRepository({FirebaseFirestore? db})
      : _col = (db ?? FirebaseFirestore.instance).collection('eventos');

  final CollectionReference<Map<String, dynamic>> _col;

  Stream<List<EventoModel>> streamProximos() {
    return _col.snapshots().map((snap) {
      final ontem = DateTime.now().subtract(const Duration(days: 1));
      final lista = snap.docs
          .map(EventoModel.fromFirestore)
          .where((e) => e.data.isAfter(ontem))
          .toList();
      lista.sort((a, b) => a.data.compareTo(b.data));
      return lista;
    });
  }
}
