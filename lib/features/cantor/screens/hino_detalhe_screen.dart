import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/theme/app_colors.dart';
import '../data/hino.dart';
import '../providers/hymnal_providers.dart';

/// Página individual de um hino: número e título em destaque, estrofes
/// organizadas, navegação anterior/seguinte, favoritos e controle de fonte.
/// Compartilha apenas a referência (número/título), não a letra, respeitando
/// limites de licença.
class HinoDetalheScreen extends ConsumerStatefulWidget {
  const HinoDetalheScreen({
    super.key,
    required this.hinos,
    required this.numero,
  });

  final List<Hino> hinos;
  final int numero;

  @override
  ConsumerState<HinoDetalheScreen> createState() => _HinoDetalheScreenState();
}

class _HinoDetalheScreenState extends ConsumerState<HinoDetalheScreen> {
  late int _indice =
      widget.hinos.indexWhere((h) => h.numero == widget.numero).clamp(0, widget.hinos.length - 1);

  Hino get _hino => widget.hinos[_indice];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(hymnalStoreProvider).registrarHistorico(_hino.numero);
    });
  }

  void _ir(int delta) {
    final novo = _indice + delta;
    if (novo < 0 || novo >= widget.hinos.length) return;
    setState(() => _indice = novo);
    ref.read(hymnalStoreProvider).registrarHistorico(_hino.numero);
  }

  @override
  Widget build(BuildContext context) {
    final fontScale = ref.watch(hymnalFontScaleProvider);
    final favoritos = ref.watch(hinosFavoritosProvider).valueOrNull ?? [];
    final isFav = favoritos.contains(_hino.numero);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.primary,
        elevation: 0,
        title: Text(
          'Hino ${_hino.numero}',
          style: GoogleFonts.montserrat(
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Diminuir fonte',
            icon: const Icon(Icons.text_decrease),
            onPressed: ref.read(hymnalFontScaleProvider.notifier).diminuir,
          ),
          IconButton(
            tooltip: 'Aumentar fonte',
            icon: const Icon(Icons.text_increase),
            onPressed: ref.read(hymnalFontScaleProvider.notifier).aumentar,
          ),
          IconButton(
            tooltip: 'Favoritar',
            icon: Icon(isFav ? Icons.favorite : Icons.favorite_border),
            onPressed: () =>
                ref.read(hinosFavoritosProvider.notifier).alternar(_hino.numero),
          ),
          IconButton(
            tooltip: 'Compartilhar referência',
            icon: const Icon(Icons.share),
            onPressed: () => Share.share(
                'Hino ${_hino.numero} — ${_hino.titulo} (Cantor Cristão)'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        children: [
          Text(
            _hino.titulo,
            style: GoogleFonts.montserrat(
              fontSize: 22 * fontScale,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
          if (_hino.autoria != null && _hino.autoria!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              _hino.autoria!,
              style: TextStyle(
                fontSize: 13 * fontScale,
                color: AppColors.mutedForeground,
              ),
            ),
          ],
          const SizedBox(height: 16),
          for (var i = 0; i < _hino.estrofes.length; i++) ...[
            _Estrofe(
              numero: i + 1,
              texto: _hino.estrofes[i],
              fontScale: fontScale,
            ),
            if (_hino.coro != null && _hino.coro!.isNotEmpty)
              _Coro(texto: _hino.coro!, fontScale: fontScale),
          ],
          if (_hino.direitos != null && _hino.direitos!.isNotEmpty) ...[
            const SizedBox(height: 24),
            Text(
              _hino.direitos!,
              style: TextStyle(
                fontSize: 11 * fontScale,
                color: AppColors.muted,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
      bottomNavigationBar: SafeArea(
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
                onPressed: _indice > 0 ? () => _ir(-1) : null,
                icon: const Icon(Icons.chevron_left),
                label: const Text('Anterior'),
              ),
              TextButton(
                onPressed:
                    _indice < widget.hinos.length - 1 ? () => _ir(1) : null,
                child: Row(
                  children: const [Text('Próximo'), Icon(Icons.chevron_right)],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Estrofe extends StatelessWidget {
  const _Estrofe(
      {required this.numero, required this.texto, required this.fontScale});
  final int numero;
  final String texto;
  final double fontScale;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$numero',
            style: GoogleFonts.inter(
              fontSize: 13 * fontScale,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              texto,
              style: GoogleFonts.inter(
                fontSize: 17 * fontScale,
                height: 1.6,
                color: AppColors.foreground,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Coro extends StatelessWidget {
  const _Coro({required this.texto, required this.fontScale});
  final String texto;
  final double fontScale;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16, left: 24),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        texto,
        style: GoogleFonts.inter(
          fontSize: 16 * fontScale,
          height: 1.6,
          fontStyle: FontStyle.italic,
          color: AppColors.foreground,
        ),
      ),
    );
  }
}
