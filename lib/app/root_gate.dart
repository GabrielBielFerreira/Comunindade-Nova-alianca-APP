import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/services/fcm_service.dart';
import '../features/auth/data/usuario_model.dart';
import '../features/auth/providers/auth_provider.dart';
import '../visual/screens/home_leader_screen.dart';
import '../visual/screens/home_member_screen.dart';
import '../visual/screens/welcome_access_screen.dart';
import 'screens/aguardando_aprovacao_screen.dart';
import 'screens/conta_inativa_screen.dart';
import 'screens/splash_screen.dart';

/// Porta de entrada única do app de produção.
///
/// Decide, a partir do estado de autenticação e do perfil do usuário, qual
/// experiência renderizar. Substitui os dois "apps" paralelos (visual x
/// produção) por um único fluxo coerente:
///
/// - Não autenticado  → [WelcomeAccessScreen] (entrar ou continuar como visitante)
/// - Autenticado + pendente → [AguardandoAprovacaoScreen]
/// - Autenticado + inativo  → [ContaInativaScreen]
/// - Autenticado + aprovado → Home por perfil (membro ou liderança)
///
/// A navegação interna das telas continua usando o mapa de rotas nomeadas
/// (ver `visual/visual_router.dart`); este gate cuida apenas do nível superior.
class RootGate extends ConsumerWidget {
  const RootGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Inicializa o FCM assim que houver um usuário autenticado (contextual).
    ref.listen<AsyncValue<User?>>(authStateProvider, (previous, next) {
      final estavaLogado = previous?.valueOrNull != null;
      final estaLogado = next.valueOrNull != null;
      if (!estavaLogado && estaLogado) {
        // Falhas de FCM não devem quebrar o app (ex.: sem google-services.json).
        FcmService.init().catchError((_) {});
      }
    });

    final authState = ref.watch(authStateProvider);

    return authState.when(
      loading: () => const SplashScreen(),
      error: (_, __) => const WelcomeAccessScreen(),
      data: (firebaseUser) {
        if (firebaseUser == null) {
          return const WelcomeAccessScreen();
        }

        final usuarioAsync = ref.watch(usuarioAtualProvider);
        return usuarioAsync.when(
          loading: () => const SplashScreen(),
          error: (_, __) =>
              const SplashScreen(mensagem: 'Não foi possível carregar seu perfil.'),
          data: (usuario) {
            if (usuario == null) {
              // Documento ainda sendo provisionado (logo após o cadastro).
              return const SplashScreen(mensagem: 'Preparando sua conta...');
            }
            switch (usuario.status) {
              case StatusUsuario.pendente:
                return const AguardandoAprovacaoScreen();
              case StatusUsuario.inativo:
                return const ContaInativaScreen();
              case StatusUsuario.aprovado:
                return usuario.isLider
                    ? const HomeLeaderScreen()
                    : const HomeMemberScreen();
            }
          },
        );
      },
    );
  }
}
