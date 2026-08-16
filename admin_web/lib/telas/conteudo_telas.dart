import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:nova_alianca_core/nova_alianca_core.dart';

import '../dados/conteudo_repository.dart';
import '../dados/membros_repository.dart';
import '../estado/providers.dart';
import '../ui/componentes.dart';
import '../ui/tema.dart';

final _dataHora = DateFormat('dd/MM/yyyy HH:mm');
final _dataCurta = DateFormat('dd/MM/yyyy');

/// Moldura comum das telas de conteúdo: título, botão de criar e corpo.
///
/// O botão só aparece quando o servidor autorizou `gerenciarConteudo`; a
/// segurança real continua nas Rules.
class _PaginaConteudo extends ConsumerWidget {
  const _PaginaConteudo({
    required this.titulo,
    required this.descricao,
    required this.rotuloNovo,
    required this.onNovo,
    required this.corpo,
  });

  final String titulo;
  final String descricao;
  final String rotuloNovo;
  final VoidCallback onNovo;
  final Widget corpo;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final acesso = ref.watch(acessoAtualProvider);
    final pode = acesso?.gerenciarConteudo ?? false;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(titulo,
                        style: Theme.of(context).textTheme.headlineSmall),
                    const SizedBox(height: 4),
                    Text(descricao,
                        style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
              if (pode)
                FilledButton.icon(
                  onPressed: onNovo,
                  icon: const Icon(Icons.add, size: 18),
                  label: Text(rotuloNovo),
                ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(child: corpo),
      ],
    );
  }
}

/// Lista genérica com estados de carregamento, erro e vazio.
class _Lista<T> extends StatelessWidget {
  const _Lista({
    required this.async,
    required this.vazio,
    required this.item,
    this.onRecarregar,
  });

  final AsyncValue<List<T>> async;
  final Widget vazio;
  final Widget Function(BuildContext, T) item;
  final VoidCallback? onRecarregar;

  @override
  Widget build(BuildContext context) {
    return async.when(
      loading: () => const CarregandoCentralizado(),
      error: (e, _) => EstadoErro(erro: e, onTentarNovamente: onRecarregar),
      data: (lista) {
        if (lista.isEmpty) return vazio;
        return ListView.separated(
          padding: const EdgeInsets.all(20),
          itemCount: lista.length,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (context, i) => item(context, lista[i]),
        );
      },
    );
  }
}

/// Executa uma mutação mostrando o resultado — inclusive a negação do
/// servidor, que é informação útil e não deve ser engolida.
Future<void> _executar(
  BuildContext context,
  Future<void> Function() acao, {
  required String sucesso,
}) async {
  try {
    await acao();
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(sucesso)));
    }
  } catch (erro) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Não foi possível concluir: $erro'),
          backgroundColor: Cores.erro,
        ),
      );
    }
  }
}

/// `?novo=1` na URL abre o formulário — é o que faz o menu "Nova atividade"
/// levar direto à criação.
bool _pediuNovo(BuildContext context) =>
    GoRouterState.of(context).uri.queryParameters['novo'] == '1';

void _limparQuery(BuildContext context, String rota) {
  if (_pediuNovo(context)) context.go(rota);
}

// ══════════════════════════════════════════════════════════════════════
// AVISOS
// ══════════════════════════════════════════════════════════════════════

class AvisosTela extends ConsumerStatefulWidget {
  const AvisosTela({super.key});

  @override
  ConsumerState<AvisosTela> createState() => _AvisosTelaState();
}

class _AvisosTelaState extends ConsumerState<AvisosTela> {
  bool _abriu = false;

  @override
  Widget build(BuildContext context) {
    if (_pediuNovo(context) && !_abriu) {
      _abriu = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _abrirForm(null));
    }

    return _PaginaConteudo(
      titulo: 'Avisos',
      descricao: 'Comunicados publicados no aplicativo desta igreja.',
      rotuloNovo: 'Novo aviso',
      onNovo: () => _abrirForm(null),
      corpo: _Lista<Aviso>(
        async: ref.watch(avisosProvider),
        onRecarregar: () => ref.invalidate(avisosProvider),
        vazio: const EstadoVazio(
          titulo: 'Nenhum aviso publicado',
          detalhe: 'Crie o primeiro aviso desta igreja.',
          icone: Icons.campaign_outlined,
        ),
        item: (context, a) => Card(
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            title: Text(a.titulo,
                style: Theme.of(context).textTheme.titleMedium),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 6),
                Text(a.conteudo,
                    maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 8),
                Wrap(spacing: 8, runSpacing: 4, children: [
                  Etiqueta(
                    texto: a.ativo ? 'Publicado' : 'Despublicado',
                    cor: a.ativo ? Cores.sucesso : Cores.muted,
                  ),
                  Etiqueta(
                    texto: a.publico ? 'Público' : 'Somente membros',
                    cor: a.publico ? Cores.info : Cores.corpo,
                  ),
                  if (a.urgente)
                    const Etiqueta(texto: 'Urgente', cor: Cores.erro),
                  if (a.publicadoEm != null)
                    Etiqueta(
                        texto: _dataCurta.format(a.publicadoEm!),
                        cor: Cores.muted),
                ]),
              ],
            ),
            trailing: Row(mainAxisSize: MainAxisSize.min, children: [
              IconButton(
                tooltip: 'Editar',
                icon: const Icon(Icons.edit_outlined),
                onPressed: () => _abrirForm(a),
              ),
              IconButton(
                tooltip: a.ativo ? 'Despublicar' : 'Publicar',
                icon: Icon(a.ativo
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined),
                onPressed: () => _executar(
                  context,
                  () => ref
                      .read(conteudoRepositoryProvider)!
                      .definirAvisoAtivo(a.id, !a.ativo),
                  sucesso: a.ativo ? 'Aviso despublicado.' : 'Aviso publicado.',
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  Future<void> _abrirForm(Aviso? aviso) async {
    final repo = ref.read(conteudoRepositoryProvider);
    if (repo == null) return;

    final titulo = TextEditingController(text: aviso?.titulo ?? '');
    final conteudo = TextEditingController(text: aviso?.conteudo ?? '');
    var urgente = aviso?.urgente ?? false;
    var publico = aviso?.publico ?? false;

    final salvar = await showDialog<bool>(
      context: context,
      builder: (d) => StatefulBuilder(
        builder: (d, setState) => AlertDialog(
          title: Text(aviso == null ? 'Novo aviso' : 'Editar aviso'),
          content: SizedBox(
            width: 520,
            child: SingleChildScrollView(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                TextField(
                  controller: titulo,
                  autofocus: true,
                  decoration: const InputDecoration(labelText: 'Título'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: conteudo,
                  minLines: 4,
                  maxLines: 8,
                  decoration: const InputDecoration(labelText: 'Conteúdo'),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: urgente,
                  onChanged: (v) => setState(() => urgente = v),
                  title: const Text('Marcar como urgente'),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: publico,
                  onChanged: (v) => setState(() => publico = v),
                  title: const Text('Visível para visitantes'),
                  subtitle: const Text(
                      'Desligado: só membros aprovados desta igreja veem.'),
                ),
              ]),
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(d).pop(false),
                child: const Text('Cancelar')),
            FilledButton(
                onPressed: () => Navigator.of(d).pop(true),
                child: const Text('Salvar')),
          ],
        ),
      ),
    );

    if (!mounted) return;

    _limparQuery(context, '/avisos');
    _abriu = false;

    if (salvar != true) return;
    if (titulo.text.trim().isEmpty) return;

    if (!mounted) return;
    await _executar(
      context,
      () => repo.salvarAviso(Aviso(
        id: aviso?.id ?? '',
        titulo: titulo.text.trim(),
        conteudo: conteudo.text.trim(),
        prioridade: urgente ? 'urgente' : 'normal',
        publico: publico,
        ativo: aviso?.ativo ?? true,
        publicadoEm: aviso?.publicadoEm,
      )),
      sucesso: aviso == null ? 'Aviso criado.' : 'Aviso atualizado.',
    );
  }
}

// ══════════════════════════════════════════════════════════════════════
// PROGRAMAÇÃO / EVENTOS
// ══════════════════════════════════════════════════════════════════════

class ProgramacaoTela extends ConsumerStatefulWidget {
  const ProgramacaoTela({super.key});

  @override
  ConsumerState<ProgramacaoTela> createState() => _ProgramacaoTelaState();
}

class _ProgramacaoTelaState extends ConsumerState<ProgramacaoTela> {
  bool _abriu = false;

  @override
  Widget build(BuildContext context) {
    if (_pediuNovo(context) && !_abriu) {
      _abriu = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _abrirForm(null));
    }

    return _PaginaConteudo(
      titulo: 'Programação',
      descricao: 'Cultos, reuniões e eventos desta igreja.',
      rotuloNovo: 'Novo evento',
      onNovo: () => _abrirForm(null),
      corpo: _Lista<Evento>(
        async: ref.watch(eventosProvider),
        onRecarregar: () => ref.invalidate(eventosProvider),
        vazio: const EstadoVazio(
          titulo: 'Nenhum evento na programação',
          detalhe: 'Crie o primeiro evento desta igreja.',
          icone: Icons.event_outlined,
        ),
        item: (context, e) => Card(
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            title: Text(e.titulo,
                style: Theme.of(context).textTheme.titleMedium),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 6),
                Text('${_dataHora.format(e.data)}'
                    '${e.local.isEmpty ? '' : ' · ${e.local}'}'),
                if (e.responsavelNome != null)
                  Text('Responsável: ${e.responsavelNome}'),
                const SizedBox(height: 8),
                Wrap(spacing: 8, runSpacing: 4, children: [
                  Etiqueta(
                    texto: e.cancelado ? 'Cancelado' : 'Confirmado',
                    cor: e.cancelado ? Cores.erro : Cores.sucesso,
                  ),
                  Etiqueta(
                    texto: e.publico ? 'Público' : 'Interno',
                    cor: e.publico ? Cores.info : Cores.corpo,
                  ),
                ]),
              ],
            ),
            trailing: Row(mainAxisSize: MainAxisSize.min, children: [
              IconButton(
                tooltip: 'Editar',
                icon: const Icon(Icons.edit_outlined),
                onPressed: () => _abrirForm(e),
              ),
              IconButton(
                tooltip: e.cancelado ? 'Reativar' : 'Cancelar',
                icon: Icon(e.cancelado
                    ? Icons.event_available_outlined
                    : Icons.event_busy_outlined),
                onPressed: () => _executar(
                  context,
                  () => ref
                      .read(conteudoRepositoryProvider)!
                      .definirEventoCancelado(e.id, !e.cancelado),
                  sucesso:
                      e.cancelado ? 'Evento reativado.' : 'Evento cancelado.',
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  Future<void> _abrirForm(Evento? evento) async {
    final repo = ref.read(conteudoRepositoryProvider);
    if (repo == null) return;

    final titulo = TextEditingController(text: evento?.titulo ?? '');
    final descricao = TextEditingController(text: evento?.descricao ?? '');
    final local = TextEditingController(text: evento?.local ?? '');
    var data = evento?.data ?? DateTime.now().add(const Duration(days: 1));
    var publico = evento?.publico ?? true;
    MembroPainel? responsavel;

    final salvar = await showDialog<bool>(
      context: context,
      builder: (d) => StatefulBuilder(
        builder: (d, setState) => AlertDialog(
          title: Text(evento == null ? 'Novo evento' : 'Editar evento'),
          content: SizedBox(
            width: 520,
            child: SingleChildScrollView(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                TextField(
                  controller: titulo,
                  autofocus: true,
                  decoration: const InputDecoration(labelText: 'Título'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descricao,
                  minLines: 2,
                  maxLines: 5,
                  decoration: const InputDecoration(labelText: 'Descrição'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: local,
                  decoration: const InputDecoration(labelText: 'Local'),
                ),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Data e hora'),
                  subtitle: Text(_dataHora.format(data)),
                  trailing: const Icon(Icons.calendar_today, size: 18),
                  onTap: () async {
                    final dia = await showDatePicker(
                      context: d,
                      initialDate: data,
                      firstDate: DateTime(DateTime.now().year - 1),
                      lastDate: DateTime(DateTime.now().year + 3),
                    );
                    if (dia == null) return;
                    if (!d.mounted) return;
                    final hora = await showTimePicker(
                      context: d,
                      initialTime: TimeOfDay.fromDateTime(data),
                    );
                    setState(() => data = DateTime(dia.year, dia.month, dia.day,
                        hora?.hour ?? 0, hora?.minute ?? 0));
                  },
                ),
                // Responsável escolhido entre membros APROVADOS desta unidade.
                _SeletorResponsavel(
                  atualNome: responsavel?.exibicao ?? evento?.responsavelNome,
                  onSelecionado: (m) => setState(() => responsavel = m),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: publico,
                  onChanged: (v) => setState(() => publico = v),
                  title: const Text('Visível para visitantes'),
                ),
              ]),
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(d).pop(false),
                child: const Text('Cancelar')),
            FilledButton(
                onPressed: () => Navigator.of(d).pop(true),
                child: const Text('Salvar')),
          ],
        ),
      ),
    );

    if (!mounted) return;

    _limparQuery(context, '/programacao');
    _abriu = false;

    if (salvar != true || titulo.text.trim().isEmpty) return;
    if (!mounted) return;

    await _executar(
      context,
      () => repo.salvarEvento(Evento(
        id: evento?.id ?? '',
        titulo: titulo.text.trim(),
        descricao: descricao.text.trim(),
        data: data,
        local: local.text.trim(),
        publico: publico,
        cancelado: evento?.cancelado ?? false,
        responsavelId: responsavel?.vinculo.uid ?? evento?.responsavelId,
        responsavelNome: responsavel?.exibicao ?? evento?.responsavelNome,
      )),
      sucesso: evento == null ? 'Evento criado.' : 'Evento atualizado.',
    );
  }
}

/// Escolhe um responsável entre os membros aprovados da unidade em foco.
class _SeletorResponsavel extends ConsumerWidget {
  const _SeletorResponsavel({this.atualNome, required this.onSelecionado});

  final String? atualNome;
  final ValueChanged<MembroPainel> onSelecionado;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final membros = ref.watch(membrosProvider).valueOrNull ?? const [];
    final aprovados = membros
        .where((m) => m.vinculo.status == StatusVinculo.aprovado)
        .toList();

    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: const Text('Responsável'),
      subtitle: Text(atualNome ?? 'Não definido'),
      trailing: const Icon(Icons.person_search_outlined, size: 20),
      onTap: aprovados.isEmpty
          ? null
          : () async {
              final escolhido = await showDialog<MembroPainel>(
                context: context,
                builder: (d) => SimpleDialog(
                  title: const Text('Selecionar responsável'),
                  children: [
                    for (final m in aprovados)
                      SimpleDialogOption(
                        onPressed: () => Navigator.of(d).pop(m),
                        child: Text(
                            '${m.exibicao} — ${m.vinculo.perfil.rotulo}'),
                      ),
                  ],
                ),
              );
              if (escolhido != null) onSelecionado(escolhido);
            },
    );
  }
}

// ══════════════════════════════════════════════════════════════════════
// CAMPANHAS
// ══════════════════════════════════════════════════════════════════════

class CampanhasTela extends ConsumerStatefulWidget {
  const CampanhasTela({super.key});

  @override
  ConsumerState<CampanhasTela> createState() => _CampanhasTelaState();
}

class _CampanhasTelaState extends ConsumerState<CampanhasTela> {
  bool _abriu = false;

  @override
  Widget build(BuildContext context) {
    if (_pediuNovo(context) && !_abriu) {
      _abriu = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _abrirForm(null));
    }

    return _PaginaConteudo(
      titulo: 'Campanhas',
      descricao: 'Campanhas e arrecadações desta igreja.',
      rotuloNovo: 'Nova campanha',
      onNovo: () => _abrirForm(null),
      corpo: _Lista<Campanha>(
        async: ref.watch(campanhasProvider),
        onRecarregar: () => ref.invalidate(campanhasProvider),
        vazio: const EstadoVazio(
          titulo: 'Nenhuma campanha cadastrada',
          icone: Icons.volunteer_activism_outlined,
        ),
        item: (context, c) => Card(
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            title:
                Text(c.titulo, style: Theme.of(context).textTheme.titleMedium),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 6),
                Text(c.descricao, maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 8),
                Wrap(spacing: 8, runSpacing: 4, children: [
                  Etiqueta(
                    texto: c.status == 'ativa' ? 'Ativa' : 'Encerrada',
                    cor: c.status == 'ativa' ? Cores.sucesso : Cores.muted,
                  ),
                  if (c.metaCentavos > 0)
                    Etiqueta(
                        texto: 'Meta ${formatarCentavos(c.metaCentavos)}',
                        cor: Cores.info),
                  Etiqueta(
                      texto: 'Início ${_dataCurta.format(c.dataInicio)}',
                      cor: Cores.muted),
                ]),
              ],
            ),
            trailing: Row(mainAxisSize: MainAxisSize.min, children: [
              IconButton(
                tooltip: 'Editar',
                icon: const Icon(Icons.edit_outlined),
                onPressed: () => _abrirForm(c),
              ),
              IconButton(
                tooltip: c.status == 'ativa' ? 'Encerrar' : 'Reabrir',
                icon: Icon(c.status == 'ativa'
                    ? Icons.stop_circle_outlined
                    : Icons.play_circle_outline),
                onPressed: () => _executar(
                  context,
                  () => ref
                      .read(conteudoRepositoryProvider)!
                      .definirCampanhaStatus(
                          c.id, c.status == 'ativa' ? 'encerrada' : 'ativa'),
                  sucesso: 'Status da campanha atualizado.',
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  Future<void> _abrirForm(Campanha? campanha) async {
    final repo = ref.read(conteudoRepositoryProvider);
    if (repo == null) return;

    final titulo = TextEditingController(text: campanha?.titulo ?? '');
    final descricao = TextEditingController(text: campanha?.descricao ?? '');
    // Meta digitada em reais, persistida em centavos.
    final meta = TextEditingController(
      text: campanha == null || campanha.metaCentavos == 0
          ? ''
          : (campanha.metaCentavos / 100).toStringAsFixed(2),
    );
    var inicio = campanha?.dataInicio ?? DateTime.now();

    final salvar = await showDialog<bool>(
      context: context,
      builder: (d) => StatefulBuilder(
        builder: (d, setState) => AlertDialog(
          title: Text(campanha == null ? 'Nova campanha' : 'Editar campanha'),
          content: SizedBox(
            width: 520,
            child: SingleChildScrollView(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                TextField(
                  controller: titulo,
                  autofocus: true,
                  decoration: const InputDecoration(labelText: 'Título'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descricao,
                  minLines: 3,
                  maxLines: 6,
                  decoration: const InputDecoration(labelText: 'Descrição'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: meta,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Meta (R\$)',
                    helperText: 'Opcional. Deixe vazio para não definir meta.',
                  ),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Início'),
                  subtitle: Text(_dataCurta.format(inicio)),
                  trailing: const Icon(Icons.calendar_today, size: 18),
                  onTap: () async {
                    final dia = await showDatePicker(
                      context: d,
                      initialDate: inicio,
                      firstDate: DateTime(DateTime.now().year - 1),
                      lastDate: DateTime(DateTime.now().year + 3),
                    );
                    if (dia != null) setState(() => inicio = dia);
                  },
                ),
              ]),
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(d).pop(false),
                child: const Text('Cancelar')),
            FilledButton(
                onPressed: () => Navigator.of(d).pop(true),
                child: const Text('Salvar')),
          ],
        ),
      ),
    );

    if (!mounted) return;

    _limparQuery(context, '/campanhas');
    _abriu = false;

    if (salvar != true || titulo.text.trim().isEmpty) return;
    if (!mounted) return;

    final reais = double.tryParse(meta.text.trim().replaceAll(',', '.')) ?? 0;

    await _executar(
      context,
      () => repo.salvarCampanha(Campanha(
        id: campanha?.id ?? '',
        titulo: titulo.text.trim(),
        descricao: descricao.text.trim(),
        dataInicio: inicio,
        dataFim: campanha?.dataFim,
        metaCentavos: (reais * 100).round(),
        status: campanha?.status ?? 'ativa',
        publico: campanha?.publico ?? true,
      )),
      sucesso: campanha == null ? 'Campanha criada.' : 'Campanha atualizada.',
    );
  }
}

// ══════════════════════════════════════════════════════════════════════
// MINISTÉRIOS
// ══════════════════════════════════════════════════════════════════════

class MinisteriosTela extends ConsumerStatefulWidget {
  const MinisteriosTela({super.key});

  @override
  ConsumerState<MinisteriosTela> createState() => _MinisteriosTelaState();
}

class _MinisteriosTelaState extends ConsumerState<MinisteriosTela> {
  bool _abriu = false;

  @override
  Widget build(BuildContext context) {
    if (_pediuNovo(context) && !_abriu) {
      _abriu = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _abrirForm(null));
    }

    return _PaginaConteudo(
      titulo: 'Ministérios',
      descricao: 'Grupos e ministérios desta igreja.',
      rotuloNovo: 'Novo ministério',
      onNovo: () => _abrirForm(null),
      corpo: _Lista<Ministerio>(
        async: ref.watch(ministeriosProvider),
        onRecarregar: () => ref.invalidate(ministeriosProvider),
        vazio: const EstadoVazio(
          titulo: 'Nenhum ministério cadastrado',
          icone: Icons.groups_outlined,
        ),
        item: (context, m) => Card(
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            title: Text(m.nome, style: Theme.of(context).textTheme.titleMedium),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 6),
                if (m.descricao.isNotEmpty)
                  Text(m.descricao,
                      maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 8),
                Wrap(spacing: 8, runSpacing: 4, children: [
                  Etiqueta(
                    texto: m.ativo ? 'Ativo' : 'Inativo',
                    cor: m.ativo ? Cores.sucesso : Cores.muted,
                  ),
                  Etiqueta(
                    texto: 'Líder: ${m.liderNome ?? 'não definido'}',
                    cor: m.liderNome == null ? Cores.alerta : Cores.info,
                  ),
                ]),
              ],
            ),
            trailing: Row(mainAxisSize: MainAxisSize.min, children: [
              IconButton(
                tooltip: 'Editar',
                icon: const Icon(Icons.edit_outlined),
                onPressed: () => _abrirForm(m),
              ),
              IconButton(
                tooltip: m.ativo ? 'Inativar' : 'Reativar',
                icon: Icon(m.ativo
                    ? Icons.toggle_on_outlined
                    : Icons.toggle_off_outlined),
                onPressed: () => _executar(
                  context,
                  () => ref
                      .read(conteudoRepositoryProvider)!
                      .definirMinisterioAtivo(m.id, !m.ativo),
                  // Inativar, nunca excluir: escalas e histórico dependem do
                  // documento do ministério.
                  sucesso: m.ativo
                      ? 'Ministério inativado (histórico preservado).'
                      : 'Ministério reativado.',
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  Future<void> _abrirForm(Ministerio? ministerio) async {
    final repo = ref.read(conteudoRepositoryProvider);
    if (repo == null) return;

    final nome = TextEditingController(text: ministerio?.nome ?? '');
    final descricao = TextEditingController(text: ministerio?.descricao ?? '');
    MembroPainel? lider;

    final salvar = await showDialog<bool>(
      context: context,
      builder: (d) => StatefulBuilder(
        builder: (d, setState) => AlertDialog(
          title:
              Text(ministerio == null ? 'Novo ministério' : 'Editar ministério'),
          content: SizedBox(
            width: 520,
            child: SingleChildScrollView(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                TextField(
                  controller: nome,
                  autofocus: true,
                  decoration: const InputDecoration(labelText: 'Nome'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descricao,
                  minLines: 2,
                  maxLines: 5,
                  decoration: const InputDecoration(labelText: 'Descrição'),
                ),
                _SeletorResponsavel(
                  atualNome: lider?.exibicao ?? ministerio?.liderNome,
                  onSelecionado: (m) => setState(() => lider = m),
                ),
              ]),
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(d).pop(false),
                child: const Text('Cancelar')),
            FilledButton(
                onPressed: () => Navigator.of(d).pop(true),
                child: const Text('Salvar')),
          ],
        ),
      ),
    );

    if (!mounted) return;

    _limparQuery(context, '/ministerios');
    _abriu = false;

    if (salvar != true || nome.text.trim().isEmpty) return;
    if (!mounted) return;

    await _executar(
      context,
      () => repo.salvarMinisterio(Ministerio(
        id: ministerio?.id ?? '',
        nome: nome.text.trim(),
        descricao: descricao.text.trim(),
        ativo: ministerio?.ativo ?? true,
        liderId: lider?.vinculo.uid ?? ministerio?.liderId,
        liderNome: lider?.exibicao ?? ministerio?.liderNome,
      )),
      sucesso:
          ministerio == null ? 'Ministério criado.' : 'Ministério atualizado.',
    );
  }
}

// ══════════════════════════════════════════════════════════════════════
// DEVOCIONAIS
// ══════════════════════════════════════════════════════════════════════

class DevocionaisTela extends ConsumerStatefulWidget {
  const DevocionaisTela({super.key});

  @override
  ConsumerState<DevocionaisTela> createState() => _DevocionaisTelaState();
}

class _DevocionaisTelaState extends ConsumerState<DevocionaisTela> {
  bool _abriu = false;

  @override
  Widget build(BuildContext context) {
    if (_pediuNovo(context) && !_abriu) {
      _abriu = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _abrirForm(null));
    }

    return _PaginaConteudo(
      titulo: 'Devocionais',
      descricao: 'Reflexões publicadas no aplicativo desta igreja.',
      rotuloNovo: 'Novo devocional',
      onNovo: () => _abrirForm(null),
      corpo: _Lista<Devocional>(
        async: ref.watch(devocionaisProvider),
        onRecarregar: () => ref.invalidate(devocionaisProvider),
        vazio: const EstadoVazio(
          titulo: 'Nenhum devocional publicado',
          icone: Icons.menu_book_outlined,
        ),
        item: (context, dv) => Card(
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            title:
                Text(dv.titulo, style: Theme.of(context).textTheme.titleMedium),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 6),
                Text(dv.corpo, maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 8),
                Wrap(spacing: 8, runSpacing: 4, children: [
                  Etiqueta(
                    texto: dv.ativo ? 'Ativo' : 'Inativo',
                    cor: dv.ativo ? Cores.sucesso : Cores.muted,
                  ),
                  if (dv.destaque)
                    const Etiqueta(texto: 'Destaque', cor: Cores.info),
                  Etiqueta(
                      texto: _dataCurta.format(dv.data), cor: Cores.muted),
                  if (dv.autor.isNotEmpty)
                    Etiqueta(texto: dv.autor, cor: Cores.corpo),
                ]),
              ],
            ),
            trailing: Row(mainAxisSize: MainAxisSize.min, children: [
              IconButton(
                tooltip: 'Editar',
                icon: const Icon(Icons.edit_outlined),
                onPressed: () => _abrirForm(dv),
              ),
              IconButton(
                tooltip: dv.ativo ? 'Inativar' : 'Reativar',
                icon: Icon(dv.ativo
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined),
                onPressed: () => _executar(
                  context,
                  () => ref
                      .read(conteudoRepositoryProvider)!
                      .definirDevocionalAtivo(dv.id, !dv.ativo),
                  sucesso: dv.ativo
                      ? 'Devocional inativado (histórico preservado).'
                      : 'Devocional reativado.',
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  Future<void> _abrirForm(Devocional? devocional) async {
    final repo = ref.read(conteudoRepositoryProvider);
    if (repo == null) return;

    final titulo = TextEditingController(text: devocional?.titulo ?? '');
    final corpo = TextEditingController(text: devocional?.corpo ?? '');
    final autor = TextEditingController(text: devocional?.autor ?? '');
    final referencia =
        TextEditingController(text: devocional?.referencia ?? '');
    var data = devocional?.data ?? DateTime.now();
    var destaque = devocional?.destaque ?? false;

    final salvar = await showDialog<bool>(
      context: context,
      builder: (d) => StatefulBuilder(
        builder: (d, setState) => AlertDialog(
          title: Text(
              devocional == null ? 'Novo devocional' : 'Editar devocional'),
          content: SizedBox(
            width: 520,
            child: SingleChildScrollView(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                TextField(
                  controller: titulo,
                  autofocus: true,
                  decoration: const InputDecoration(labelText: 'Título'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: corpo,
                  minLines: 4,
                  maxLines: 10,
                  decoration: const InputDecoration(labelText: 'Texto'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: autor,
                  decoration: const InputDecoration(labelText: 'Autor'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: referencia,
                  decoration: const InputDecoration(
                      labelText: 'Referência bíblica (opcional)'),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Data'),
                  subtitle: Text(_dataCurta.format(data)),
                  trailing: const Icon(Icons.calendar_today, size: 18),
                  onTap: () async {
                    final dia = await showDatePicker(
                      context: d,
                      initialDate: data,
                      firstDate: DateTime(DateTime.now().year - 2),
                      lastDate: DateTime(DateTime.now().year + 2),
                    );
                    if (dia != null) setState(() => data = dia);
                  },
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: destaque,
                  onChanged: (v) => setState(() => destaque = v),
                  title: const Text('Marcar como destaque'),
                ),
              ]),
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(d).pop(false),
                child: const Text('Cancelar')),
            FilledButton(
                onPressed: () => Navigator.of(d).pop(true),
                child: const Text('Salvar')),
          ],
        ),
      ),
    );

    if (!mounted) return;

    _limparQuery(context, '/devocionais');
    _abriu = false;

    if (salvar != true || titulo.text.trim().isEmpty) return;
    if (!mounted) return;

    await _executar(
      context,
      () => repo.salvarDevocional(Devocional(
        id: devocional?.id ?? '',
        titulo: titulo.text.trim(),
        corpo: corpo.text.trim(),
        autor: autor.text.trim(),
        data: data,
        referencia: referencia.text.trim().isEmpty
            ? null
            : referencia.text.trim(),
        destaque: destaque,
        ativo: devocional?.ativo ?? true,
      )),
      sucesso: devocional == null
          ? 'Devocional criado.'
          : 'Devocional atualizado.',
    );
  }
}

// ══════════════════════════════════════════════════════════════════════
// ORAÇÃO
// ══════════════════════════════════════════════════════════════════════

class OracaoTela extends ConsumerWidget {
  const OracaoTela({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final acesso = ref.watch(acessoAtualProvider);
    if (acesso == null) return const CarregandoCentralizado();

    if (!acesso.moderarOracao) {
      return const EstadoVazio(
        titulo: 'Sem permissão para moderar orações',
        detalhe:
            'A moderação fica disponível para a liderança e para quem tem a '
            'função de moderador de oração nesta igreja.',
        icone: Icons.lock_outline,
      );
    }

    return DefaultTabController(
      length: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Oração',
                    style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 4),
                Text(
                  'Recusar não apaga o pedido: ele sai do mural, mas continua '
                  'registrado com o motivo e o autor da decisão.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            labelColor: Cores.primary,
            indicatorColor: Cores.primary,
            tabs: [
              Tab(text: 'Aguardando moderação'),
              Tab(text: 'No mural'),
            ],
          ),
          const Divider(height: 1),
          Expanded(
            child: TabBarView(
              children: [
                _ListaOracao(
                  async: ref.watch(oracoesPendentesProvider),
                  vazio: const EstadoVazio(
                    titulo: 'Nenhum pedido aguardando',
                    detalhe: 'A fila de moderação está vazia.',
                    icone: Icons.inbox_outlined,
                  ),
                  moderavel: true,
                ),
                _ListaOracao(
                  async: ref.watch(oracoesAprovadasProvider),
                  vazio: const EstadoVazio(
                    titulo: 'Nenhum pedido no mural',
                    icone: Icons.favorite_outline,
                  ),
                  moderavel: false,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ListaOracao extends ConsumerWidget {
  const _ListaOracao({
    required this.async,
    required this.vazio,
    required this.moderavel,
  });

  final AsyncValue<List<PedidoOracao>> async;
  final Widget vazio;
  final bool moderavel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uid = ref.watch(authStateProvider).valueOrNull?.uid ?? '';

    return async.when(
      loading: () => const CarregandoCentralizado(),
      error: (e, _) => EstadoErro(erro: e),
      data: (lista) {
        if (lista.isEmpty) return vazio;
        return ListView.separated(
          padding: const EdgeInsets.all(20),
          itemCount: lista.length,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (context, i) {
            final p = lista[i];
            return Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(spacing: 8, runSpacing: 4, children: [
                      Etiqueta(texto: p.nomeExibicao, cor: Cores.corpo),
                      if (p.anonimo)
                        const Etiqueta(texto: 'Anônimo', cor: Cores.info),
                      if (p.urgente)
                        const Etiqueta(texto: 'Urgente', cor: Cores.erro),
                      if (p.criadoEm != null)
                        Etiqueta(
                            texto: _dataHora.format(p.criadoEm!),
                            cor: Cores.muted),
                    ]),
                    const SizedBox(height: 10),
                    Text(p.texto),
                    if (moderavel) ...[
                      const SizedBox(height: 14),
                      Row(children: [
                        OutlinedButton(
                          onPressed: () async {
                            final motivo = await _pedirMotivo(context);
                            if (motivo == null || !context.mounted) return;
                            await _executar(
                              context,
                              () => ref
                                  .read(conteudoRepositoryProvider)!
                                  .recusarOracao(p.id, uid, motivo),
                              sucesso:
                                  'Pedido recusado. O registro foi preservado.',
                            );
                          },
                          style: OutlinedButton.styleFrom(
                              foregroundColor: Cores.erro),
                          child: const Text('Recusar'),
                        ),
                        const SizedBox(width: 10),
                        FilledButton(
                          onPressed: () => _executar(
                            context,
                            () => ref
                                .read(conteudoRepositoryProvider)!
                                .aprovarOracao(p.id, uid),
                            sucesso: 'Pedido publicado no mural.',
                          ),
                          child: const Text('Aprovar'),
                        ),
                      ]),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<String?> _pedirMotivo(BuildContext context) => DialogoMotivo.mostrar(
        context,
        titulo: 'Recusar pedido',
        descricao:
            'O pedido sai da fila e do mural, mas continua registrado com o '
            'motivo e o autor da decisão.',
        rotuloConfirmar: 'Recusar',
      );
}
