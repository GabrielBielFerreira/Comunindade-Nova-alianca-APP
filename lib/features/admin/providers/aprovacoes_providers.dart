import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nova_alianca_core/nova_alianca_core.dart';

import '../../igrejas/providers/igreja_providers.dart';
import '../data/aprovacoes_repository.dart';
import '../data/membros_repository.dart';
import 'membros_providers.dart';

final aprovacoesRepositoryProvider =
    Provider<AprovacoesRepository>((ref) => AprovacoesRepository());

/// Cadastros pendentes da unidade em foco.
final cadastrosPendentesProvider =
    StreamProvider.autoDispose<List<MembroUnidade>>((ref) {
  final autorizacao = ref.watch(autorizacaoAtualProvider);
  if (ref.watch(igrejaScopeProvider) == null ||
      autorizacao == null ||
      !autorizacao.podeAprovarMembro) {
    return Stream.value(const <MembroUnidade>[]);
  }
  return ref
      .watch(membrosRepositoryProvider)
      .streamPorStatus(StatusVinculo.pendente);
});

final cadastrosPendentesCountProvider = Provider.autoDispose<int>((ref) {
  return ref.watch(cadastrosPendentesProvider).valueOrNull?.length ?? 0;
});
