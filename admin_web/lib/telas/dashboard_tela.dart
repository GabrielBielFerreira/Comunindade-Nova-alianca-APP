import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nova_alianca_core/nova_alianca_core.dart';

import '../estado/providers.dart';
import '../ui/componentes.dart';

/// Visão geral da unidade em foco. Todo número vem de contagem real; onde não
/// há dado, aparece estado vazio — nada é preenchido para "parecer pronto".
class DashboardTela extends ConsumerWidget {
  const DashboardTela({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final acesso = ref.watch(acessoAtualProvider);
    if (acesso == null) return const CarregandoCentralizado();

    final resumoAsync = ref.watch(resumoDashboardProvider);

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(acesso.nome,
                      style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 4),
                  Text(
                    'Seu perfil nesta unidade: ${acesso.perfil.rotulo}'
                    '${acesso.funcoesAdmin.isEmpty ? '' : ' · ${acesso.funcoesAdmin.map((f) => f.rotulo).join(', ')}'}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                  ),
                ],
              ),
            ),
            if (!acesso.ativa)
              const Etiqueta(texto: 'UNIDADE INATIVA', cor: Colors.orange),
          ],
        ),
        const SizedBox(height: 24),

        resumoAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 48),
            child: CarregandoCentralizado(),
          ),
          error: (erro, _) => EstadoErro(
            erro: erro,
            onTentarNovamente: () => ref.invalidate(membrosProvider),
          ),
          data: (resumo) => Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              SizedBox(
                width: 240,
                child: CartaoMetrica(
                  rotulo: 'Cadastros pendentes',
                  valor: '${resumo.pendentes}',
                  detalhe: resumo.pendentes == 0
                      ? 'Nada aguardando aprovação'
                      : 'Aguardando aprovação',
                  icone: Icons.hourglass_empty,
                  destaque: resumo.pendentes > 0,
                ),
              ),
              SizedBox(
                width: 240,
                child: CartaoMetrica(
                  rotulo: 'Membros aprovados',
                  valor: '${resumo.aprovados}',
                  icone: Icons.people_outline,
                ),
              ),
              SizedBox(
                width: 240,
                child: CartaoMetrica(
                  rotulo: 'Liderança',
                  valor: '${resumo.lideranca}',
                  detalhe: 'Pastor, diácono, evangelista e líder',
                  icone: Icons.workspace_premium_outlined,
                ),
              ),
              SizedBox(
                width: 240,
                child: CartaoMetrica(
                  rotulo: 'Vínculos inativos',
                  valor: '${resumo.inativos}',
                  detalhe: 'Histórico preservado',
                  icone: Icons.person_off_outlined,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 32),
        Text('Finanças', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        if (!acesso.lerFinancas)
          Card(
            child: ListTile(
              leading: const Icon(Icons.lock_outline),
              title: const Text('Sem acesso financeiro'),
              subtitle: Text(
                'Seu perfil (${acesso.perfil.rotulo}) não inclui leitura das '
                'finanças desta unidade.',
              ),
            ),
          )
        else
          const _ResumoFinanceiro(),
      ],
    );
  }
}

class _ResumoFinanceiro extends ConsumerWidget {
  const _ResumoFinanceiro();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transacoesAsync = ref.watch(transacoesProvider);

    return transacoesAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 32),
        child: CarregandoCentralizado(),
      ),
      error: (erro, _) => EstadoErro(erro: erro),
      data: (transacoes) {
        if (transacoes.isEmpty) {
          return const Card(
            child: EstadoVazio(
              titulo: 'Nenhuma transação registrada',
              detalhe: 'Esta unidade ainda não possui contribuições lançadas.',
              icone: Icons.receipt_long_outlined,
            ),
          );
        }

        final totais = TotaisFinanceiros.de(transacoes);
        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            SizedBox(
              width: 240,
              child: CartaoMetrica(
                rotulo: 'Recebido (aprovado)',
                valor: formatarCentavos(totais.aprovadoCentavos),
                icone: Icons.check_circle_outline,
                destaque: true,
              ),
            ),
            SizedBox(
              width: 240,
              child: CartaoMetrica(
                rotulo: 'Pendente',
                valor: formatarCentavos(totais.pendenteCentavos),
                icone: Icons.schedule,
              ),
            ),
            SizedBox(
              width: 240,
              child: CartaoMetrica(
                rotulo: 'Transações',
                valor: '${totais.quantidade}',
                icone: Icons.receipt_long_outlined,
              ),
            ),
          ],
        );
      },
    );
  }
}
