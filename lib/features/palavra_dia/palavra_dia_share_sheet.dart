import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'palavra_dia_share_card.dart';
import 'palavra_dia_share_service.dart';
import 'palavra_do_dia.dart';

/// Folha de pré-visualização e compartilhamento da Palavra do Dia.
///
/// Mostra o card pronto (feed 1080×1350), gera a imagem em alta resolução e
/// abre o compartilhamento nativo com legenda + link. Oferece também a versão
/// para Stories (1080×1920). Exibe carregamento e mensagem de erro claros.
class PalavraDiaShareSheet extends ConsumerStatefulWidget {
  const PalavraDiaShareSheet({super.key, required this.palavra});

  final PalavraDoDia palavra;

  static Future<void> abrir(BuildContext context, PalavraDoDia palavra) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => PalavraDiaShareSheet(palavra: palavra),
    );
  }

  @override
  ConsumerState<PalavraDiaShareSheet> createState() =>
      _PalavraDiaShareSheetState();
}

class _PalavraDiaShareSheetState extends ConsumerState<PalavraDiaShareSheet> {
  static const _primary = Color(0xFF7A0022);
  static const _title = Color(0xFF1A1A1A);
  static const _muted = Color(0xFF6B7280);
  static const _logo = 'assets/images/figma/welcome/welcome_logo.png';

  final GlobalKey _feedKey = GlobalKey();
  final GlobalKey _storyKey = GlobalKey();

  bool _gerando = false;
  String? _erro;
  bool _precached = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_precached) {
      _precached = true;
      // Garante o logotipo carregado antes da captura.
      precacheImage(const AssetImage(_logo), context);
    }
  }

  Future<void> _compartilhar(ShareCardFormato formato) async {
    if (_gerando) return;
    setState(() {
      _gerando = true;
      _erro = null;
    });
    final link = ref.read(linkOficialProvider).valueOrNull ?? '';
    try {
      // Aguarda o fim do frame para garantir layout e assets prontos.
      await WidgetsBinding.instance.endOfFrame;
      final key = formato == ShareCardFormato.feed ? _feedKey : _storyKey;
      final png = await PalavraDiaShareService.capturarPng(key);
      final legenda =
          PalavraDiaShareService.montarLegenda(widget.palavra, link);
      await PalavraDiaShareService.compartilhar(png: png, legenda: legenda);
    } catch (_) {
      if (mounted) {
        setState(() => _erro =
            'Não foi possível gerar a imagem. Verifique a conexão e tente novamente.');
      }
    } finally {
      if (mounted) setState(() => _gerando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final link = ref.watch(linkOficialProvider).valueOrNull ?? '';
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    final maxPreviewHeight = MediaQuery.sizeOf(context).height * 0.5;

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 8, 20, 16 + bottomInset),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE5E7EB),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Text(
                  'Compartilhar',
                  style: GoogleFonts.montserrat(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: _title,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  icon: const Icon(Icons.close_rounded, color: _muted),
                  tooltip: 'Fechar',
                ),
              ],
            ),
            const SizedBox(height: 4),
            // Pré-visualização (card feed em escala).
            Flexible(
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: maxPreviewHeight),
                  child: AspectRatio(
                    aspectRatio:
                        ShareCardFormato.feed.largura / ShareCardFormato.feed.altura,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: FittedBox(
                        fit: BoxFit.contain,
                        child: RepaintBoundary(
                          key: _feedKey,
                          child: SizedBox(
                            width: ShareCardFormato.feed.largura,
                            height: ShareCardFormato.feed.altura,
                            child: PalavraDiaShareCard(
                              palavra: widget.palavra,
                              linkOficial: link,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            if (_erro != null) ...[
              const SizedBox(height: 12),
              Text(
                _erro!,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: const Color(0xFFB02D21),
                ),
              ),
            ],
            const SizedBox(height: 16),
            _BotaoPrimario(
              rotulo: 'Compartilhar',
              icone: Icons.share_rounded,
              carregando: _gerando,
              onTap: () => _compartilhar(ShareCardFormato.feed),
            ),
            const SizedBox(height: 10),
            _BotaoSecundario(
              rotulo: 'Compartilhar nos Stories',
              icone: Icons.auto_awesome_rounded,
              habilitado: !_gerando,
              onTap: () => _compartilhar(ShareCardFormato.story),
            ),
            // Boundary do Stories: pintado (para captura) porém recortado a 1px.
            _OffstagePintado(
              child: RepaintBoundary(
                key: _storyKey,
                child: SizedBox(
                  width: ShareCardFormato.story.largura,
                  height: ShareCardFormato.story.altura,
                  child: PalavraDiaShareCard(
                    palavra: widget.palavra,
                    linkOficial: link,
                    formato: ShareCardFormato.story,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Mantém [child] no tamanho nativo e PINTADO (necessário para `toImage`),
/// porém visível como 1×1 px (praticamente invisível na tela).
class _OffstagePintado extends StatelessWidget {
  const _OffstagePintado({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: SizedBox(
        width: 1,
        height: 1,
        child: OverflowBox(
          alignment: Alignment.topLeft,
          minWidth: 0,
          minHeight: 0,
          maxWidth: double.infinity,
          maxHeight: double.infinity,
          child: child,
        ),
      ),
    );
  }
}

class _BotaoPrimario extends StatelessWidget {
  const _BotaoPrimario({
    required this.rotulo,
    required this.icone,
    required this.carregando,
    required this.onTap,
  });

  final String rotulo;
  final IconData icone;
  final bool carregando;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: !carregando,
      label: carregando ? 'Gerando imagem para compartilhar' : rotulo,
      child: SizedBox(
        height: 54,
        child: ElevatedButton.icon(
          onPressed: carregando ? null : onTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: _PalavraDiaShareSheetState._primary,
            foregroundColor: Colors.white,
            disabledBackgroundColor:
                _PalavraDiaShareSheetState._primary.withValues(alpha: 0.6),
            disabledForegroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          icon: carregando
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Icon(icone, size: 20),
          label: Text(
            carregando ? 'Gerando imagem…' : rotulo,
            style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700),
          ),
        ),
      ),
    );
  }
}

class _BotaoSecundario extends StatelessWidget {
  const _BotaoSecundario({
    required this.rotulo,
    required this.icone,
    required this.habilitado,
    required this.onTap,
  });

  final String rotulo;
  final IconData icone;
  final bool habilitado;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: habilitado,
      label: rotulo,
      child: SizedBox(
        height: 52,
        child: OutlinedButton.icon(
          onPressed: habilitado ? onTap : null,
          style: OutlinedButton.styleFrom(
            foregroundColor: _PalavraDiaShareSheetState._primary,
            side: const BorderSide(color: _PalavraDiaShareSheetState._primary),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          icon: Icon(icone, size: 20),
          label: Text(
            rotulo,
            style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }
}
