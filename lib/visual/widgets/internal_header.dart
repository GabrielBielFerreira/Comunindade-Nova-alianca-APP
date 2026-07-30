import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Header padrão das telas internas (push por cima, sem bottom navigation).
///
/// Botão de voltar à esquerda + título (e subtítulo opcional) centralizado,
/// fundo branco com borda inferior — no estilo Nova Aliança.
class InternalHeader extends StatelessWidget {
  const InternalHeader({
    super.key,
    required this.title,
    required this.scale,
    required this.topPadding,
    this.subtitle,
    this.uppercaseTitle = true,
    this.titleSize = 16,
  });

  static const _line = Color(0xFFE5E7EB);
  static const _title = Color(0xFF1A1A1A);
  static const _muted = Color(0xFF6B7280);

  final String title;
  final String? subtitle;
  final double scale;
  final double topPadding;
  final bool uppercaseTitle;
  final double titleSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64 * scale + topPadding,
      width: double.infinity,
      padding: EdgeInsets.only(top: topPadding),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: _line)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 56 * scale,
            child: IconButton(
              onPressed: () => Navigator.maybePop(context),
              icon: Icon(Icons.arrow_back, size: 22 * scale, color: _title),
            ),
          ),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  uppercaseTitle ? title.toUpperCase() : title,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.montserrat(
                    fontSize: titleSize * scale,
                    fontWeight: FontWeight.w700,
                    color: _title,
                  ),
                ),
                if (subtitle != null) ...[
                  SizedBox(height: 2 * scale),
                  Text(
                    subtitle!,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 12 * scale,
                      fontWeight: FontWeight.w400,
                      height: 16 / 12,
                      color: _muted,
                    ),
                  ),
                ],
              ],
            ),
          ),
          // Espaçador para manter o título opticamente centralizado.
          SizedBox(width: 56 * scale),
        ],
      ),
    );
  }
}