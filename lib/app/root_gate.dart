import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nova_alianca_core/nova_alianca_core.dart';

import '../core/services/fcm_service.dart';
import '../features/auth/providers/auth_provider.dart';
import '../features/igrejas/providers/igreja_providers.dart';
import '../visual/screens/home_leader_screen.dart';
import '../visual/screens/select_church_screen.dart';
import '../visual/screens/home_member_screen.dart';
import '../visual/screens/welcome_access_screen.dart';
import 'screens/aguardando_aprovacao_screen.dart';
import 'screens/conta_inativa_screen.dart';
import 'screens/splash_screen.dart';

/// Porta de entrada única do app de produção.
///
/// Decide qual experiência renderizar:
///
/// - Não autenticado          → [WelcomeAccessScreen]
/// - Sem documento de usuário → splash de provisionamento (com saída)
/// - Sem igreja principal     → [SemIgrejaVinculadaScreen]
/// - Vínculo pendente         → [AguardandoAprovacaoScreen]
/// - Vínculo inativo          → [ContaInativaScreen]
/// - Vínculo aprovado         → Home por perfil (liderança ou membro)
///
/// ## Fonte da decisão
///
/// A decisão vem do VÍNCULO com a igreja principal
/// (`igrejas/{igrejaId}/membros/{uid}`), não mais de `perfil`/`status` no
/// documento global `usuarios/{uid}`.
///
/// Isso é obrigatório na arquitetura multi-igreja: autorização é sempre
/// relativa a uma unidade. Ler o perfil global permitia que alguém aprovado
/// numa igreja fosse tratado como aprovado em qualquer outra — e as Rules
/// atuais nem gravam mais esses campos ali.
///
/// Usa deliberadamente o vínculo PRINCIPAL, não o da unidade em foco: quem
/// visita outra igreja continua entrando no aplicativo pela própria.
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

    // Ao AUTENTICAR, descarta a unidade pública escolhida antes do login.
    //
    // Sem isto, quem navegou como visitante em Petrolina e depois entrou com
    // conta de Olinda continuaria vendo Petrolina — herdando silenciosamente
    // um contexto que não é o seu. A sessão começa sempre na igreja do
    // vínculo; visitar outra passa a exigir uma troca manual explícita.
    ref.listen<AsyncValue<User?>>(authStateProvider, (previous, next) {
      final entrou = previous?.valueOrNull == null && next.valueOrNull != null;
      if (entrou) {
        ref.read(igrejaVisualizadaProvider.notifier).limpar();
      }
    });

    final authState = ref.watch(authStateProvider);

    return authState.when(
      loading: () => const SplashScreen(),
      error: (_, _) => const WelcomeAccessScreen(),
      data: (firebaseUser) {
        if (firebaseUser == null) {
          // ── Onboarding do visitante ──────────────────────────────────
          //
          // O produto começa escolhendo a igreja: sem unidade em foco não há
          // conteúdo a mostrar, porque tudo vive sob "igrejas/{igrejaId}".
          final preferencia = ref.watch(igrejaVisualizadaProvider);

          // Espera a leitura do disco. Decidir com nulo antes disso faria a
          // tela de seleção piscar para quem já escolheu.
          if (!preferencia.carregado) return const SplashScreen();

          if (preferencia.id == null) {
            return const SelectChurchScreen(modo: ModoSelecaoIgreja.onboarding);
          }

          return const WelcomeAccessScreen();
        }

        final usuarioAsync = ref.watch(usuarioAtualProvider);
        return usuarioAsync.when(
          loading: () => const SplashScreen(),
          // Nunca deixa o usuário preso: oferece tentar de novo ou sair.
          error: (_, _) => SplashScreen(
            mensagem: 'Não foi possível carregar seu perfil. '
                'Verifique sua conexão e tente novamente.',
            onTentarNovamente: () => ref.invalidate(usuarioAtualProvider),
            onSair: () => ref.read(authServiceProvider).logout(),
          ),
          data: (usuario) {
            if (usuario == null) {
              // Documento ainda sendo provisionado (logo após o cadastro).
              return SplashScreen(
                mensagem: 'Preparando sua conta...',
                onSair: () => ref.read(authServiceProvider).logout(),
              );
            }

            // Conta sem unidade: cadastro antigo ou provisionamento parcial.
            // Não adivinhamos uma igreja — sem vínculo não há o que liberar.
            final principal = ref.watch(igrejaPrincipalProvider);
            if (principal == null) {
              return const SemIgrejaVinculadaScreen();
            }

            final vinculoAsync = ref.watch(vinculoPrincipalProvider);
            return vinculoAsync.when(
              loading: () => const SplashScreen(),
              error: (_, _) => SplashScreen(
                mensagem: 'Não foi possível verificar seu vínculo com a '
                    'igreja. Verifique sua conexão e tente novamente.',
                onTentarNovamente: () =>
                    ref.invalidate(vinculoPrincipalProvider),
                onSair: () => ref.read(authServiceProvider).logout(),
              ),
              data: (vinculo) {
                // Autenticado, com igreja principal, mas sem documento de
                // vínculo: o cadastro não completou. Tratar como pendente é o
                // mais seguro — nunca liberar conteúdo por ausência de dado.
                if (vinculo == null) {
                  return const AguardandoAprovacaoScreen();
                }

                switch (vinculo.status) {
                  case StatusVinculo.pendente:
                    return const AguardandoAprovacaoScreen();
                  case StatusVinculo.inativo:
                    return const ContaInativaScreen();
                  case StatusVinculo.aprovado:
                    // Liderança ministerial vem do perfil VALIDADO no
                    // servidor, dentro desta unidade.
                    return vinculo.perfil.isLiderancaMinisterial
                        ? const HomeLeaderScreen()
                        : const HomeMemberScreen();
                }
              },
            );
          },
        );
      },
    );
  }
}

/// Conta autenticada que não está vinculada a nenhuma unidade.
///
/// Acontece com cadastros anteriores à arquitetura multi-igreja e com
/// provisionamentos interrompidos. A saída é escolher a igreja, não navegar
/// pelo aplicativo sem escopo.
class SemIgrejaVinculadaScreen extends ConsumerWidget {
  const SemIgrejaVinculadaScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.church_outlined,
                    size: 56, color: Color(0xFF7A0022)),
                const SizedBox(height: 16),
                Text(
                  'Sua conta ainda não está vinculada a uma igreja',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'Fale com a liderança da sua igreja para concluir o '
                  'vínculo. Enquanto isso, você pode sair e entrar novamente '
                  'escolhendo a sua unidade.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 24),
                FilledButton.tonal(
                  onPressed: () => ref.read(authServiceProvider).logout(),
                  child: const Text('Sair'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
