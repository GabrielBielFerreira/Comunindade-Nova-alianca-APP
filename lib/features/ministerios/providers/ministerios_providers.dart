import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../avisos/data/ministerio_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../data/ministerios_repository.dart';

final ministeriosRepositoryProvider =
    Provider<MinisteriosRepository>((ref) => MinisteriosRepository());

/// Todos os ministérios ativos (para a lista de "demonstrar interesse").
final ministeriosProvider =
    StreamProvider.autoDispose<List<MinisterioModel>>((ref) {
  return ref.watch(ministeriosRepositoryProvider).stream();
});

/// Ministério do usuário logado (null se não houver vínculo).
final meuMinisterioProvider =
    FutureProvider.autoDispose<MinisterioModel?>((ref) {
  final usuario = ref.watch(usuarioProvider);
  final id = usuario?.ministerioId;
  if (id == null || id.isEmpty) return Future.value(null);
  return ref.watch(ministeriosRepositoryProvider).obter(id);
});
