import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/igreja_scope.dart';
import '../../auth/providers/auth_provider.dart';
import '../../igrejas/providers/igreja_providers.dart';
import '../data/oracao_repository.dart';
import '../data/pedido_oracao_model.dart';

final oracaoRepositoryProvider = Provider<OracaoRepository>((ref) {
  final scope = ref.watch(igrejaScopeProvider);
  if (scope == null) throw const IgrejaNaoSelecionada();
  return OracaoRepository(scope);
});

/// Mural da unidade em foco (pedidos públicos aprovados).
final muralPedidosProvider =
    StreamProvider.autoDispose<List<PedidoOracaoModel>>((ref) {
  if (ref.watch(igrejaScopeProvider) == null) return Stream.value(const []);
  return ref.watch(oracaoRepositoryProvider).streamMural();
});

/// Pedidos do próprio usuário na unidade em foco.
final meusPedidosProvider =
    StreamProvider.autoDispose<List<PedidoOracaoModel>>((ref) {
  final uid = ref.watch(authStateProvider).valueOrNull?.uid;
  if (uid == null || ref.watch(igrejaScopeProvider) == null) {
    return Stream.value(const <PedidoOracaoModel>[]);
  }
  return ref.watch(oracaoRepositoryProvider).streamMeusPedidos(uid);
});

/// Fila de moderação — só emite para quem pode moderar na unidade.
final pedidosModeracaoProvider =
    StreamProvider.autoDispose<List<PedidoOracaoModel>>((ref) {
  final autorizacao = ref.watch(autorizacaoAtualProvider);
  if (ref.watch(igrejaScopeProvider) == null ||
      autorizacao == null ||
      !autorizacao.podeModerarOracao) {
    return Stream.value(const <PedidoOracaoModel>[]);
  }
  return ref.watch(oracaoRepositoryProvider).streamPendentesModeracao();
});

final pedidosModeracaoCountProvider = Provider.autoDispose<int>((ref) {
  return ref.watch(pedidosModeracaoProvider).valueOrNull?.length ?? 0;
});
