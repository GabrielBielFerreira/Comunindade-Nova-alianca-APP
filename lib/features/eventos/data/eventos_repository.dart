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

  /// Visão da liderança (Gestão): TODOS os eventos, inclusive os já passados,
  /// mais recentes/próximos primeiro. Permite revisar e limpar a agenda.
  Stream<List<EventoModel>> streamGerenciar() {
    return _col.snapshots().map((snap) {
      final lista = snap.docs.map(EventoModel.fromFirestore).toList();
      lista.sort((a, b) => b.data.compareTo(a.data));
      return lista;
    });
  }

  /// Cria um novo evento. Retorna o id gerado.
  Future<String> criar(EventoModel evento) async {
    final ref = await _col.add(evento.toMap());
    return ref.id;
  }

  /// Atualiza um evento existente.
  Future<void> atualizar(EventoModel evento) {
    return _col.doc(evento.id).update(evento.toMap());
  }

  /// Remove definitivamente um evento.
  Future<void> excluir(String id) {
    return _col.doc(id).delete();
  }
}
