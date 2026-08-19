import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nova_alianca_core/nova_alianca_core.dart';

import '../../../core/data/igreja_scope.dart';
import '../../avisos/data/ministerio_model.dart';
import '../../igrejas/providers/igreja_providers.dart';
import '../data/ministerios_repository.dart';

final ministeriosRepositoryProvider = Provider<MinisteriosRepository>((ref) {
  final scope = ref.watch(igrejaScopeProvider);
  if (scope == null) throw const IgrejaNaoSelecionada();
  return MinisteriosRepository(scope);
});

/// Ministérios ativos da unidade em foco.
final ministeriosProvider = StreamProvider.autoDispose<List<MinisterioModel>>((
  ref,
) {
  if (ref.watch(igrejaScopeProvider) == null) return Stream.value(const []);
  final vinculo = ref.watch(vinculoAtualProvider).valueOrNull;
  final aprovado = vinculo?.status == StatusVinculo.aprovado;
  final repo = ref.watch(ministeriosRepositoryProvider);
  return aprovado ? repo.stream() : repo.streamPublicos();
});

/// Lista de gestão: todos os ministérios, inclusive inativos.
final ministeriosGerenciarProvider =
    StreamProvider.autoDispose<List<MinisterioModel>>((ref) {
      if (ref.watch(igrejaScopeProvider) == null) return Stream.value(const []);
      return ref.watch(ministeriosRepositoryProvider).streamGerenciar();
    });

/// Ministério do usuário na unidade em foco.
///
/// Vem do VÍNCULO daquela unidade — não do documento global — porque
/// participar de um ministério é relação com a igreja, não com a conta.
final meuMinisterioProvider = FutureProvider.autoDispose<MinisterioModel?>((
  ref,
) async {
  if (ref.watch(igrejaScopeProvider) == null) return null;

  final vinculo = ref.watch(vinculoAtualProvider).valueOrNull;
  final ids = vinculo?.ministerioIds ?? const <String>[];
  if (ids.isEmpty) return null;

  return ref.watch(ministeriosRepositoryProvider).obter(ids.first);
});
