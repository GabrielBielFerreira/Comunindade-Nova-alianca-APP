import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../data/bible_book.dart';
import '../providers/bible_providers.dart';
import 'capitulo_reader_screen.dart';

class BibliaHistoricoScreen extends ConsumerWidget {
  const BibliaHistoricoScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historico = ref.watch(historicoProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.primary,
        elevation: 0,
        title: Text('Histórico',
            style: GoogleFonts.montserrat(
                fontWeight: FontWeight.w700, color: AppColors.primary)),
      ),
      body: historico.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) =>
            const Center(child: Text('Não foi possível carregar o histórico.')),
        data: (lista) {
          if (lista.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text('Nenhum capítulo lido ainda.',
                    style: TextStyle(color: AppColors.mutedForeground)),
              ),
            );
          }
          return ListView.separated(
            itemCount: lista.length,
            separatorBuilder: (_, _) =>
                const Divider(height: 1, color: AppColors.border),
            itemBuilder: (context, i) {
              final m = lista[i];
              final nome = m['nome'] as String? ?? '';
              final capitulo = (m['capitulo'] as num?)?.toInt() ?? 1;
              return ListTile(
                leading:
                    const Icon(Icons.menu_book_outlined, color: AppColors.primary),
                title: Text('$nome $capitulo'),
                trailing: const Icon(Icons.chevron_right,
                    color: AppColors.mutedForeground),
                onTap: () {
                  final livro = livroPorNome(nome);
                  if (livro == null) return;
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) =>
                        CapituloReaderScreen(livro: livro, capitulo: capitulo),
                  ));
                },
              );
            },
          );
        },
      ),
    );
  }
}
