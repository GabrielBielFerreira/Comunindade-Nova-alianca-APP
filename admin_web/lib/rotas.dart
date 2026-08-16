import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'estado/providers.dart';
import 'telas/conteudo_telas.dart';
import 'telas/dashboard_tela.dart';
import 'telas/financas_tela.dart';
import 'telas/igrejas_tela.dart';
import 'telas/lideranca_tela.dart';
import 'telas/login_tela.dart';
import 'telas/membros_tela.dart';
import 'telas/shell.dart';

/// Reemite sempre que a sessão muda, para o GoRouter reavaliar o redirect.
/// É o que faz "sessão expirada" cair no login sem estado órfão.
class _RefreshPorAuth extends ChangeNotifier {
  _RefreshPorAuth(this._ref) {
    _ref.listen(authStateProvider, (_, _) => notifyListeners());
  }
  final Ref _ref;
}

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = _RefreshPorAuth(ref);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: '/dashboard',
    refreshListenable: refresh,
    redirect: (context, state) {
      final auth = ref.read(authStateProvider);
      // Enquanto o estado inicial da sessão não resolve, não redireciona.
      if (auth.isLoading) return null;

      final logado = auth.valueOrNull != null;
      final rota = state.uri.path;
      final emAreaPublica = rota == '/login' || rota == '/recuperar-senha';

      if (!logado) return emAreaPublica ? null : '/login';
      if (logado && emAreaPublica) return '/dashboard';
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (_, _) => const LoginTela()),
      GoRoute(
        path: '/recuperar-senha',
        builder: (_, _) => const RecuperarSenhaTela(),
      ),
      ShellRoute(
        builder: (_, _, child) => PainelShell(child: child),
        routes: [
          GoRoute(path: '/dashboard', builder: (_, _) => const DashboardTela()),
          GoRoute(path: '/membros', builder: (_, _) => const MembrosTela()),
          GoRoute(path: '/lideranca', builder: (_, _) => const LiderancaTela()),
          GoRoute(path: '/avisos', builder: (_, _) => const AvisosTela()),
          GoRoute(
              path: '/programacao', builder: (_, _) => const ProgramacaoTela()),
          GoRoute(path: '/campanhas', builder: (_, _) => const CampanhasTela()),
          GoRoute(
              path: '/ministerios', builder: (_, _) => const MinisteriosTela()),
          GoRoute(
              path: '/devocionais', builder: (_, _) => const DevocionaisTela()),
          GoRoute(path: '/oracao', builder: (_, _) => const OracaoTela()),
          GoRoute(path: '/financas', builder: (_, _) => const FinancasTela()),
          GoRoute(path: '/igrejas', builder: (_, _) => const IgrejasTela()),
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.help_outline, size: 48),
            const SizedBox(height: 12),
            Text('Página não encontrada: ${state.uri.path}'),
            const SizedBox(height: 16),
            FilledButton.tonal(
              onPressed: () => context.go('/dashboard'),
              child: const Text('Ir para o painel'),
            ),
          ],
        ),
      ),
    ),
  );
});
