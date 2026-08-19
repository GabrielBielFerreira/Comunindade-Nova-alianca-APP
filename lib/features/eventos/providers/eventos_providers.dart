import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/igreja_scope.dart';
import '../../igrejas/providers/igreja_providers.dart';
import '../data/evento_model.dart';
import '../data/eventos_repository.dart';

final eventosRepositoryProvider = Provider<EventosRepository>((ref) {
  final scope = ref.watch(igrejaScopeProvider);
  if (scope == null) throw const IgrejaNaoSelecionada();
  return EventosRepository(scope);
});

final eventosStreamProvider =
    StreamProvider.autoDispose<List<EventoModel>>((ref) {
  if (ref.watch(igrejaScopeProvider) == null) return Stream.value(const []);

  final repo = ref.watch(eventosRepositoryProvider);
  final aprovado = ref.watch(isMembroAprovadoAtualProvider);
  return aprovado ? repo.streamProximos() : repo.streamProximosPublicos();
});

/// Lista de gestão: todos os eventos, inclusive passados.
final eventosGerenciarStreamProvider =
    StreamProvider.autoDispose<List<EventoModel>>((ref) {
  if (ref.watch(igrejaScopeProvider) == null) return Stream.value(const []);
  return ref.watch(eventosRepositoryProvider).streamGerenciar();
});
