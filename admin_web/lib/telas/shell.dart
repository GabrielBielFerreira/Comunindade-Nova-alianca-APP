import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nova_alianca_core/nova_alianca_core.dart';

import '../config/ambiente.dart';
import '../dados/acessos.dart';
import '../estado/providers.dart';
import '../ui/componentes.dart';
import '../ui/tema.dart';

/// Item de navegação. `visivel` recebe as capacidades vindas do SERVIDOR —
/// nenhum menu aparece por suposição do cliente.
class ItemMenu {
  const ItemMenu(this.rota, this.rotulo, this.icone, this.visivel);

  final String rota;
  final String rotulo;
  final IconData icone;
  final bool Function(AcessoIgreja) visivel;
}

bool _sempre(AcessoIgreja _) => true;
bool _conteudo(AcessoIgreja a) => a.gerenciarConteudo;
bool _oracao(AcessoIgreja a) => a.moderarOracao;
bool _lideranca(AcessoIgreja a) => a.gerenciarLideranca;
bool _financas(AcessoIgreja a) => a.lerFinancas;

/// Grupos do menu. Só entram módulos que existem de verdade — Escalas,
/// Relatórios, busca global e sino ficam de fora enquanto não houver domínio.
const gruposMenu = <String, List<ItemMenu>>{
  'Visão geral': [
    ItemMenu('/dashboard', 'Dashboard', Icons.dashboard_outlined, _sempre),
  ],
  'Pessoas': [
    ItemMenu('/membros', 'Membros', Icons.people_outline, _sempre),
    ItemMenu(
      '/lideranca',
      'Liderança',
      Icons.workspace_premium_outlined,
      _lideranca,
    ),
  ],
  'Conteúdo': [
    ItemMenu('/avisos', 'Avisos', Icons.campaign_outlined, _conteudo),
    ItemMenu('/programacao', 'Programação', Icons.event_outlined, _conteudo),
    ItemMenu(
      '/campanhas',
      'Campanhas',
      Icons.volunteer_activism_outlined,
      _conteudo,
    ),
    ItemMenu('/ministerios', 'Ministérios', Icons.groups_outlined, _conteudo),
    ItemMenu(
      '/devocionais',
      'Devocionais',
      Icons.menu_book_outlined,
      _conteudo,
    ),
    ItemMenu('/oracao', 'Oração', Icons.favorite_outline, _oracao),
  ],
  'Administração': [
    ItemMenu('/financas', 'Finanças', Icons.attach_money, _financas),
    ItemMenu('/igrejas', 'Igrejas', Icons.church_outlined, _sempreSuperAdmin),
  ],
};

/// `/igrejas` é exclusiva do superadministrador; a capacidade real é conferida
/// no shell, onde o `MeusAcessos` está disponível.
bool _sempreSuperAdmin(AcessoIgreja _) => true;

List<ItemMenu> itensVisiveis(
  AcessoIgreja acesso, {
  required bool isSuperAdmin,
}) {
  final lista = <ItemMenu>[];
  for (final entrada in gruposMenu.entries) {
    for (final item in entrada.value) {
      if (item.rota == '/igrejas') {
        if (isSuperAdmin) lista.add(item);
        continue;
      }
      if (item.visivel(acesso)) lista.add(item);
    }
  }
  return lista;
}

/// Moldura do painel: barra lateral vinho, cabeçalho com a unidade e o
/// usuário autenticado, conteúdo à direita.
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
        if (acessos.semAcessoAdministrativo) return const AcessoNegado();

        final acessoAtual = ref.watch(acessoAtualProvider);
        if (acessoAtual == null) return const AcessoNegado();

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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final largura = MediaQuery.sizeOf(context).width;
    final desktop = largura >= Breakpoints.desktop;
    final visiveis = itensVisiveis(
      acessoAtual,
      isSuperAdmin: acessos.isSuperAdmin,
    );

    final barra = _BarraLateral(
      acessos: acessos,
      acessoAtual: acessoAtual,
      itens: visiveis,
    );

    return Scaffold(
      backgroundColor: Cores.background,
      // Em telas menores a barra vira drawer — nenhum conteúdo é escondido.
      drawer: desktop ? null : Drawer(width: Breakpoints.sidebar, child: barra),
      appBar: desktop
          ? null
          : AppBar(
              title: Text(largura < 380 ? 'Painel' : 'Painel de Gestão'),
              backgroundColor: Cores.primary,
              foregroundColor: Colors.white,
              actions: [
                _AcoesCabecalho(
                  acessos: acessos,
                  acessoAtual: acessoAtual,
                  compacto: largura < Breakpoints.tablet,
                ),
              ],
            ),
      body: Row(
        children: [
          if (desktop) SizedBox(width: Breakpoints.sidebar, child: barra),
          Expanded(
            child: Column(
              children: [
                if (desktop)
                  _Cabecalho(acessos: acessos, acessoAtual: acessoAtual),
                Expanded(child: child),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════
// Barra lateral
// ══════════════════════════════════════════════════════════════════════

class _BarraLateral extends ConsumerWidget {
  const _BarraLateral({
    required this.acessos,
    required this.acessoAtual,
    required this.itens,
  });

  final MeusAcessos acessos;
  final AcessoIgreja acessoAtual;
  final List<ItemMenu> itens;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rotaAtual = GoRouterState.of(context).uri.path;

    return Container(
      color: Cores.primary,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _LogoCabecalho(),
            const SizedBox(height: 8),
            _MenuNovaAtividade(acesso: acessoAtual),
            const SizedBox(height: 8),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  for (final grupo in gruposMenu.entries)
                    ..._construirGrupo(
                      context,
                      grupo.key,
                      grupo.value,
                      rotaAtual,
                    ),
                ],
              ),
            ),
            const Divider(color: Colors.white24, height: 1),
            _ItemSair(),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  List<Widget> _construirGrupo(
    BuildContext context,
    String titulo,
    List<ItemMenu> doGrupo,
    String rotaAtual,
  ) {
    final visiveisDoGrupo = doGrupo
        .where((i) => itens.any((v) => v.rota == i.rota))
        .toList();
    if (visiveisDoGrupo.isEmpty) return const [];

    return [
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
        child: Text(
          titulo.toUpperCase(),
          style: const TextStyle(
            color: Colors.white54,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
          ),
        ),
      ),
      for (final item in visiveisDoGrupo)
        _ItemNavegacao(item: item, ativo: rotaAtual.startsWith(item.rota)),
    ];
  }
}

class _LogoCabecalho extends StatelessWidget {
  const _LogoCabecalho();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.asset(
              'assets/images/logo_nova_alianca.png',
              width: 40,
              height: 40,
              fit: BoxFit.contain,
              // Se o ativo faltar, o painel continua utilizável.
              errorBuilder: (_, _, _) => const Icon(
                Icons.church_outlined,
                color: Colors.white,
                size: 32,
              ),
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Nova Aliança',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    height: 1.1,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Painel de Gestão',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ItemNavegacao extends StatelessWidget {
  const _ItemNavegacao({required this.item, required this.ativo});

  final ItemMenu item;
  final bool ativo;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Material(
        color: ativo ? Colors.white : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () {
            // Fecha o drawer antes de navegar em telas pequenas.
            final scaffold = Scaffold.maybeOf(context);
            if (scaffold?.isDrawerOpen ?? false) Navigator.of(context).pop();
            context.go(item.rota);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Icon(
                  item.icone,
                  size: 20,
                  color: ativo ? Cores.primary : Colors.white,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    item.rotulo,
                    style: TextStyle(
                      color: ativo ? Cores.primary : Colors.white,
                      fontWeight: ativo ? FontWeight.w700 : FontWeight.w500,
                      fontSize: 14.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// "Nova atividade" — menu real, filtrado pelas capacidades. Cada opção leva a
/// um formulário que existe; nada aqui é decorativo.
class _MenuNovaAtividade extends ConsumerWidget {
  const _MenuNovaAtividade({required this.acesso});

  final AcessoIgreja acesso;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final opcoes = <({String rota, String rotulo, IconData icone})>[
      if (acesso.gerenciarConteudo) ...[
        (
          rota: '/avisos?novo=1',
          rotulo: 'Novo aviso',
          icone: Icons.campaign_outlined,
        ),
        (
          rota: '/programacao?novo=1',
          rotulo: 'Novo evento',
          icone: Icons.event_outlined,
        ),
        (
          rota: '/campanhas?novo=1',
          rotulo: 'Nova campanha',
          icone: Icons.volunteer_activism_outlined,
        ),
        (
          rota: '/ministerios?novo=1',
          rotulo: 'Novo ministério',
          icone: Icons.groups_outlined,
        ),
        (
          rota: '/devocionais?novo=1',
          rotulo: 'Novo devocional',
          icone: Icons.menu_book_outlined,
        ),
      ],
    ];

    // Sem nenhuma ação autorizada, o botão simplesmente não existe.
    if (opcoes.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: PopupMenuButton<String>(
        tooltip: 'Criar novo conteúdo',
        position: PopupMenuPosition.under,
        onSelected: (rota) => context.go(rota),
        itemBuilder: (context) => [
          for (final o in opcoes)
            PopupMenuItem(
              value: o.rota,
              child: Row(
                children: [
                  Icon(o.icone, size: 18, color: Cores.primary),
                  const SizedBox(width: 10),
                  Text(o.rotulo),
                ],
              ),
            ),
        ],
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
          ),
          // Com a fonte do sistema ampliada, o rotulo passa da largura fixa
          // da barra (268 px) e a Row estourava. FittedBox encolhe o
          // conjunto em vez de cortar a palavra ou vazar o layout.
          child: const FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add, size: 19, color: Cores.primary),
                SizedBox(width: 8),
                Text(
                  'Nova atividade',
                  style: TextStyle(
                    color: Cores.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 14.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ItemSair extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () => ref.read(authProvider).signOut(),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Icon(Icons.logout, size: 20, color: Colors.white),
                SizedBox(width: 12),
                Text(
                  'Sair',
                  style: TextStyle(color: Colors.white, fontSize: 14.5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════
// Cabeçalho
// ══════════════════════════════════════════════════════════════════════

class _Cabecalho extends ConsumerWidget {
  const _Cabecalho({required this.acessos, required this.acessoAtual});

  final MeusAcessos acessos;
  final AcessoIgreja acessoAtual;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        color: Cores.surface,
        border: Border(bottom: BorderSide(color: Cores.line)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    acessoAtual.nome,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                if (!acessoAtual.ativa) ...[
                  const SizedBox(width: 10),
                  const Etiqueta(texto: 'UNIDADE INATIVA', cor: Cores.alerta),
                ],
                if (ambienteAtual.isEmulador) ...[
                  const SizedBox(width: 10),
                  const Etiqueta(texto: 'EMULADOR', cor: Cores.alerta),
                ],
              ],
            ),
          ),
          _AcoesCabecalho(acessos: acessos, acessoAtual: acessoAtual),
        ],
      ),
    );
  }
}

class _AcoesCabecalho extends ConsumerWidget {
  const _AcoesCabecalho({
    required this.acessos,
    required this.acessoAtual,
    this.compacto = false,
  });

  final MeusAcessos acessos;
  final AcessoIgreja acessoAtual;
  final bool compacto;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (acessos.precisaSeletor)
          _SeletorIgreja(
            acessos: acessos,
            atual: acessoAtual,
            compacto: compacto,
          ),
        const SizedBox(width: 8),
        _MenuUsuario(
          acessos: acessos,
          acessoAtual: acessoAtual,
          compacto: compacto,
        ),
      ],
    );
  }
}

/// Alterna entre unidades JÁ AUTORIZADAS. Nunca concede permissão: a lista vem
/// de `meusAcessos`, e trocar aqui só muda o foco de leitura.
class _SeletorIgreja extends ConsumerWidget {
  const _SeletorIgreja({
    required this.acessos,
    required this.atual,
    this.compacto = false,
  });

  final MeusAcessos acessos;
  final AcessoIgreja atual;
  final bool compacto;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    void selecionar(String? valor) {
      final id = IgrejaId.tentar(valor);
      if (id == null) return;
      ref.read(igrejaSelecionadaProvider.notifier).state = id;
      // Filtros são por unidade: trocar de igreja limpa o contexto.
      ref.invalidate(filtroFinancasProvider);
    }

    if (compacto) {
      return PopupMenuButton<String>(
        tooltip: 'Trocar unidade',
        icon: const Icon(Icons.church_outlined),
        initialValue: atual.igrejaId.valor,
        onSelected: selecionar,
        itemBuilder: (context) => [
          for (final acesso in acessos.acessos)
            PopupMenuItem(
              value: acesso.igrejaId.valor,
              child: Row(
                children: [
                  Expanded(
                    child: Text(acesso.nome, overflow: TextOverflow.ellipsis),
                  ),
                  if (!acesso.ativa) ...[
                    const SizedBox(width: 8),
                    const Etiqueta(texto: 'inativa', cor: Cores.muted),
                  ],
                ],
              ),
            ),
        ],
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Cores.soft,
        borderRadius: BorderRadius.circular(10),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: atual.igrejaId.valor,
          borderRadius: BorderRadius.circular(10),
          icon: const Icon(Icons.expand_more, color: Cores.primary),
          style: const TextStyle(color: Cores.primary, fontSize: 14),
          items: [
            for (final acesso in acessos.acessos)
              DropdownMenuItem(
                value: acesso.igrejaId.valor,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      acesso.nome,
                      style: const TextStyle(
                        color: Cores.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (!acesso.ativa) ...[
                      const SizedBox(width: 8),
                      const Etiqueta(texto: 'inativa', cor: Cores.muted),
                    ],
                  ],
                ),
              ),
          ],
          onChanged: selecionar,
        ),
      ),
    );
  }
}

/// Mostra SEMPRE o usuário autenticado — nunca nome ou foto fictícios.
class _MenuUsuario extends ConsumerWidget {
  const _MenuUsuario({
    required this.acessos,
    required this.acessoAtual,
    this.compacto = false,
  });

  final MeusAcessos acessos;
  final AcessoIgreja acessoAtual;
  final bool compacto;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usuario = ref.watch(authStateProvider).valueOrNull;
    // Sem displayName, o e-mail identifica a pessoa.
    final nome = (usuario?.displayName?.trim().isNotEmpty ?? false)
        ? usuario!.displayName!.trim()
        : (usuario?.email ?? '—');

    final papel = acessos.isSuperAdmin
        ? 'Superadministrador'
        : acessoAtual.perfil.rotulo;
    final avatar = CircleAvatar(
      radius: 17,
      backgroundColor: Cores.soft,
      child: Text(
        nome.isEmpty ? '?' : nome[0].toUpperCase(),
        style: const TextStyle(
          color: Cores.primary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );

    return PopupMenuButton<String>(
      tooltip: 'Conta',
      position: PopupMenuPosition.under,
      onSelected: (valor) async {
        if (valor == 'sair') await ref.read(authProvider).signOut();
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          enabled: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                usuario?.email ?? '—',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 4),
              Text(
                '$papel · ${acessoAtual.nome}',
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
      child: compacto
          ? avatar
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                avatar,
                const SizedBox(width: 10),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 180),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        nome,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: Cores.titulo,
                        ),
                      ),
                      Text(
                        papel,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Cores.muted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

/// Autenticado, mas sem nenhuma função administrativa em nenhuma unidade.
class AcessoNegado extends ConsumerWidget {
  const AcessoNegado({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Cores.background,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.lock_outline, size: 56, color: Cores.erro),
                const SizedBox(height: 16),
                Text(
                  'Acesso negado',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
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
