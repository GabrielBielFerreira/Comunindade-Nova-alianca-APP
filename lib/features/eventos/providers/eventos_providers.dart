import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/evento_model.dart';
import '../data/eventos_repository.dart';

final eventosRepositoryProvider =
    Provider<EventosRepository>((ref) => EventosRepository());

final eventosStreamProvider =
    StreamProvider.autoDispose<List<EventoModel>>((ref) {
  return ref.watch(eventosRepositoryProvider).streamProximos();
});

/// Lista de gestão (liderança): todos os eventos, inclusive passados.
final eventosGerenciarStreamProvider =
    StreamProvider.autoDispose<List<EventoModel>>((ref) {
  return ref.watch(eventosRepositoryProvider).streamGerenciar();
});
