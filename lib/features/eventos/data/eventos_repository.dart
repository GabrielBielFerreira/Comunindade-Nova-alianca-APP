import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/data/igreja_scope.dart';
import 'evento_model.dart';

/// Programação de UMA unidade: `igrejas/{igrejaId}/eventos`.
/// Filtro de data e ordenação no cliente para dispensar índice composto.
class EventosRepository {
  EventosRepository(this._scope);

  final IgrejaScope _scope;

  CollectionReference<Map<String, dynamic>> get _col => _scope.eventos;

  Stream<List<EventoModel>> streamProximos() {
    return _col.snapshots().map(_futuros);
  }

  /// Programação visível a visitante: somente eventos públicos.
  /// O filtro `publico == true` é exigido pelas Rules na própria consulta.
  Stream<List<EventoModel>> streamProximosPublicos() {
    return _col.where('publico', isEqualTo: true).snapshots().map(_futuros);
  }

  List<EventoModel> _futuros(QuerySnapshot<Map<String, dynamic>> snap) {
    return filtrarEventosProximos(snap.docs.map(EventoModel.fromFirestore));
  }

  /// Visão de gestão: todos os eventos, inclusive passados.
  Stream<List<EventoModel>> streamGerenciar() {
    return _col.snapshots().map((snap) {
      final lista = snap.docs.map(EventoModel.fromFirestore).toList();
      lista.sort((a, b) => b.data.compareTo(a.data));
      return lista;
    });
  }

  Future<String> criar(EventoModel evento) async {
    final ref = await _col.add(evento.toMap());
    return ref.id;
  }

  Future<void> atualizar(EventoModel evento) {
    return _col.doc(evento.id).update(evento.toMap());
  }

  /// Cancela sem apagar, preservando o histórico da unidade.
  Future<void> definirCancelado(String id, bool cancelado) {
    return _col.doc(id).update({'cancelado': cancelado});
  }
}

/// Programação pública/próxima nunca inclui evento cancelado. A gestão usa
/// [EventosRepository.streamGerenciar] e continua vendo o histórico completo.
List<EventoModel> filtrarEventosProximos(
  Iterable<EventoModel> eventos, {
  DateTime? agora,
}) {
  final ontem = (agora ?? DateTime.now()).subtract(const Duration(days: 1));
  final lista = eventos
      .where((e) => !e.cancelado && e.data.isAfter(ontem))
      .toList();
  lista.sort((a, b) => a.data.compareTo(b.data));
  return lista;
}
