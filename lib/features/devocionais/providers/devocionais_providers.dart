import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/devocional_model.dart';
import '../data/devocionais_repository.dart';

final devocionaisRepositoryProvider =
    Provider<DevocionaisRepository>((ref) => DevocionaisRepository());

final devocionaisStreamProvider =
    StreamProvider.autoDispose<List<DevocionalModel>>((ref) {
  return ref.watch(devocionaisRepositoryProvider).stream();
});

/// Devocional em destaque (o marcado como destaque, senão o mais recente).
final devocionalDestaqueProvider = Provider.autoDispose<DevocionalModel?>((ref) {
  final lista = ref.watch(devocionaisStreamProvider).valueOrNull ?? [];
  if (lista.isEmpty) return null;
  return lista.firstWhere((d) => d.destaque, orElse: () => lista.first);
});
