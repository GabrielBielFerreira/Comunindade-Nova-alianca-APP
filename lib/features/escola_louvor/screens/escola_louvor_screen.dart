import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_colors.dart';

/// Configuração da Escola de Louvor (documento `configuracoes/escola_louvor`).
final escolaLouvorProvider =
    FutureProvider.autoDispose<Map<String, dynamic>?>((ref) async {
  final doc = await FirebaseFirestore.instance
      .collection('configuracoes')
      .doc('escola_louvor')
      .get();
  return doc.data();
});

/// Escola de Louvor — descrição, agenda, materiais e contato (dados reais do
/// Firebase). Só é acessível quando habilitada por feature flag.
class EscolaLouvorScreen extends ConsumerWidget {
  const EscolaLouvorScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(escolaLouvorProvider);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.primary,
        elevation: 0,
        title: Text('Escola de Louvor',
            style: GoogleFonts.montserrat(
                fontWeight: FontWeight.w700, color: AppColors.primary)),
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => const Center(child: Text('Não foi possível carregar.')),
        data: (dados) {
          if (dados == null) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  'Conteúdo da Escola de Louvor ainda não configurado.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.mutedForeground),
                ),
              ),
            );
          }
          final contato = dados['contato'] as String?;
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              if (dados['descricao'] != null) ...[
                Text('Sobre',
                    style: GoogleFonts.montserrat(
                        fontWeight: FontWeight.w700, fontSize: 16)),
                const SizedBox(height: 8),
                Text('${dados['descricao']}',
                    style: const TextStyle(height: 1.6)),
                const SizedBox(height: 20),
              ],
              if (dados['agenda'] != null) ...[
                Text('Agenda',
                    style: GoogleFonts.montserrat(
                        fontWeight: FontWeight.w700, fontSize: 16)),
                const SizedBox(height: 8),
                Text('${dados['agenda']}', style: const TextStyle(height: 1.6)),
                const SizedBox(height: 20),
              ],
              if (contato != null && contato.isNotEmpty)
                FilledButton.icon(
                  style:
                      FilledButton.styleFrom(backgroundColor: AppColors.primary),
                  onPressed: () {
                    final uri = Uri.tryParse(contato);
                    if (uri != null) {
                      launchUrl(uri, mode: LaunchMode.externalApplication);
                    }
                  },
                  icon: const Icon(Icons.contact_page_outlined),
                  label: const Text('Falar com a liderança'),
                ),
            ],
          );
        },
      ),
    );
  }
}
