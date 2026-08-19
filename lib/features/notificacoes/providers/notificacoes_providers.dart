import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_provider.dart';
import '../data/notificacao_model.dart';
import '../data/notificacoes_repository.dart';

final notificacoesRepositoryProvider =
    Provider<NotificacoesRepository>((ref) => NotificacoesRepository());

/// Notificações são pessoais, não da unidade: seguem o usuário mesmo quando
/// ele visualiza outra igreja.
final notificacoesStreamProvider =
    StreamProvider.autoDispose<List<NotificacaoModel>>((ref) {
  final uid = ref.watch(authStateProvider).valueOrNull?.uid;
  if (uid == null) return Stream.value(const <NotificacaoModel>[]);
  return ref.watch(notificacoesRepositoryProvider).stream(uid);
});

final naoLidasCountProvider = Provider.autoDispose<int>((ref) {
  final lista = ref.watch(notificacoesStreamProvider).valueOrNull ?? [];
  return lista.where((n) => !n.lida).length;
});
