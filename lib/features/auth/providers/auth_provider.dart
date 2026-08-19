import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/auth_service.dart';
import '../data/usuario_model.dart';

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});

final usuarioAtualProvider = StreamProvider<UsuarioModel?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.when(
    data: (user) {
      // Usuário anônimo é apenas a credencial técnica de um visitante para
      // ações abertas. Ele não possui `usuarios/{uid}` nem vínculo de igreja.
      if (user == null || user.isAnonymous) return Stream.value(null);
      return ref.watch(authServiceProvider).streamUsuarioAtual();
    },
    loading: () => Stream.value(null),
    error: (_, _) => Stream.value(null),
  );
});

// Conveniência: retorna o UsuarioModel sincronamente quando disponível
final usuarioProvider = Provider<UsuarioModel?>((ref) {
  return ref.watch(usuarioAtualProvider).valueOrNull;
});
