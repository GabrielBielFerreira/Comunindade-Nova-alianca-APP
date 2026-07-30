import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/theme/app_colors.dart';
import '../data/bible_book.dart';
import '../data/bible_models.dart';
import '../providers/bible_providers.dart';

/// Leitor de capítulo: versículos numerados, navegação anterior/seguinte,
/// controle de fonte, copiar/compartilhar/favoritar versículo, estados de
/// carregamento, erro (com "Tentar novamente") e offline.
class CapituloReaderScreen extends ConsumerStatefulWidget {
  const CapituloReaderScreen({
    super.key,
    required this.livro,
    required this.capitulo,
  });

  final BibleBook livro;
  final int capitulo;

  @override
  ConsumerState<CapituloReaderScreen> createState() =>
      _CapituloReaderScreenState();
}

class _CapituloReaderScreenState extends ConsumerState<CapituloReaderScreen> {
  late BibleBook _livro = widget.livro;
  late int _capitulo = widget.capitulo;
  int? _versiculoSelecionado;
  String? _ultimoRegistrado;

  int get _indiceLivro => kBibliaLivros.indexOf(_livro);

  bool get _temAnterior => _capitulo > 1 || _indiceLivro > 0;
  bool get _temProximo =>
      _capitulo < _livro.capitulos || _indiceLivro < kBibliaLivros.length - 1;

  void _anterior() {
    setState(() {
      _versiculoSelecionado = null;
      if (_capitulo > 1) {
        _capitulo--;
      } else if (_indiceLivro > 0) {
        _livro = kBibliaLivros[_indiceLivro - 1];
        _capitulo = _livro.capitulos;
      }
    });
  }

  void _proximo() {
    setState(() {
      _versiculoSelecionado = null;
      if (_capitulo < _livro.capitulos) {
        _capitulo++;
      } else if (_indiceLivro < kBibliaLivros.length - 1) {
        _livro = kBibliaLivros[_indiceLivro + 1];
        _capitulo = 1;
      }
    });
  }

  void _registrarLeitura(BibleChapter cap) {
    final chave = '${cap.livroApiName}|${cap.capitulo}';
    if (_ultimoRegistrado == chave) return;
    _ultimoRegistrado = chave;
    final store = ref.read(bibleStoreProvider);
    store.registrarHistorico(cap.livroApiName, cap.capitulo, _livro.nome);
    store.salvarUltimoLido(cap.livroApiName, cap.capitulo, _livro.nome);
  }

  @override
  Widget build(BuildContext context) {
    final arg = CapituloArg(_livro.apiName, _capitulo, _livro.nome);
    final capAsync = ref.watch(capituloProvider(arg));
    final fontScale = ref.watch(fontScaleProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.primary,
        elevation: 0,
        title: Text(
          '${_livro.nome} $_capitulo',
          style: GoogleFonts.montserrat(
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Diminuir fonte',
            icon: const Icon(Icons.text_decrease),
            onPressed: ref.read(fontScaleProvider.notifier).diminuir,
          ),
          IconButton(
            tooltip: 'Aumentar fonte',
            icon: const Icon(Icons.text_increase),
            onPressed: ref.read(fontScaleProvider.notifier).aumentar,
          ),
        ],
      ),
      body: capAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _ErroCapitulo(
          mensagem: e is BibleException
              ? e.mensagem
              : 'Não foi possível carregar o capítulo.',
          onTentar: () => ref.invalidate(capituloProvider(arg)),
        ),
        data: (cap) {
          WidgetsBinding.instance
              .addPostFrameCallback((_) => _registrarLeitura(cap));
          return _ConteudoCapitulo(
            capitulo: cap,
            livro: _livro,
            fontScale: fontScale,
            selecionado: _versiculoSelecionado,
            onSelecionar: (n) => setState(() =>
                _versiculoSelecionado = _versiculoSelecionado == n ? null : n),
          );
        },
      ),
      bottomNavigationBar: _BarraNavegacao(
        temAnterior: _temAnterior,
        temProximo: _temProximo,
        onAnterior: _anterior,
        onProximo: _proximo,
      ),
    );
  }
}

class _ConteudoCapitulo extends ConsumerWidget {
  const _ConteudoCapitulo({
    required this.capitulo,
    required this.livro,
    required this.fontScale,
    required this.selecionado,
    required this.onSelecionar,
  });

  final BibleChapter capitulo;
  final BibleBook livro;
  final double fontScale;
  final int? selecionado;
  final void Function(int) onSelecionar;

  BibleVerseRef _ref(int numero) => BibleVerseRef(
        livroNome: livro.nome,
        livroApiName: livro.apiName,
        capitulo: capitulo.capitulo,
        versiculo: numero,
      );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Stack(
      children: [
        ListView.builder(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 96),
          itemCount: capitulo.versiculos.length,
          itemBuilder: (context, i) {
            final v = capitulo.versiculos[i];
            final isSel = selecionado == v.numero;
            return GestureDetector(
              onTap: () => onSelecionar(v.numero),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                margin: const EdgeInsets.only(bottom: 2),
                decoration: BoxDecoration(
                  color: isSel ? AppColors.primarySoft : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: '${v.numero}  ',
                        style: GoogleFonts.inter(
                          fontSize: 12 * fontScale,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                      TextSpan(
                        text: v.texto,
                        style: GoogleFonts.inter(
                          fontSize: 17 * fontScale,
                          height: 1.6,
                          color: AppColors.foreground,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
        if (selecionado != null)
          Align(
            alignment: Alignment.bottomCenter,
            child: _AcoesVersiculo(
              ref: _ref(selecionado!),
              texto: capitulo.versiculos
                  .firstWhere((v) => v.numero == selecionado)
                  .texto,
            ),
          ),
      ],
    );
  }
}

class _AcoesVersiculo extends ConsumerWidget {
  const _AcoesVersiculo({required this.ref, required this.texto});
  final BibleVerseRef ref;
  final String texto;

  String get _formatado => '"$texto"\n— ${ref.referencia} (Almeida)';

  @override
  Widget build(BuildContext context, WidgetRef widgetRef) {
    final favoritos = widgetRef.watch(favoritosProvider).valueOrNull ?? [];
    final isFav = favoritos.any((m) =>
        m['livroApiName'] == ref.livroApiName &&
        m['capitulo'] == ref.capitulo &&
        m['versiculo'] == ref.versiculo);

    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(color: Color(0x14000000), blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _AcaoBotao(
            icone: Icons.copy_rounded,
            rotulo: 'Copiar',
            onTap: () async {
              await Clipboard.setData(ClipboardData(text: _formatado));
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Versículo copiado.')),
                );
              }
            },
          ),
          _AcaoBotao(
            icone: Icons.share_rounded,
            rotulo: 'Compartilhar',
            onTap: () => Share.share(_formatado),
          ),
          _AcaoBotao(
            icone: isFav ? Icons.favorite : Icons.favorite_border,
            rotulo: 'Favoritar',
            onTap: () =>
                widgetRef.read(favoritosProvider.notifier).alternar(ref, texto),
          ),
        ],
      ),
    );
  }
}

class _AcaoBotao extends StatelessWidget {
  const _AcaoBotao(
      {required this.icone, required this.rotulo, required this.onTap});
  final IconData icone;
  final String rotulo;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: rotulo,
      child: TextButton.icon(
        onPressed: onTap,
        icon: Icon(icone, size: 20, color: AppColors.primary),
        label: Text(rotulo,
            style: const TextStyle(color: AppColors.primary, fontSize: 12)),
      ),
    );
  }
}

class _BarraNavegacao extends StatelessWidget {
  const _BarraNavegacao({
    required this.temAnterior,
    required this.temProximo,
    required this.onAnterior,
    required this.onProximo,
  });

  final bool temAnterior;
  final bool temProximo;
  final VoidCallback onAnterior;
  final VoidCallback onProximo;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton.icon(
              onPressed: temAnterior ? onAnterior : null,
              icon: const Icon(Icons.chevron_left),
              label: const Text('Anterior'),
            ),
            TextButton(
              onPressed: temProximo ? onProximo : null,
              child: Row(
                children: const [Text('Próximo'), Icon(Icons.chevron_right)],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErroCapitulo extends StatelessWidget {
  const _ErroCapitulo({required this.mensagem, required this.onTentar});
  final String mensagem;
  final VoidCallback onTentar;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_rounded,
                size: 48, color: AppColors.mutedForeground),
            const SizedBox(height: 16),
            Text(mensagem,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.mutedForeground)),
            const SizedBox(height: 16),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
              onPressed: onTentar,
              child: const Text('Tentar novamente'),
            ),
          ],
        ),
      ),
    );
  }
}
