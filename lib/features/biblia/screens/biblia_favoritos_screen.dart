import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../data/bible_book.dart';
import '../data/bible_models.dart';
import '../providers/bible_providers.dart';
import 'capitulo_reader_screen.dart';

class BibliaFavoritosScreen extends ConsumerWidget {
  const BibliaFavoritosScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favoritos = ref.watch(favoritosProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.primary,
        elevation: 0,
        title: Text('Favoritos',
            style: GoogleFonts.montserrat(
                fontWeight: FontWeight.w700, color: AppColors.primary)),
      ),
      body: favoritos.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) =>
            const Center(child: Text('Não foi possível carregar os favoritos.')),
        data: (lista) {
          if (lista.isEmpty) {
            return const _Vazio(
              icone: Icons.favorite_border,
              texto: 'Nenhum versículo favoritado ainda.\n'
                  'Toque em um versículo e escolha "Favoritar".',
            );
          }
          return ListView.separated(
            itemCount: lista.length,
            separatorBuilder: (_, _) =>
                const Divider(height: 1, color: AppColors.border),
            itemBuilder: (context, i) {
              final m = lista[i];
              final refVerse = BibleVerseRef.fromJson(m);
              final texto = m['texto'] as String? ?? '';
              return ListTile(
                title: Text('"$texto"',
                    maxLines: 3, overflow: TextOverflow.ellipsis),
                subtitle: Text(refVerse.referencia,
                    style: const TextStyle(color: AppColors.primary)),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => ref
                      .read(favoritosProvider.notifier)
                      .alternar(refVerse, texto),
                ),
                onTap: () {
                  final livro = livroPorNome(refVerse.livroNome);
                  if (livro == null) return;
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => CapituloReaderScreen(
                        livro: livro, capitulo: refVerse.capitulo),
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

class _Vazio extends StatelessWidget {
  const _Vazio({required this.icone, required this.texto});
  final IconData icone;
  final String texto;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icone, size: 48, color: AppColors.mutedForeground),
            const SizedBox(height: 16),
            Text(texto,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.mutedForeground)),
          ],
        ),
      ),
    );
  }
}
