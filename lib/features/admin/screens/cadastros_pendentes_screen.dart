import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:nova_alianca_core/nova_alianca_core.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../igrejas/providers/igreja_providers.dart';
import '../data/membros_repository.dart';
import '../providers/aprovacoes_providers.dart';

/// Cadastros pendentes DA UNIDADE EM FOCO.
///
/// A aprovação é feita por Cloud Function: o cliente não tem permissão de
/// escrever `status` de vínculo nem de gravar auditoria.
class CadastrosPendentesScreen extends ConsumerWidget {
  const CadastrosPendentesScreen({super.key});

  void _mostrar(BuildContext context, String msg) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  /// Confere a autorização na unidade em foco. O servidor revalida.
  IgrejaId? _igrejaAutorizadaOuAviso(BuildContext context, WidgetRef ref) {
    final autorizacao = ref.read(autorizacaoAtualProvider);
    if (autorizacao == null || !autorizacao.podeAprovarMembro) {
      _mostrar(context, 'Ação restrita à liderança desta igreja.');
      return null;
    }
    return autorizacao.igrejaId;
  }

  Future<void> _aprovar(
      BuildContext context, WidgetRef ref, MembroUnidade alvo) async {
    final igrejaId = _igrejaAutorizadaOuAviso(context, ref);
    if (igrejaId == null) return;

    final ok = await showDialog<bool>(
      context: context,
      builder: (d) => AlertDialog(
        title: const Text('Aprovar cadastro'),
        content: Text('Liberar o acesso de ${alvo.exibicao}?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(d).pop(false),
              child: const Text('Cancelar')),
          FilledButton(
              onPressed: () => Navigator.of(d).pop(true),
              child: const Text('Aprovar')),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;

    await _executar(
      context,
      () => ref.read(aprovacoesRepositoryProvider).aprovar(
            igrejaId: igrejaId,
            uid: alvo.vinculo.uid,
          ),
      sucesso: 'Cadastro aprovado. O membro já pode entrar.',
    );
  }

  Future<void> _recusar(
      BuildContext context, WidgetRef ref, MembroUnidade alvo) async {
    final igrejaId = _igrejaAutorizadaOuAviso(context, ref);
    if (igrejaId == null) return;

    final motivo = await _pedirMotivo(context, alvo);
    if (motivo == null || !context.mounted) return; // cancelado

    await _executar(
      context,
      () => ref.read(aprovacoesRepositoryProvider).recusar(
            igrejaId: igrejaId,
            uid: alvo.vinculo.uid,
            motivo: motivo,
          ),
      sucesso: 'Cadastro recusado. O vínculo ficou inativo e o histórico foi preservado.',
    );
  }

  /// Diálogo que EXIGE um motivo para a recusa (o servidor rejeita sem ele e
  /// o registra na auditoria). Retorna o motivo, ou null se cancelado.
  Future<String?> _pedirMotivo(BuildContext context, MembroUnidade alvo) {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (d) {
        return StatefulBuilder(
          builder: (d, setState) {
            // O servidor exige 5 caracteres; o botão segue o mesmo limite para
            // não deixar o usuário enviar algo que será recusado.
            final valido = controller.text.trim().length >= 5;
            return AlertDialog(
              title: const Text('Recusar cadastro'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Informe o motivo da recusa de ${alvo.exibicao}.',
                      style: const TextStyle(fontSize: 14)),
                  const SizedBox(height: 12),
                  TextField(
                    controller: controller,
                    autofocus: true,
                    minLines: 2,
                    maxLines: 4,
                    textInputAction: TextInputAction.newline,
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                      hintText: 'Ex.: dados incompletos, não localizado…',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                    onPressed: () => Navigator.of(d).pop(),
                    child: const Text('Cancelar')),
                FilledButton(
                  onPressed: valido
                      ? () => Navigator.of(d).pop(controller.text.trim())
                      : null,
                  style: FilledButton.styleFrom(
                      backgroundColor: AppColors.error),
                  child: const Text('Recusar'),
                ),
              ],
            );
          },
        );
      },
    ).whenComplete(controller.dispose);
  }

  Future<void> _executar(
    BuildContext context,
    Future<void> Function() acao, {
    required String sucesso,
  }) async {
    String mensagem;
    try {
      await acao();
      mensagem = sucesso;
    } on FirebaseException catch (e) {
      mensagem = e.code == 'permission-denied'
          ? 'Sem permissão para esta ação. Confirme seu perfil de liderança '
              'no servidor.'
          : 'Falha no servidor (${e.code}). Tente novamente.';
    } catch (_) {
      mensagem = 'Sem conexão ou falha temporária. Tente novamente.';
    }
    if (!context.mounted) return;
    _mostrar(context, mensagem);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(cadastrosPendentesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.primary,
        elevation: 0,
        title: Text(
          'Cadastros pendentes',
          style: GoogleFonts.montserrat(
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Não foi possível carregar. Verifique se você tem permissão de liderança.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.mutedForeground),
            ),
          ),
        ),
        data: (pendentes) {
          if (pendentes.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.verified_user_outlined,
                        size: 48, color: AppColors.mutedForeground),
                    SizedBox(height: 16),
                    Text('Nenhum cadastro pendente.',
                        style: TextStyle(color: AppColors.mutedForeground)),
                  ],
                ),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: pendentes.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, i) {
              final u = pendentes[i];
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(u.exibicao,
                        style: GoogleFonts.inter(
                            fontWeight: FontWeight.w700,
                            color: AppColors.foreground)),
                    if ((u.email ?? '').isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(u.email!,
                          style: const TextStyle(
                              color: AppColors.mutedForeground, fontSize: 13)),
                    ],
                    if (u.vinculo.atualizadoEm != null)
                      Text(
                          'Solicitado em ${Formatters.data(u.vinculo.atualizadoEm!)}',
                          style: const TextStyle(
                              color: AppColors.muted, fontSize: 12)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _recusar(context, ref, u),
                            icon: const Icon(Icons.close, size: 18),
                            label: const Text('Recusar'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.error,
                              side: const BorderSide(color: AppColors.error),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: () => _aprovar(context, ref, u),
                            icon: const Icon(Icons.check, size: 18),
                            label: const Text('Aprovar'),
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
