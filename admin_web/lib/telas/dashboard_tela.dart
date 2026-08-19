import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:nova_alianca_core/nova_alianca_core.dart';

import '../dados/acessos.dart';
import '../dados/auditoria_repository.dart';
import '../dados/conteudo_repository.dart';
import '../estado/providers.dart';
import '../ui/componentes.dart';
import '../ui/tema.dart';

/// Visão geral da unidade em foco.
///
/// Todo número vem de contagem real (agregada no servidor) e toda lista vem de
/// consulta limitada. Onde não há dado, aparece estado vazio — nada é
/// preenchido para "parecer pronto".
class DashboardTela extends ConsumerWidget {
  const DashboardTela({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final acesso = ref.watch(acessoAtualProvider);
    if (acesso == null) return const CarregandoCentralizado();

    final acessos = ref.watch(meusAcessosProvider).valueOrNull;
    final isSuperAdmin = acessos?.isSuperAdmin ?? false;

    return RefreshIndicator(
      onRefresh: () async => recarregarDashboard(ref),
      child: ListView(
        // O padding acompanha a largura: em 320 px, 24 de cada lado comem
        // 15% da tela.
        padding: EdgeInsets.all(espacoDaLargura(context)),
        children: [
          _Saudacao(acesso: acesso, isSuperAdmin: isSuperAdmin),
          const SizedBox(height: 20),
          const _BuscaDashboard(),
          const SizedBox(height: 20),
          const _Metricas(),
          const SizedBox(height: 12),
          _AcoesRapidas(acesso: acesso, isSuperAdmin: isSuperAdmin),
          const SizedBox(height: 24),
          if (acesso.lerFinancas) ...[
            const _SecaoFinanceira(),
            const SizedBox(height: 24),
          ],
          _ColunasOuPilha(
            esquerda: const [
              _CartaoAvisosRecentes(),
              SizedBox(height: 16),
              _CartaoProximasProgramacoes(),
            ],
            direita: [
              if (acesso.moderarOracao) ...const [
                _CartaoOracoesPendentes(),
                SizedBox(height: 16),
              ],
              const _CartaoConfiguracaoUnidade(),
              const SizedBox(height: 16),
              const _CartaoAtividadeAdministrativa(),
            ],
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════
// Cabeçalho: saudação, função e unidade em foco
// ══════════════════════════════════════════════════════════════════════

/// Regras puras da saudação, isoladas para poderem ser testadas sem widget.
class SaudacaoDashboard {
  const SaudacaoDashboard._();

  /// Saudação pelo horário local de quem está usando o painel.
  static String cumprimento(DateTime agora) {
    if (agora.hour < 12) return 'Bom dia';
    if (agora.hour < 18) return 'Boa tarde';
    return 'Boa noite';
  }

  /// Primeiro nome, quando houver. Sem `displayName`, o e-mail identifica a
  /// pessoa — nunca um nome inventado.
  static String primeiroNome(String? displayName, String? email) {
    final nome = displayName?.trim();
    if (nome != null && nome.isNotEmpty) return nome.split(RegExp(r'\s+')).first;
    final e = email?.trim();
    if (e != null && e.isNotEmpty) return e.split('@').first;
    return 'Bem-vindo';
  }
}

class _Saudacao extends ConsumerWidget {
  const _Saudacao({required this.acesso, required this.isSuperAdmin});

  final AcessoIgreja acesso;
  final bool isSuperAdmin;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usuario = ref.watch(authStateProvider).valueOrNull;
    final nome =
        SaudacaoDashboard.primeiroNome(usuario?.displayName, usuario?.email);

    final funcoes = <String>[
      if (isSuperAdmin) 'Superadministrador' else acesso.perfil.rotulo,
      ...acesso.funcoesAdmin.map((f) => f.rotulo),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${SaudacaoDashboard.cumprimento(DateTime.now())}, $nome.',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        // Wrap em vez de Row: em telas estreitas as etiquetas quebram
        // linha em vez de estourar.
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Etiqueta(texto: acesso.nome, cor: Cores.primary),
            for (final f in funcoes) Etiqueta(texto: f, cor: Cores.muted),
            if (!acesso.ativa)
              const Etiqueta(texto: 'UNIDADE INATIVA', cor: Cores.alerta),
          ],
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════════
// Métricas — contagens agregadas
// ══════════════════════════════════════════════════════════════════════

class _Metricas extends ConsumerWidget {
  const _Metricas();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contagemAsync = ref.watch(contagemMembrosProvider);

    return contagemAsync.when(
      loading: () => const _AlturaCarregando(altura: 120),
      error: (erro, _) => EstadoErro(
        erro: erro,
        onTentarNovamente: () => ref.invalidate(contagemMembrosProvider),
      ),
      data: (c) => GradeCartoes(
        children: [
          CartaoMetrica(
            rotulo: 'Cadastros pendentes',
            valor: '${c.pendentes}',
            detalhe: c.pendentes == 0
                ? 'Nada aguardando aprovação'
                : 'Aguardando aprovação',
            icone: Icons.hourglass_empty,
            destaque: c.pendentes > 0,
            onTap: () => context.go('/membros'),
          ),
          CartaoMetrica(
            rotulo: 'Membros aprovados',
            valor: '${c.aprovados}',
            icone: Icons.people_outline,
            onTap: () => context.go('/membros'),
          ),
          CartaoMetrica(
            rotulo: 'Liderança',
            valor: '${c.lideranca}',
            detalhe: 'Pastor, diácono, evangelista e líder',
            icone: Icons.workspace_premium_outlined,
          ),
          CartaoMetrica(
            rotulo: 'Vínculos inativos',
            valor: '${c.inativos}',
            detalhe: 'Histórico preservado',
            icone: Icons.person_off_outlined,
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════
// Ações rápidas — estritamente pelas capacidades do servidor
// ══════════════════════════════════════════════════════════════════════

class _AcoesRapidas extends StatelessWidget {
  const _AcoesRapidas({required this.acesso, required this.isSuperAdmin});

  final AcessoIgreja acesso;
  final bool isSuperAdmin;

  @override
  Widget build(BuildContext context) {
    // Cada ação existe de verdade e leva a uma tela real. Nada aqui aparece
    // por suposição do cliente: `acesso` vem de `meusAcessos`.
    final acoes = <({String rotulo, IconData icone, String rota})>[
      if (acesso.aprovarMembro)
        (
          rotulo: 'Aprovar cadastros',
          icone: Icons.how_to_reg_outlined,
          rota: '/membros'
        ),
      if (acesso.gerenciarConteudo) ...[
        (
          rotulo: 'Novo aviso',
          icone: Icons.campaign_outlined,
          rota: '/avisos?novo=1'
        ),
        (
          rotulo: 'Nova programação',
          icone: Icons.event_outlined,
          rota: '/programacao?novo=1'
        ),
      ],
      if (acesso.moderarOracao)
        (
          rotulo: 'Moderar oração',
          icone: Icons.favorite_outline,
          rota: '/oracao'
        ),
      if (acesso.gerenciarLideranca)
        (
          rotulo: 'Gerir liderança',
          icone: Icons.workspace_premium_outlined,
          rota: '/lideranca'
        ),
      if (acesso.lerFinancas)
        (rotulo: 'Ver finanças', icone: Icons.attach_money, rota: '/financas'),
      if (isSuperAdmin)
        (rotulo: 'Unidades', icone: Icons.church_outlined, rota: '/igrejas'),
    ];

    if (acoes.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final a in acoes)
          OutlinedButton.icon(
            onPressed: () => context.go(a.rota),
            icon: Icon(a.icone, size: 18),
            label: Text(a.rotulo),
          ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════════
// Finanças — somente para quem tem `lerFinancas`
// ══════════════════════════════════════════════════════════════════════

class _SecaoFinanceira extends ConsumerWidget {
  const _SecaoFinanceira();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resumoAsync = ref.watch(resumoFinanceiroProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _TituloSecao(
          titulo: 'Finanças',
          acao: TextButton(
            onPressed: () => context.go('/financas'),
            child: const Text('Ver tudo'),
          ),
        ),
        const SizedBox(height: 12),
        resumoAsync.when(
          loading: () => const _AlturaCarregando(altura: 120),
          error: (erro, _) => EstadoErro(
            erro: erro,
            onTentarNovamente: () => ref.invalidate(resumoFinanceiroProvider),
          ),
          data: (resumo) {
            if (resumo == null) return const SizedBox.shrink();
            if (resumo.quantidade == 0) {
              return const Card(
                child: EstadoVazio(
                  titulo: 'Nenhuma transação registrada',
                  detalhe:
                      'Esta unidade ainda não possui contribuições lançadas.',
                  icone: Icons.receipt_long_outlined,
                ),
              );
            }
            return GradeCartoes(
              children: [
                CartaoMetrica(
                  rotulo: 'Recebido (aprovado)',
                  valor: formatarCentavos(resumo.aprovadoCentavos),
                  icone: Icons.check_circle_outline,
                  destaque: true,
                ),
                CartaoMetrica(
                  rotulo: 'Pendente',
                  valor: formatarCentavos(resumo.pendenteCentavos),
                  icone: Icons.schedule,
                ),
                CartaoMetrica(
                  rotulo: 'Transações',
                  valor: '${resumo.quantidade}',
                  detalhe: 'Aprovadas e pendentes',
                  icone: Icons.receipt_long_outlined,
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════════
// Cartões de lista
// ══════════════════════════════════════════════════════════════════════

class _CartaoAvisosRecentes extends ConsumerWidget {
  const _CartaoAvisosRecentes();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final acesso = ref.watch(acessoAtualProvider);
    if (acesso == null || !acesso.gerenciarConteudo) {
      return const SizedBox.shrink();
    }

    return _CartaoLista<Aviso>(
      titulo: 'Avisos recentes',
      icone: Icons.campaign_outlined,
      rota: '/avisos',
      valor: ref.watch(avisosRecentesProvider),
      vazio: 'Nenhum aviso publicado nesta unidade.',
      linha: (context, a) => _LinhaLista(
        titulo: a.titulo.isEmpty ? '(sem título)' : a.titulo,
        subtitulo: a.publicadoEm == null
            ? 'Sem data de publicação'
            : _dataCurta(a.publicadoEm!),
        etiqueta: a.urgente
            ? const Etiqueta(texto: 'urgente', cor: Cores.erro)
            : (a.ativo
                ? null
                : const Etiqueta(texto: 'inativo', cor: Cores.muted)),
      ),
    );
  }
}

class _CartaoProximasProgramacoes extends ConsumerWidget {
  const _CartaoProximasProgramacoes();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final acesso = ref.watch(acessoAtualProvider);
    if (acesso == null || !acesso.gerenciarConteudo) {
      return const SizedBox.shrink();
    }

    return _CartaoLista<Evento>(
      titulo: 'Próximas programações',
      icone: Icons.event_outlined,
      rota: '/programacao',
      valor: ref.watch(proximosEventosProvider),
      vazio: 'Nenhuma programação futura cadastrada.',
      linha: (context, e) => _LinhaLista(
        titulo: e.titulo.isEmpty ? '(sem título)' : e.titulo,
        subtitulo: [
          _dataHora(e.data),
          if (e.local.isNotEmpty) e.local,
        ].join(' · '),
        etiqueta: e.publico
            ? null
            : const Etiqueta(texto: 'interno', cor: Cores.muted),
      ),
    );
  }
}

class _CartaoOracoesPendentes extends ConsumerWidget {
  const _CartaoOracoesPendentes();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(oracoesPendentesProvider);

    return _CartaoLista<PedidoOracao>(
      titulo: 'Oração aguardando moderação',
      icone: Icons.favorite_outline,
      rota: '/oracao',
      // Mostra só os primeiros; o total fica no rodapé do cartão.
      valor: async.whenData(
        (p) => p.itens.take(ConteudoRepository.limiteDashboard).toList(),
      ),
      rodape: async.valueOrNull == null
          ? null
          : _rodapeFila(async.valueOrNull!),
      vazio: 'Nenhum pedido aguardando decisão.',
      linha: (context, p) => _LinhaLista(
        titulo: p.texto.isEmpty ? '(sem texto)' : p.texto,
        subtitulo: p.nomeExibicao,
        etiqueta: p.urgente
            ? const Etiqueta(texto: 'urgente', cor: Cores.erro)
            : null,
      ),
    );
  }

  /// Diz a verdade sobre o tamanho da fila, inclusive quando a consulta bateu
  /// no teto — "200+" em vez de fingir que são exatamente 200.
  static String? _rodapeFila(Pagina<PedidoOracao> pagina) {
    final n = pagina.length;
    if (n <= ConteudoRepository.limiteDashboard) return null;
    return pagina.truncada
        ? 'Mais de $n pedidos na fila.'
        : '$n pedidos na fila.';
  }
}

// ══════════════════════════════════════════════════════════════════════
// Configuração da unidade e Mercado Pago (informativo)
// ══════════════════════════════════════════════════════════════════════

class _CartaoConfiguracaoUnidade extends ConsumerWidget {
  const _CartaoConfiguracaoUnidade();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final igrejaAsync = ref.watch(igrejaAtualProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: igrejaAsync.when(
          loading: () => const _AlturaCarregando(altura: 80),
          error: (erro, _) => EstadoErro(erro: erro),
          data: (igreja) {
            if (igreja == null) {
              return const EstadoVazio(
                titulo: 'Unidade não encontrada',
                detalhe: 'O documento desta unidade não existe no Firestore.',
                icone: Icons.help_outline,
              );
            }

            // Campos institucionais ainda em branco. A interface diz o que
            // falta em vez de preencher com suposição.
            final faltando = <String>[
              if (igreja.pastorResponsavel == null) 'pastor responsável',
              if (igreja.endereco == null) 'endereço',
              if (igreja.cidadeEstado == null) 'cidade/estado',
              if (igreja.telefone == null) 'telefone',
            ];

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.tune, size: 18, color: Cores.muted),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text('Configuração da unidade',
                          style: Theme.of(context).textTheme.titleMedium),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    Etiqueta(
                      texto: igreja.ativa ? 'ativa' : 'inativa',
                      cor: igreja.ativa ? Cores.sucesso : Cores.alerta,
                    ),
                    Etiqueta(
                      texto:
                          igreja.configurada ? 'configurada' : 'não configurada',
                      cor: igreja.configurada ? Cores.sucesso : Cores.alerta,
                    ),
                  ],
                ),
                if (faltando.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Dados oficiais ainda não informados: '
                    '${faltando.join(', ')}.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 12),
                _StatusMercadoPago(status: igreja.mercadoPagoStatus),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Estritamente informativo: o painel não conecta, não desconecta e não
/// aciona pagamento. Pagamentos online seguem desligados nesta fase.
class _StatusMercadoPago extends StatelessWidget {
  const _StatusMercadoPago({required this.status});

  final StatusMercadoPago status;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.payments_outlined, size: 18, color: Cores.muted),
            const SizedBox(width: 8),
            const Expanded(child: Text('Mercado Pago')),
            Etiqueta(
              texto: status.rotulo,
              cor: status == StatusMercadoPago.conectado
                  ? Cores.sucesso
                  : Cores.muted,
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Pagamentos online estão desativados nesta versão. Este status é '
          'apenas informativo — o painel não recebe nem aprova contribuições.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════════
// Atividade administrativa recente (auditoria)
// ══════════════════════════════════════════════════════════════════════

class _CartaoAtividadeAdministrativa extends ConsumerWidget {
  const _CartaoAtividadeAdministrativa();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(auditoriaRecenteProvider);

    // `null` = perfil sem permissão de ler auditoria. O cartão some em vez de
    // mostrar erro de permissão.
    if (async.valueOrNull == null && !async.isLoading && !async.hasError) {
      return const SizedBox.shrink();
    }

    return _CartaoLista<RegistroAuditoria>(
      titulo: 'Atividade administrativa recente',
      icone: Icons.history,
      valor: async.whenData((l) => l ?? const <RegistroAuditoria>[]),
      vazio: 'Nenhuma ação administrativa registrada ainda.',
      linha: (context, r) => _LinhaLista(
        titulo: r.rotulo,
        subtitulo: [
          if (r.em != null) _dataHora(r.em!),
          if (r.motivo != null && r.motivo!.isNotEmpty) r.motivo!,
        ].join(' · '),
        etiqueta: r.autorSuperAdmin
            ? const Etiqueta(texto: 'super admin', cor: Cores.info)
            : null,
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════
// Busca
// ══════════════════════════════════════════════════════════════════════

/// Busca sobre membros, ministérios, avisos e programações.
///
/// As consultas de conteúdo só são disparadas quando há termo com 2+
/// caracteres: abrir o dashboard não deve custar quatro coleções.
class _BuscaDashboard extends ConsumerStatefulWidget {
  const _BuscaDashboard();

  @override
  ConsumerState<_BuscaDashboard> createState() => _BuscaDashboardState();
}

class _BuscaDashboardState extends ConsumerState<_BuscaDashboard> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final termo = ref.watch(buscaDashboardProvider);
    final ativo = termo.trim().length >= 2;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _controller,
          onChanged: (v) =>
              ref.read(buscaDashboardProvider.notifier).state = v,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: 'Buscar membros, ministérios, avisos e programações',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: termo.isEmpty
                ? null
                : IconButton(
                    tooltip: 'Limpar busca',
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      _controller.clear();
                      ref.read(buscaDashboardProvider.notifier).state = '';
                    },
                  ),
          ),
        ),
        if (termo.trim().isNotEmpty && !ativo) ...[
          const SizedBox(height: 8),
          Text(
            'Digite ao menos 2 caracteres.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
        if (ativo) ...[
          const SizedBox(height: 12),
          _ResultadosBusca(termo: termo.trim().toLowerCase()),
        ],
      ],
    );
  }
}

class _ResultadosBusca extends ConsumerWidget {
  const _ResultadosBusca({required this.termo});

  final String termo;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final membros = ref.watch(membrosProvider).valueOrNull;
    final ministerios = ref.watch(ministeriosProvider).valueOrNull;
    final avisos = ref.watch(avisosProvider).valueOrNull;
    final eventos = ref.watch(eventosProvider).valueOrNull;

    bool casa(String? texto) =>
        texto != null && texto.toLowerCase().contains(termo);

    final grupos = <({String titulo, String rota, List<String> itens})>[
      (
        titulo: 'Membros',
        rota: '/membros',
        itens: (membros?.itens ?? [])
            .where((m) => casa(m.exibicao) || casa(m.email))
            .map((m) => m.exibicao)
            .toList(),
      ),
      (
        titulo: 'Ministérios',
        rota: '/ministerios',
        itens: (ministerios?.itens ?? [])
            .where((m) => casa(m.nome) || casa(m.descricao))
            .map((m) => m.nome)
            .toList(),
      ),
      (
        titulo: 'Avisos',
        rota: '/avisos',
        itens: (avisos?.itens ?? [])
            .where((a) => casa(a.titulo) || casa(a.conteudo))
            .map((a) => a.titulo)
            .toList(),
      ),
      (
        titulo: 'Programação',
        rota: '/programacao',
        itens: (eventos?.itens ?? [])
            .where((e) => casa(e.titulo) || casa(e.local))
            .map((e) => '${e.titulo} · ${_dataCurta(e.data)}')
            .toList(),
      ),
    ].where((g) => g.itens.isNotEmpty).toList();

    final carregando = membros == null ||
        ministerios == null ||
        avisos == null ||
        eventos == null;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: grupos.isEmpty
            ? Row(
                children: [
                  if (carregando)
                    const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else
                    const Icon(Icons.search_off, size: 18, color: Cores.muted),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(carregando
                        ? 'Buscando...'
                        : 'Nada encontrado para "$termo" nos registros '
                            'carregados.'),
                  ),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final g in grupos) ...[
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${g.titulo} (${g.itens.length})',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                        ),
                        TextButton(
                          onPressed: () => context.go(g.rota),
                          child: const Text('Abrir'),
                        ),
                      ],
                    ),
                    for (final item in g.itens.take(4))
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Text('· $item',
                            maxLines: 2, overflow: TextOverflow.ellipsis),
                      ),
                    if (g.itens.length > 4)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          'e mais ${g.itens.length - 4}...',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    const SizedBox(height: 12),
                  ],
                ],
              ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════
// Peças reutilizadas
// ══════════════════════════════════════════════════════════════════════

/// Duas colunas em telas largas, empilhado em telas estreitas.
class _ColunasOuPilha extends StatelessWidget {
  const _ColunasOuPilha({required this.esquerda, required this.direita});

  final List<Widget> esquerda;
  final List<Widget> direita;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 900) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ...esquerda,
              const SizedBox(height: 16),
              ...direita,
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: esquerda,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: direita,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _TituloSecao extends StatelessWidget {
  const _TituloSecao({required this.titulo, this.acao});

  final String titulo;
  final Widget? acao;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(titulo, style: Theme.of(context).textTheme.titleLarge),
        ),
        ?acao,
      ],
    );
  }
}

class _AlturaCarregando extends StatelessWidget {
  const _AlturaCarregando({required this.altura});

  final double altura;

  @override
  Widget build(BuildContext context) =>
      SizedBox(height: altura, child: const CarregandoCentralizado());
}

/// Cartão com título, até N linhas e um link para a tela completa.
class _CartaoLista<T> extends StatelessWidget {
  const _CartaoLista({
    required this.titulo,
    required this.icone,
    required this.valor,
    required this.vazio,
    required this.linha,
    this.rota,
    this.rodape,
  });

  final String titulo;
  final IconData icone;
  final AsyncValue<List<T>> valor;
  final String vazio;
  final Widget Function(BuildContext, T) linha;
  final String? rota;
  final String? rodape;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icone, size: 18, color: Cores.muted),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(titulo,
                      style: Theme.of(context).textTheme.titleMedium),
                ),
                if (rota != null)
                  TextButton(
                    onPressed: () => context.go(rota!),
                    child: const Text('Ver tudo'),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            valor.when(
              loading: () => const _AlturaCarregando(altura: 80),
              error: (erro, _) => EstadoErro(erro: erro),
              data: (itens) {
                if (itens.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(vazio,
                        style: Theme.of(context).textTheme.bodySmall),
                  );
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final item in itens) linha(context, item),
                    if (rodape != null) ...[
                      const SizedBox(height: 8),
                      Text(rodape!,
                          style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _LinhaLista extends StatelessWidget {
  const _LinhaLista({
    required this.titulo,
    required this.subtitulo,
    this.etiqueta,
  });

  final String titulo;
  final String subtitulo;
  final Widget? etiqueta;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                if (subtitulo.isNotEmpty)
                  Text(
                    subtitulo,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
              ],
            ),
          ),
          if (etiqueta != null) ...[
            const SizedBox(width: 8),
            etiqueta!,
          ],
        ],
      ),
    );
  }
}

String _dataCurta(DateTime d) => DateFormat('dd/MM/yyyy').format(d);
String _dataHora(DateTime d) => DateFormat("dd/MM 'às' HH:mm").format(d);
