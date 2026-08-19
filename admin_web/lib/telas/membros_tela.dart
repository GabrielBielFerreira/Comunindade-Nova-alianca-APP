import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nova_alianca_core/nova_alianca_core.dart';

import '../dados/membros_repository.dart';
import '../estado/providers.dart';
import '../ui/componentes.dart';

final _filtroStatusProvider = StateProvider<StatusVinculo?>((ref) => null);

Color corDoStatus(StatusVinculo status) => switch (status) {
      StatusVinculo.pendente => Colors.orange,
      StatusVinculo.aprovado => Colors.green,
      StatusVinculo.inativo => Colors.grey,
    };

class MembrosTela extends ConsumerWidget {
  const MembrosTela({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final acesso = ref.watch(acessoAtualProvider);
    if (acesso == null) return const CarregandoCentralizado();

    final membrosAsync = ref.watch(membrosProvider);
    final filtro = ref.watch(_filtroStatusProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Membros — ${acesso.nome}',
                  style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: [
                  FilterChip(
                    label: const Text('Todos'),
                    selected: filtro == null,
                    onSelected: (_) =>
                        ref.read(_filtroStatusProvider.notifier).state = null,
                  ),
                  for (final status in StatusVinculo.values)
                    FilterChip(
                      label: Text(status.rotulo),
                      selected: filtro == status,
                      onSelected: (_) =>
                          ref.read(_filtroStatusProvider.notifier).state = status,
                    ),
                ],
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: membrosAsync.when(
            loading: () => const CarregandoCentralizado(),
            error: (erro, _) => EstadoErro(
              erro: erro,
              onTentarNovamente: () => ref.invalidate(membrosProvider),
            ),
            data: (pagina) {
              final todos = pagina.itens;
              final lista = filtro == null
                  ? todos
                  : todos.where((m) => m.vinculo.status == filtro).toList();

              if (lista.isEmpty) {
                return EstadoVazio(
                  titulo: filtro == null
                      ? 'Nenhum membro nesta unidade'
                      : 'Nenhum membro com status "${filtro.rotulo}"',
                  detalhe: filtro == null
                      ? 'Os cadastros feitos no aplicativo aparecem aqui.'
                      : null,
                  icone: Icons.people_outline,
                );
              }

              return ListView.separated(
                padding: EdgeInsets.all(espacoDaLargura(context)),
                itemCount: lista.length + (pagina.truncada ? 1 : 0),
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, i) => i >= lista.length
                    ? AvisoListaTruncada(exibidos: lista.length)
                    : _LinhaMembro(
                        membro: lista[i],
                        podeAprovar: acesso.aprovarMembro,
                      ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _LinhaMembro extends ConsumerStatefulWidget {
  const _LinhaMembro({required this.membro, required this.podeAprovar});

  final MembroPainel membro;
  final bool podeAprovar;

  @override
  ConsumerState<_LinhaMembro> createState() => _LinhaMembroState();
}

class _LinhaMembroState extends ConsumerState<_LinhaMembro> {
  bool _ocupado = false;

  Future<void> _executar(Future<void> Function() acao, String sucesso) async {
    setState(() => _ocupado = true);
    try {
      await acao();
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(sucesso)));
      }
    } catch (erro) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Falhou: $erro'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _ocupado = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final vinculo = widget.membro.vinculo;
    final repo = ref.read(membrosRepositoryProvider);

    final acoes = <Widget>[
      if (vinculo.status == StatusVinculo.pendente)
        FilledButton(
          onPressed: () => _executar(
            () => repo.aprovar(igrejaId: vinculo.igrejaId, uid: vinculo.uid),
            'Cadastro aprovado.',
          ),
          child: const Text('Aprovar'),
        ),
      if (vinculo.status != StatusVinculo.inativo)
        OutlinedButton(
          onPressed: () async {
            final motivo = await DialogoMotivo.mostrar(
              context,
              titulo: vinculo.status == StatusVinculo.pendente
                  ? 'Recusar cadastro'
                  : 'Inativar vínculo',
              descricao:
                  'O vínculo de ${widget.membro.exibicao} será marcado como '
                  'inativo. O histórico é preservado.',
              rotuloConfirmar: 'Confirmar',
            );
            if (motivo == null) return;
            await _executar(
              () => repo.recusar(
                igrejaId: vinculo.igrejaId,
                uid: vinculo.uid,
                motivo: motivo,
              ),
              'Vínculo inativado.',
            );
          },
          child: Text(vinculo.status == StatusVinculo.pendente
              ? 'Recusar'
              : 'Inativar'),
        ),
    ];

    final identificacao = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          widget.membro.exibicao,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Etiqueta(
              texto: vinculo.status.rotulo,
              cor: corDoStatus(vinculo.status),
            ),
            Etiqueta(texto: vinculo.perfil.rotulo, cor: Colors.blueGrey),
            for (final funcao in vinculo.funcoesAdmin)
              Etiqueta(texto: funcao.rotulo, cor: Colors.indigo),
          ],
        ),
      ],
    );

    final Widget controles = _ocupado
        ? const Padding(
            padding: EdgeInsets.all(4),
            child: SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          )
        : Wrap(spacing: 8, runSpacing: 8, children: acoes);

    final mostrarAcoes = widget.podeAprovar && (acoes.isNotEmpty || _ocupado);

    // Sem ListTile: dois botões no `trailing` não cabem em 320 px e o próprio
    // ListTile aborta o layout. Aqui as ações descem para baixo do nome
    // quando o espaço aperta.
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final estreito = constraints.maxWidth < 420;

            if (!mostrarAcoes) return identificacao;

            if (estreito) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  identificacao,
                  const SizedBox(height: 12),
                  controles,
                ],
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: identificacao),
                const SizedBox(width: 12),
                controles,
              ],
            );
          },
        ),
      ),
    );
  }
}
