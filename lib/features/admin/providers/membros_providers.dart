import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/data/usuario_model.dart';
import '../data/membros_repository.dart';

final membrosRepositoryProvider =
    Provider<MembrosRepository>((ref) => MembrosRepository());

/// Membros aprovados (para o seletor de membros na gestão).
final membrosAprovadosProvider =
    StreamProvider.autoDispose<List<UsuarioModel>>((ref) {
  return ref.watch(membrosRepositoryProvider).streamAprovados();
});
