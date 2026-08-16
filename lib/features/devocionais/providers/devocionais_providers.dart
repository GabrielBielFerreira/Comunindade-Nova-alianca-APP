import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/igreja_scope.dart';
import '../../igrejas/providers/igreja_providers.dart';
import '../data/devocional_model.dart';
import '../data/devocionais_repository.dart';

final devocionaisRepositoryProvider = Provider<DevocionaisRepository>((ref) {
  final scope = ref.watch(igrejaScopeProvider);
  if (scope == null) throw const IgrejaNaoSelecionada();
  return DevocionaisRepository(scope);
});

final devocionaisStreamProvider =
    StreamProvider.autoDispose<List<DevocionalModel>>((ref) {
  if (ref.watch(igrejaScopeProvider) == null) return Stream.value(const []);
  return ref.watch(devocionaisRepositoryProvider).stream();
});

/// Lista de gestão: inclui devocionais inativos.
final devocionaisGerenciarProvider =
    StreamProvider.autoDispose<List<DevocionalModel>>((ref) {
  if (ref.watch(igrejaScopeProvider) == null) return Stream.value(const []);
  return ref.watch(devocionaisRepositoryProvider).streamGerenciar();
});

/// Devocional em destaque (o marcado como destaque, senão o mais recente).
final devocionalDestaqueProvider = Provider.autoDispose<DevocionalModel?>((ref) {
  final lista = ref.watch(devocionaisStreamProvider).valueOrNull ?? [];
  if (lista.isEmpty) return null;
  return lista.firstWhere((d) => d.destaque, orElse: () => lista.first);
});
