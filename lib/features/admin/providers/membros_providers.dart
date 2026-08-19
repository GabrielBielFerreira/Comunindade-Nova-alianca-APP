import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/igreja_scope.dart';
import '../../igrejas/providers/igreja_providers.dart';
import '../data/membros_repository.dart';

final membrosRepositoryProvider = Provider<MembrosRepository>((ref) {
  final scope = ref.watch(igrejaScopeProvider);
  if (scope == null) throw const IgrejaNaoSelecionada();
  return MembrosRepository(scope);
});

/// Membros aprovados da unidade em foco (seletor de responsável, etc.).
final membrosAprovadosProvider =
    StreamProvider.autoDispose<List<MembroUnidade>>((ref) {
  if (ref.watch(igrejaScopeProvider) == null) return Stream.value(const []);
  return ref.watch(membrosRepositoryProvider).streamAprovados();
});
