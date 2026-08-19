import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/igreja_scope.dart';
import '../../igrejas/providers/igreja_providers.dart';
import '../data/aviso_model.dart';
import '../data/avisos_repository.dart';

/// Repositório da unidade em foco. É recriado quando a igreja muda, o que
/// invalida automaticamente os streams derivados — é assim que o cache da
/// unidade anterior é descartado.
final avisosRepositoryProvider = Provider<AvisosRepository>((ref) {
  final scope = ref.watch(igrejaScopeProvider);
  if (scope == null) throw const IgrejaNaoSelecionada();
  return AvisosRepository(scope);
});

/// Avisos conforme o vínculo: membro aprovado vê os internos; visitante (ou
/// quem apenas visualiza outra unidade) vê somente os públicos.
final avisosStreamProvider =
    StreamProvider.autoDispose<List<AvisoModel>>((ref) {
  if (ref.watch(igrejaScopeProvider) == null) return Stream.value(const []);

  final repo = ref.watch(avisosRepositoryProvider);
  final aprovado = ref.watch(isMembroAprovadoAtualProvider);
  return aprovado ? repo.stream() : repo.streamPublicos();
});

/// Lista de gestão (liderança/editor): inclui despublicados.
final avisosGerenciarStreamProvider =
    StreamProvider.autoDispose<List<AvisoModel>>((ref) {
  if (ref.watch(igrejaScopeProvider) == null) return Stream.value(const []);
  return ref.watch(avisosRepositoryProvider).streamGerenciar();
});
