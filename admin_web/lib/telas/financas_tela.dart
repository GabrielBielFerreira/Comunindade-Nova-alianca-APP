import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:nova_alianca_core/nova_alianca_core.dart';

import '../dados/financas_repository.dart';
import '../estado/providers.dart';
import '../ui/componentes.dart';

/// Painel financeiro SOMENTE LEITURA.
///
/// Não existe botão de aprovar, editar valor ou alterar status: o backend e o
/// webhook são a fonte da verdade, e as Rules negam qualquer escrita de
/// cliente em `transacoes`.
class FinancasTela extends ConsumerWidget {
  const FinancasTela({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final acesso = ref.watch(acessoAtualProvider);
    if (acesso == null) return const CarregandoCentralizado();

    if (!acesso.lerFinancas) {
      return const EstadoVazio(
        titulo: 'Sem acesso financeiro',
        detalhe:
            'As finanças ficam disponíveis para pastor, diácono, evangelista, '
            'líder e tesoureiro da própria unidade.',
        icone: Icons.lock_outline,
      );
    }

    final transacoesAsync = ref.watch(transacoesProvider);
    final filtro = ref.watch(filtroFinancasProvider);
    final filtradas = ref.watch(transacoesFiltradasProvider);

    final espaco = espacoDaLargura(context);

    // Página única e rolável: em 320 px os filtros ocupam várias linhas e um
    // cabeçalho de altura livre dentro de Column estourava a tela.
    return ListView(
      padding: EdgeInsets.fromLTRB(espaco, espaco, espaco, espaco),
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text('Finanças — ${acesso.nome}',
                style: Theme.of(context).textTheme.headlineSmall),
            const Etiqueta(texto: 'SOMENTE LEITURA', cor: Colors.teal),
          ],
        ),
        const SizedBox(height: 12),
        _Filtros(filtro: filtro),
        const SizedBox(height: 16),
        const Divider(height: 1),
        const SizedBox(height: 16),
        transacoesAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 48),
            child: CarregandoCentralizado(),
          ),
          error: (erro, _) => EstadoErro(
            erro: erro,
            onTentarNovamente: () => ref.invalidate(transacoesProvider),
          ),
          data: (pagina) {
            if (pagina.isEmpty) {
              return const EstadoVazio(
                titulo: 'Nenhuma transação registrada',
                detalhe: 'Esta unidade ainda não possui contribuições lançadas.',
                icone: Icons.receipt_long_outlined,
              );
            }
            if (filtradas.isEmpty) {
              return const EstadoVazio(
                titulo: 'Nenhuma transação para os filtros aplicados',
                detalhe: 'Ajuste o período, o status ou o tipo.',
                icone: Icons.filter_alt_off_outlined,
              );
            }

            // Totais das transações CARREGADAS e filtradas. O total geral da
            // unidade aparece no dashboard, somado no servidor.
            final totais = TotaisFinanceiros.de(filtradas);
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                GradeCartoes(
                  children: [
                    CartaoMetrica(
                      rotulo: 'Aprovado',
                      valor: formatarCentavos(totais.aprovadoCentavos),
                      icone: Icons.check_circle_outline,
                      destaque: true,
                    ),
                    CartaoMetrica(
                      rotulo: 'Pendente',
                      valor: formatarCentavos(totais.pendenteCentavos),
                      icone: Icons.schedule,
                    ),
                    CartaoMetrica(
                      rotulo: 'Recusado/estornado',
                      valor: formatarCentavos(totais.recusadoCentavos),
                      icone: Icons.cancel_outlined,
                    ),
                    CartaoMetrica(
                      rotulo: 'Transações',
                      valor: '${totais.quantidade}',
                      icone: Icons.receipt_long_outlined,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Card(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text('Data')),
                        DataColumn(label: Text('Tipo')),
                        DataColumn(label: Text('Método')),
                        DataColumn(label: Text('Status')),
                        DataColumn(label: Text('Valor'), numeric: true),
                        DataColumn(label: Text('ID Mercado Pago')),
                      ],
                      rows: [
                        for (final t in filtradas)
                          DataRow(cells: [
                            DataCell(Text(t.criadoEm == null
                                ? '—'
                                : DateFormat('dd/MM/yyyy HH:mm')
                                    .format(t.criadoEm!))),
                            DataCell(Text(t.tipo.rotulo)),
                            DataCell(Text(t.metodo.rotulo)),
                            DataCell(Etiqueta(
                              texto: t.status.rotulo,
                              cor: _corStatus(t.status),
                            )),
                            // Sempre derivado de valor_centavos.
                            DataCell(Text(formatarCentavos(t.valorCentavos))),
                            DataCell(Text(t.mpPaymentId ?? '—')),
                          ]),
                      ],
                    ),
                  ),
                ),
                if (pagina.truncada) ...[
                  const SizedBox(height: 16),
                  AvisoListaTruncada(exibidos: pagina.length),
                ],
              ],
            );
          },
        ),
      ],
    );
  }
}

Color _corStatus(StatusTransacao status) => switch (status) {
      StatusTransacao.aprovado => Colors.green,
      StatusTransacao.pendente || StatusTransacao.criando => Colors.orange,
      StatusTransacao.rejeitado => Colors.red,
      StatusTransacao.cancelado => Colors.grey,
      StatusTransacao.estornado => Colors.purple,
    };

class _Filtros extends ConsumerWidget {
  const _Filtros({required this.filtro});

  final FiltroFinancas filtro;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(filtroFinancasProvider.notifier);

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        DropdownMenu<StatusTransacao?>(
          initialSelection: filtro.status,
          label: const Text('Status'),
          width: 200,
          dropdownMenuEntries: [
            const DropdownMenuEntry(value: null, label: 'Todos'),
            for (final s in StatusTransacao.values)
              DropdownMenuEntry(value: s, label: s.rotulo),
          ],
          onSelected: (valor) => notifier.state = valor == null
              ? filtro.copiarCom(limparStatus: true)
              : filtro.copiarCom(status: valor),
        ),
        DropdownMenu<TipoContribuicao?>(
          initialSelection: filtro.tipo,
          label: const Text('Tipo'),
          width: 200,
          dropdownMenuEntries: [
            const DropdownMenuEntry(value: null, label: 'Todos'),
            for (final t in TipoContribuicao.values)
              DropdownMenuEntry(value: t, label: t.rotulo),
          ],
          onSelected: (valor) => notifier.state = valor == null
              ? filtro.copiarCom(limparTipo: true)
              : filtro.copiarCom(tipo: valor),
        ),
        OutlinedButton.icon(
          icon: const Icon(Icons.date_range, size: 18),
          label: Text(
            filtro.inicio == null && filtro.fim == null
                ? 'Período: todos'
                : '${filtro.inicio == null ? '…' : DateFormat('dd/MM/yy').format(filtro.inicio!)}'
                    ' — '
                    '${filtro.fim == null ? '…' : DateFormat('dd/MM/yy').format(filtro.fim!)}',
          ),
          onPressed: () async {
            final agora = DateTime.now();
            final intervalo = await showDateRangePicker(
              context: context,
              firstDate: DateTime(agora.year - 5),
              lastDate: DateTime(agora.year + 1),
            );
            if (intervalo == null) return;
            notifier.state = filtro.copiarCom(
              inicio: intervalo.start,
              // Inclui o dia final inteiro.
              fim: DateTime(
                intervalo.end.year,
                intervalo.end.month,
                intervalo.end.day,
                23,
                59,
                59,
              ),
            );
          },
        ),
        if (!filtro.vazio)
          TextButton.icon(
            icon: const Icon(Icons.clear, size: 18),
            label: const Text('Limpar filtros'),
            onPressed: () => notifier.state = const FiltroFinancas(),
          ),
      ],
    );
  }
}
