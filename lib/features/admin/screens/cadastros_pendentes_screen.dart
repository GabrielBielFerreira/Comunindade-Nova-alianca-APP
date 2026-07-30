import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../auth/data/usuario_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/aprovacoes_providers.dart';

/// Cadastros pendentes — líder/pastor/diácono aprovam ou recusam novos membros.
class CadastrosPendentesScreen extends ConsumerWidget {
  const CadastrosPendentesScreen({super.key});

  Future<void> _confirmar(
    BuildContext context,
    WidgetRef ref,
    UsuarioModel alvo, {
    required bool aprovar,
  }) async {
    final aprovador = ref.read(usuarioProvider);
    if (aprovador == null || !aprovador.isLider) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ação restrita à liderança.')),
      );
      return;
    }

    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text(aprovar ? 'Aprovar cadastro' : 'Recusar cadastro'),
        content: Text(
          aprovar
              ? 'Liberar o acesso de ${alvo.nome}?'
              : 'Recusar o cadastro de ${alvo.nome}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(true),
            child: Text(aprovar ? 'Aprovar' : 'Recusar'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    try {
      final repo = ref.read(aprovacoesRepositoryProvider);
      if (aprovar) {
        await repo.aprovar(
          uid: alvo.uid,
          aprovadorUid: aprovador.uid,
          aprovadorNome: aprovador.nome,
        );
      } else {
        await repo.recusar(
          uid: alvo.uid,
          aprovadorUid: aprovador.uid,
          aprovadorNome: aprovador.nome,
        );
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(aprovar ? 'Cadastro aprovado.' : 'Cadastro recusado.'),
          ),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível concluir a ação.')),
        );
      }
    }
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
                    Text(u.nome,
                        style: GoogleFonts.inter(
                            fontWeight: FontWeight.w700,
                            color: AppColors.foreground)),
                    const SizedBox(height: 4),
                    Text(u.email,
                        style: const TextStyle(
                            color: AppColors.mutedForeground, fontSize: 13)),
                    if (u.telefone.isNotEmpty)
                      Text(u.telefone,
                          style: const TextStyle(
                              color: AppColors.mutedForeground, fontSize: 13)),
                    Text('Cadastrado em ${Formatters.data(u.dataCadastro)}',
                        style: const TextStyle(
                            color: AppColors.muted, fontSize: 12)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () =>
                                _confirmar(context, ref, u, aprovar: false),
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
                            onPressed: () =>
                                _confirmar(context, ref, u, aprovar: true),
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
