import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/igreja_scope.dart';
import '../../igrejas/providers/igreja_providers.dart';
import '../data/campanha_model.dart';
import '../data/campanhas_repository.dart';

final campanhasRepositoryProvider = Provider<CampanhasRepository>((ref) {
  final scope = ref.watch(igrejaScopeProvider);
  if (scope == null) throw const IgrejaNaoSelecionada();
  return CampanhasRepository(scope);
});

/// Campanhas ativas da unidade em foco (lista vazia = nenhuma publicada).
final campanhasAtivasProvider =
    StreamProvider.autoDispose<List<CampanhaModel>>((ref) {
  if (ref.watch(igrejaScopeProvider) == null) return Stream.value(const []);

  final repo = ref.watch(campanhasRepositoryProvider);
  final aprovado = ref.watch(isMembroAprovadoAtualProvider);
  return aprovado ? repo.streamAtivas() : repo.streamAtivasPublicas();
});

/// Lista de gestão: todas as campanhas, inclusive encerradas.
final campanhasGerenciarProvider =
    StreamProvider.autoDispose<List<CampanhaModel>>((ref) {
  if (ref.watch(igrejaScopeProvider) == null) return Stream.value(const []);
  return ref.watch(campanhasRepositoryProvider).streamGerenciar();
});
