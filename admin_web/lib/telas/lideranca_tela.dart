import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nova_alianca_core/nova_alianca_core.dart';

import '../dados/membros_repository.dart';
import '../estado/providers.dart';
import '../ui/componentes.dart';
import 'membros_tela.dart' show corDoStatus;

/// Gestão do ciclo de vida da liderança.
///
/// Visível apenas a pastor da unidade e super_admin — e o backend valida de
/// novo, então esconder o menu é conveniência, não a segurança.
class LiderancaTela extends ConsumerWidget {
  const LiderancaTela({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final acesso = ref.watch(acessoAtualProvider);
    if (acesso == null) return const CarregandoCentralizado();

    if (!acesso.gerenciarLideranca) {
      return const EstadoVazio(
        titulo: 'Sem permissão para gerir a liderança',
        detalhe:
            'Somente o pastor da unidade ou o superadministrador pode promover, '
            'rebaixar ou desvincular integrantes da liderança.',
        icone: Icons.lock_outline,
      );
    }

    final membrosAsync = ref.watch(membrosProvider);
    final uidAtual = ref.watch(meusAcessosProvider).valueOrNull?.uid;
    final isSuperAdmin =
        ref.watch(meusAcessosProvider).valueOrNull?.isSuperAdmin ?? false;

    return membrosAsync.when(
      loading: () => const CarregandoCentralizado(),
      error: (erro, _) => EstadoErro(
        erro: erro,
        onTentarNovamente: () => ref.invalidate(membrosProvider),
      ),
      data: (todos) {
        final aprovados =
            todos.where((m) => m.vinculo.status == StatusVinculo.aprovado).toList();
        final lideranca =
            aprovados.where((m) => m.vinculo.perfil.isLiderancaMinisterial).toList();
        final membros =
            aprovados.where((m) => !m.vinculo.perfil.isLiderancaMinisterial).toList();

        return ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text('Liderança — ${acesso.nome}',
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 4),
            Text(
              'Toda alteração exige motivo e fica registrada na auditoria. '
              'Nenhuma operação apaga histórico.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
            ),
            const SizedBox(height: 24),

            Text('Liderança atual',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            if (lideranca.isEmpty)
              const Card(
                child: EstadoVazio(
                  titulo: 'Nenhum integrante na liderança',
                  icone: Icons.workspace_premium_outlined,
                ),
              )
            else
              for (final m in lideranca)
                _CartaoLideranca(
                  membro: m,
                  uidAtual: uidAtual,
                  isSuperAdmin: isSuperAdmin,
                ),

            const SizedBox(height: 32),
            Text('Membros aprovados',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(
              'Promova alguém para a liderança ministerial.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            if (membros.isEmpty)
              const Card(
                child: EstadoVazio(
                  titulo: 'Nenhum membro aprovado disponível',
                  icone: Icons.people_outline,
                ),
              )
            else
              for (final m in membros)
                _CartaoLideranca(
                  membro: m,
                  uidAtual: uidAtual,
                  isSuperAdmin: isSuperAdmin,
                ),
          ],
        );
      },
    );
  }
}

class _CartaoLideranca extends ConsumerStatefulWidget {
  const _CartaoLideranca({
    required this.membro,
    required this.uidAtual,
    required this.isSuperAdmin,
  });

  final MembroPainel membro;
  final String? uidAtual;
  final bool isSuperAdmin;

  @override
  ConsumerState<_CartaoLideranca> createState() => _CartaoLiderancaState();
}

class _CartaoLiderancaState extends ConsumerState<_CartaoLideranca> {
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
            content: Text('Operação negada: $erro'),
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

    final ehEuMesmo = vinculo.uid == widget.uidAtual;
    final ehPastor = vinculo.perfil.isPastor;

    // Espelha assertPodeAlterarVinculo no servidor.
    final bloqueado = !widget.isSuperAdmin && (ehEuMesmo || ehPastor);
    final motivoBloqueio = ehEuMesmo
        ? 'Um pastor não pode alterar o próprio vínculo.'
        : 'Alterar o vínculo de um pastor exige o superadministrador.';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.membro.exibicao,
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          Etiqueta(
                              texto: vinculo.perfil.rotulo, cor: Colors.blueGrey),
                          Etiqueta(
                            texto: vinculo.status.rotulo,
                            cor: corDoStatus(vinculo.status),
                          ),
                          for (final f in vinculo.funcoesAdmin)
                            Etiqueta(texto: f.rotulo, cor: Colors.indigo),
                        ],
                      ),
                    ],
                  ),
                ),
                if (_ocupado)
                  const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
            if (bloqueado) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.lock_outline, size: 16),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      motivoBloqueio,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ] else ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (!vinculo.perfil.isLiderancaMinisterial)
                    for (final perfil in [
                      PerfilComunitario.lider,
                      PerfilComunitario.diacono,
                      PerfilComunitario.evangelista,
                    ])
                      OutlinedButton(
                        onPressed: _ocupado
                            ? null
                            : () => _executar(
                                  () => repo.promover(
                                    igrejaId: vinculo.igrejaId,
                                    uid: vinculo.uid,
                                    perfil: perfil,
                                  ),
                                  'Promovido a ${perfil.rotulo}.',
                                ),
                        child: Text('Promover a ${perfil.rotulo}'),
                      ),
                  if (vinculo.perfil.isLiderancaMinisterial)
                    OutlinedButton.icon(
                      icon: const Icon(Icons.arrow_downward, size: 16),
                      onPressed: _ocupado
                          ? null
                          : () async {
                              final motivo = await DialogoMotivo.mostrar(
                                context,
                                titulo: 'Remover da liderança',
                                descricao:
                                    '${widget.membro.exibicao} passa a ser membro. '
                                    'O vínculo continua aprovado e o histórico '
                                    'é preservado.',
                                rotuloConfirmar: 'Rebaixar',
                              );
                              if (motivo == null) return;
                              await _executar(
                                () => repo.removerDaLideranca(
                                  igrejaId: vinculo.igrejaId,
                                  uid: vinculo.uid,
                                  motivo: motivo,
                                ),
                                'Removido da liderança.',
                              );
                            },
                      label: const Text('Remover da liderança'),
                    ),
                  // Funções administrativas: tesoureiro, editor e moderador.
                  // A função `pastor` não entra aqui — ela acompanha o perfil.
                  for (final funcao in const [
                    FuncaoAdmin.tesoureiro,
                    FuncaoAdmin.editor,
                    FuncaoAdmin.moderadorOracao,
                  ])
                    if (!vinculo.funcoesAdmin.contains(funcao))
                      OutlinedButton.icon(
                        icon: const Icon(Icons.add_moderator_outlined, size: 16),
                        onPressed: _ocupado
                            ? null
                            : () => _executar(
                                  () => repo.atribuirFuncao(
                                    igrejaId: vinculo.igrejaId,
                                    uid: vinculo.uid,
                                    funcao: funcao,
                                  ),
                                  '${funcao.rotulo} atribuído.',
                                ),
                        label: Text('Dar ${funcao.rotulo}'),
                      )
                    else
                      OutlinedButton.icon(
                        icon: const Icon(Icons.remove_moderator_outlined,
                            size: 16),
                        onPressed: _ocupado
                            ? null
                            : () async {
                                final motivo = await DialogoMotivo.mostrar(
                                  context,
                                  titulo: 'Remover ${funcao.rotulo}',
                                  descricao:
                                      '${widget.membro.exibicao} perde a função '
                                      '${funcao.rotulo} nesta igreja. O vínculo '
                                      'e o histórico permanecem.',
                                  rotuloConfirmar: 'Remover função',
                                );
                                if (motivo == null) return;
                                await _executar(
                                  () => repo.removerFuncao(
                                    igrejaId: vinculo.igrejaId,
                                    uid: vinculo.uid,
                                    funcao: funcao,
                                    motivo: motivo,
                                  ),
                                  '${funcao.rotulo} removido.',
                                );
                              },
                        label: Text('Tirar ${funcao.rotulo}'),
                      ),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.person_off_outlined, size: 16),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Theme.of(context).colorScheme.error,
                    ),
                    onPressed: _ocupado
                        ? null
                        : () async {
                            final motivo = await DialogoMotivo.mostrar(
                              context,
                              titulo: 'Desvincular da igreja',
                              descricao:
                                  'O vínculo de ${widget.membro.exibicao} fica '
                                  'inativo e todas as funções são revogadas. '
                                  'Nenhum documento é apagado.',
                              rotuloConfirmar: 'Desvincular',
                            );
                            if (motivo == null) return;
                            await _executar(
                              () => repo.desvincular(
                                igrejaId: vinculo.igrejaId,
                                uid: vinculo.uid,
                                motivo: motivo,
                              ),
                              'Vínculo inativado.',
                            );
                          },
                    label: const Text('Desvincular'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
