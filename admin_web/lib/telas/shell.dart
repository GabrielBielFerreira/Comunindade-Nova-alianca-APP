import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nova_alianca_core/nova_alianca_core.dart';

import '../config/emulador.dart';
import '../dados/acessos.dart';
import '../estado/providers.dart';
import '../ui/componentes.dart';

/// Item de menu, exibido apenas quando o servidor autorizou a capacidade.
class _ItemMenu {
  const _ItemMenu(this.rota, this.rotulo, this.icone, this.visivel);
  final String rota;
  final String rotulo;
  final IconData icone;
  final bool Function(AcessoIgreja) visivel;
}

const _itens = <_ItemMenu>[
  _ItemMenu('/dashboard', 'Dashboard', Icons.dashboard_outlined, _sempre),
  _ItemMenu('/membros', 'Membros', Icons.people_outline, _sempre),
  _ItemMenu('/lideranca', 'Liderança', Icons.workspace_premium_outlined,
      _podeLideranca),
  _ItemMenu('/financas', 'Finanças', Icons.attach_money, _podeFinancas),
];

bool _sempre(AcessoIgreja _) => true;
bool _podeLideranca(AcessoIgreja a) => a.gerenciarLideranca;
bool _podeFinancas(AcessoIgreja a) => a.lerFinancas;

/// Moldura do painel: navegação lateral, seletor de unidade e logout.
class PainelShell extends ConsumerWidget {
  const PainelShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final acessosAsync = ref.watch(meusAcessosProvider);

    return acessosAsync.when(
      loading: () => const Scaffold(
        body: CarregandoCentralizado(mensagem: 'Carregando seus acessos...'),
      ),
      error: (erro, _) => Scaffold(
        body: EstadoErro(
          erro: erro,
          onTentarNovamente: () => ref.invalidate(meusAcessosProvider),
        ),
      ),
      data: (acessos) {
        if (acessos == null) {
          return const Scaffold(body: CarregandoCentralizado());
        }
        // Autenticado, porém sem nenhuma função administrativa.
        if (acessos.semAcessoAdministrativo) {
          return const _AcessoNegado();
        }

        final acessoAtual = ref.watch(acessoAtualProvider);
        if (acessoAtual == null) return const _AcessoNegado();

        return _Moldura(
          acessos: acessos,
          acessoAtual: acessoAtual,
          child: child,
        );
      },
    );
  }
}

class _Moldura extends ConsumerWidget {
  const _Moldura({
    required this.acessos,
    required this.acessoAtual,
    required this.child,
  });

  final MeusAcessos acessos;
  final AcessoIgreja acessoAtual;
  final Widget child;

  int _indiceAtual(BuildContext context, List<_ItemMenu> visiveis) {
    final rota = GoRouterState.of(context).uri.path;
    final indice = visiveis.indexWhere((i) => rota.startsWith(i.rota));
    return indice < 0 ? 0 : indice;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final visiveis = _itens.where((i) => i.visivel(acessoAtual)).toList();
    final indice = _indiceAtual(context, visiveis);
    final largo = MediaQuery.sizeOf(context).width >= 900;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text('Painel Nova Aliança'),
            const SizedBox(width: 12),
            if (ambienteAtual.isEmulador)
              const Etiqueta(texto: 'EMULADOR', cor: Colors.orange),
          ],
        ),
        actions: [
          if (acessos.precisaSeletor) _SeletorIgreja(acessos: acessos, atual: acessoAtual),
          if (!acessos.precisaSeletor)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Center(child: Text(acessoAtual.nome)),
            ),
          const SizedBox(width: 8),
          _MenuUsuario(acessos: acessos, acessoAtual: acessoAtual),
          const SizedBox(width: 8),
        ],
      ),
      body: Row(
        children: [
          if (largo)
            NavigationRail(
              extended: true,
              minExtendedWidth: 200,
              selectedIndex: indice,
              onDestinationSelected: (i) => context.go(visiveis[i].rota),
              destinations: [
                for (final item in visiveis)
                  NavigationRailDestination(
                    icon: Icon(item.icone),
                    label: Text(item.rotulo),
                  ),
              ],
            ),
          if (largo) const VerticalDivider(width: 1),
          Expanded(child: child),
        ],
      ),
      bottomNavigationBar: largo
          ? null
          : NavigationBar(
              selectedIndex: indice,
              onDestinationSelected: (i) => context.go(visiveis[i].rota),
              destinations: [
                for (final item in visiveis)
                  NavigationDestination(
                    icon: Icon(item.icone),
                    label: item.rotulo,
                  ),
              ],
            ),
    );
  }
}

/// Alterna entre unidades JÁ AUTORIZADAS. Nunca concede permissão: a lista
/// vem de `meusAcessos`, e trocar aqui só muda o foco de leitura.
class _SeletorIgreja extends ConsumerWidget {
  const _SeletorIgreja({required this.acessos, required this.atual});

  final MeusAcessos acessos;
  final AcessoIgreja atual;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: atual.igrejaId.valor,
          borderRadius: BorderRadius.circular(8),
          items: [
            for (final acesso in acessos.acessos)
              DropdownMenuItem(
                value: acesso.igrejaId.valor,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(acesso.nome),
                    if (!acesso.ativa) ...[
                      const SizedBox(width: 8),
                      const Etiqueta(texto: 'inativa', cor: Colors.grey),
                    ],
                  ],
                ),
              ),
          ],
          onChanged: (valor) {
            final id = IgrejaId.tentar(valor);
            if (id == null) return;
            ref.read(igrejaSelecionadaProvider.notifier).state = id;
            // Filtros são por unidade: trocar de igreja limpa o contexto.
            ref.invalidate(filtroFinancasProvider);
          },
        ),
      ),
    );
  }
}

class _MenuUsuario extends ConsumerWidget {
  const _MenuUsuario({required this.acessos, required this.acessoAtual});

  final MeusAcessos acessos;
  final AcessoIgreja acessoAtual;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usuario = ref.watch(authStateProvider).valueOrNull;

    return PopupMenuButton<String>(
      icon: const Icon(Icons.account_circle_outlined),
      onSelected: (valor) async {
        if (valor == 'sair') {
          await ref.read(authProvider).signOut();
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          enabled: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(usuario?.email ?? '—',
                  style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 4),
              Text(
                acessos.isSuperAdmin
                    ? 'Superadministrador'
                    : '${acessoAtual.perfil.rotulo} · ${acessoAtual.nome}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              if (acessoAtual.funcoesAdmin.isNotEmpty)
                Text(
                  acessoAtual.funcoesAdmin.map((f) => f.rotulo).join(', '),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
            ],
          ),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem(
          value: 'sair',
          child: ListTile(
            leading: Icon(Icons.logout),
            title: Text('Sair'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
      ],
    );
  }
}

/// Autenticado, mas sem nenhuma função administrativa em nenhuma unidade.
class _AcessoNegado extends ConsumerWidget {
  const _AcessoNegado();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.lock_outline,
                    size: 56, color: Theme.of(context).colorScheme.error),
                const SizedBox(height: 16),
                Text('Acesso negado',
                    style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 8),
                Text(
                  'Sua conta não possui função administrativa em nenhuma '
                  'unidade. Este painel é exclusivo da liderança e da '
                  'administração. Fale com o pastor da sua igreja.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 24),
                FilledButton.tonal(
                  onPressed: () => ref.read(authProvider).signOut(),
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
