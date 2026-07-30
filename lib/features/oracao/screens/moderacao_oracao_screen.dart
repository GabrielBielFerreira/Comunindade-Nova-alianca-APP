import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../providers/oracao_providers.dart';

/// Moderação de pedidos de oração públicos — liderança aprova/recusa antes de
/// aparecerem no Mural da Comunidade.
class ModeracaoOracaoScreen extends ConsumerWidget {
  const ModeracaoOracaoScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(pedidosModeracaoProvider);
    final repo = ref.read(oracaoRepositoryProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.primary,
        elevation: 0,
        title: Text('Pedidos a aprovar',
            style: GoogleFonts.montserrat(
                fontWeight: FontWeight.w700, color: AppColors.primary)),
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text('Não foi possível carregar (requer liderança).',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.mutedForeground)),
          ),
        ),
        data: (lista) {
          if (lista.isEmpty) {
            return const Center(
              child: Text('Nenhum pedido aguardando aprovação.',
                  style: TextStyle(color: AppColors.mutedForeground)),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: lista.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, i) {
              final p = lista[i];
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
                    Row(
                      children: [
                        Expanded(
                          child: Text('${p.nomeExibicao} • ${Formatters.dataRelativa(p.criadoEm)}',
                              style: const TextStyle(
                                  color: AppColors.mutedForeground, fontSize: 12)),
                        ),
                        if (p.urgente)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                                color: AppColors.accentSoft,
                                borderRadius: BorderRadius.circular(999)),
                            child: const Text('URGENTE',
                                style: TextStyle(
                                    color: AppColors.accent,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700)),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(p.texto,
                        style: const TextStyle(
                            fontSize: 15, color: AppColors.foreground)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => repo.recusarPedido(p.id),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.error,
                              side: const BorderSide(color: AppColors.error),
                            ),
                            child: const Text('Recusar'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton(
                            onPressed: () => repo.aprovarPedido(p.id),
                            style: FilledButton.styleFrom(
                                backgroundColor: AppColors.primary),
                            child: const Text('Aprovar'),
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
