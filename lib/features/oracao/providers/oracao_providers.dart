import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_provider.dart';
import '../data/oracao_repository.dart';
import '../data/pedido_oracao_model.dart';

final oracaoRepositoryProvider =
    Provider<OracaoRepository>((ref) => OracaoRepository());

/// Mural público da comunidade (pedidos não privados).
final muralPedidosProvider =
    StreamProvider.autoDispose<List<PedidoOracaoModel>>((ref) {
  return ref.watch(oracaoRepositoryProvider).streamMural();
});

/// Pedidos do usuário logado (inclui privados e não aprovados).
final meusPedidosProvider =
    StreamProvider.autoDispose<List<PedidoOracaoModel>>((ref) {
  final uid = ref.watch(authStateProvider).valueOrNull?.uid;
  if (uid == null) return Stream.value(const <PedidoOracaoModel>[]);
  return ref.watch(oracaoRepositoryProvider).streamMeusPedidos(uid);
});

/// Pedidos públicos aguardando moderação (liderança).
final pedidosModeracaoProvider =
    StreamProvider.autoDispose<List<PedidoOracaoModel>>((ref) {
  return ref.watch(oracaoRepositoryProvider).streamPendentesModeracao();
});

final pedidosModeracaoCountProvider = Provider.autoDispose<int>((ref) {
  return ref.watch(pedidosModeracaoProvider).valueOrNull?.length ?? 0;
});
