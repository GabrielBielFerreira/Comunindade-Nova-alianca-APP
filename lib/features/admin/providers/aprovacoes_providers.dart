import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/data/usuario_model.dart';
import '../data/aprovacoes_repository.dart';

final aprovacoesRepositoryProvider =
    Provider<AprovacoesRepository>((ref) => AprovacoesRepository());

/// Lista de cadastros pendentes (apenas liderança consegue ler, via regras).
final cadastrosPendentesProvider =
    StreamProvider.autoDispose<List<UsuarioModel>>((ref) {
  return ref.watch(aprovacoesRepositoryProvider).streamPendentes();
});

/// Contador para o card/badge de "Cadastros pendentes".
final cadastrosPendentesCountProvider = Provider.autoDispose<int>((ref) {
  return ref.watch(cadastrosPendentesProvider).valueOrNull?.length ?? 0;
});
