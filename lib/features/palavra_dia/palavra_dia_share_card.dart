import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'palavra_do_dia.dart';

/// Formatos de compartilhamento suportados.
enum ShareCardFormato {
  /// Feed (Instagram/WhatsApp/Telegram): 1080 × 1350.
  feed(1080, 1350),

  /// Stories: 1080 × 1920.
  story(1080, 1920);

  const ShareCardFormato(this.largura, this.altura);
  final double largura;
  final double altura;
}

/// Card de divulgação da Palavra do Dia — desenhado em unidades de PIXEL do
/// resultado final (1080 de largura). Renderizado dentro de um RepaintBoundary
/// e capturado no tamanho nativo. Identidade oficial: vinho #7A0022, cartão
/// branco, Montserrat (títulos) e Inter (textos). Sem dourado, sem modo escuro.
///
/// Textos usam [FittedBox]/quebra de linha para NUNCA cortar conteúdo, logotipo
/// ou chamada, mesmo com versículos longos.
class PalavraDiaShareCard extends StatelessWidget {
  const PalavraDiaShareCard({
    super.key,
    required this.palavra,
    required this.linkOficial,
    this.formato = ShareCardFormato.feed,
  });

  final PalavraDoDia palavra;
  final String linkOficial;
  final ShareCardFormato formato;

  static const _primary = Color(0xFF7A0022);
  static const _dark = Color(0xFF510014);
  static const _cardBg = Colors.white;
  static const _title = Color(0xFF1A1A1A);
  static const _body = Color(0xFF584142);
  static const _muted = Color(0xFF6B7280);

  static const _logo = 'assets/images/figma/welcome/welcome_logo.png';

  String get _dataFormatada {
    const meses = [
      'janeiro', 'fevereiro', 'março', 'abril', 'maio', 'junho',
      'julho', 'agosto', 'setembro', 'outubro', 'novembro', 'dezembro',
    ];
    final d = palavra.data;
    final mes = (d.month >= 1 && d.month <= 12) ? meses[d.month - 1] : '';
    return '${d.day} de $mes de ${d.year}';
  }

  String get _chamada {
    final r = palavra.reflexao?.trim();
    if (r != null && r.isNotEmpty) return r;
    return 'Fortaleça sua fé todos os dias.';
  }

  @override
  Widget build(BuildContext context) {
    final isStory = formato == ShareCardFormato.story;
    // Isola o card da escala de fonte do sistema para que a imagem gerada seja
    // idêntica para todos, independentemente das preferências do aparelho.
    return MediaQuery(
      data: const MediaQueryData(textScaler: TextScaler.noScaling),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Container(
          width: formato.largura,
          height: formato.altura,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [_primary, _dark],
            ),
          ),
          child: Stack(
            children: [
              // Elementos visuais discretos (círculos translúcidos + aspas).
              Positioned(
                top: -160,
                right: -140,
                child: _circulo(420, Colors.white.withValues(alpha: 0.06)),
              ),
              Positioned(
                bottom: -180,
                left: -150,
                child: _circulo(460, Colors.white.withValues(alpha: 0.05)),
              ),
              Positioned(
                top: isStory ? 300 : 210,
                left: 70,
                child: Text(
                  '“',
                  style: GoogleFonts.montserrat(
                    fontSize: 300,
                    height: 1,
                    fontWeight: FontWeight.w700,
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                ),
              ),
              // Conteúdo com altura natural, escalado por um único FittedBox
              // (scaleDown): garante que NADA seja cortado nem estoure —
              // versículos longos apenas reduzem o card proporcionalmente.
              Positioned.fill(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(80, isStory ? 150 : 90, 80,
                      isStory ? 140 : 80),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.topCenter,
                    child: SizedBox(
                      width: formato.largura - 160,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _cabecalho(),
                          SizedBox(height: isStory ? 70 : 48),
                          _cartaoVersiculo(),
                          SizedBox(height: isStory ? 70 : 48),
                          _rodape(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _circulo(double d, Color c) => Container(
        width: d,
        height: d,
        decoration: BoxDecoration(color: c, shape: BoxShape.circle),
      );

  Widget _cabecalho() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 120,
          height: 120,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
          padding: const EdgeInsets.all(14),
          child: ClipOval(
            child: Image.asset(
              _logo,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => const SizedBox.shrink(),
            ),
          ),
        ),
        const SizedBox(width: 28),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'PALAVRA DO DIA',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.montserrat(
                  fontSize: 40,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 3,
                  height: 1.1,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _dataFormatada,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 28,
                  color: Colors.white.withValues(alpha: 0.85),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _cartaoVersiculo() {
    final texto = palavra.temTexto ? '“${palavra.texto}”' : palavra.referencia;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(64, 64, 64, 56),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(48),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 40,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Altura natural; o FittedBox externo reduz tudo se necessário. Um
          // maxLines alto evita reticências mesmo em versículos longos.
          Text(
            texto,
            maxLines: 14,
            style: GoogleFonts.montserrat(
              fontSize: 58,
              fontWeight: FontWeight.w600,
              height: 1.32,
              color: _title,
            ),
          ),
          const SizedBox(height: 40),
          Container(height: 4, width: 96, color: _primary),
          const SizedBox(height: 28),
          Text(
            palavra.referencia,
            style: GoogleFonts.montserrat(
              fontSize: 46,
              fontWeight: FontWeight.w800,
              color: _primary,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            palavra.traducao,
            style: GoogleFonts.inter(fontSize: 26, color: _muted),
          ),
          if (palavra.reflexao != null &&
              palavra.reflexao!.trim().isNotEmpty) ...[
            const SizedBox(height: 26),
            Text(
              palavra.reflexao!.trim(),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: 30,
                height: 1.4,
                fontStyle: FontStyle.italic,
                color: _body,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _rodape() {
    return Column(
      children: [
        Text(
          _chamada,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.montserrat(
            fontSize: 34,
            fontWeight: FontWeight.w600,
            height: 1.3,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 22),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 34, vertical: 20),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Nova Aliança App',
                style: GoogleFonts.montserrat(
                  fontSize: 38,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                linkOficial.isNotEmpty
                    ? 'Baixe e participe: $linkOficial'
                    : 'Baixe e participe da comunidade',
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 26,
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
