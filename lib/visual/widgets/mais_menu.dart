import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/config/app_config.dart';
import '../visual_router.dart';

/// Menu "Mais" (☰) da Home — folha inferior on-brand com atalhos reais.
///
/// Só lista itens que possuem destino real. A seção de liderança só aparece
/// para pastores/diáconos/líderes ([isLider]); a Escola de Louvor só aparece
/// quando habilitada por feature flag.
Future<void> showMaisMenu(BuildContext context, {required bool isLider}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => _MaisMenuSheet(isLider: isLider),
  );
}

class _MenuEntry {
  const _MenuEntry(this.icone, this.titulo, this.subtitulo, this.rota);
  final IconData icone;
  final String titulo;
  final String subtitulo;
  final String rota;
}

class _MaisMenuSheet extends StatelessWidget {
  const _MaisMenuSheet({required this.isLider});

  final bool isLider;

  static const _primary = Color(0xFF7A0022);
  static const _soft = Color(0xFFF5E6EC);
  static const _title = Color(0xFF1A1A1A);
  static const _muted = Color(0xFF6B7280);
  static const _line = Color(0xFFE5E7EB);

  List<_MenuEntry> get _principais => [
        const _MenuEntry(Icons.church_rounded, 'Sobre a Comunidade',
            'Quem somos e onde estamos', VisualRoutes.sobreComunidade),
        const _MenuEntry(Icons.menu_book_rounded, 'Bíblia',
            'Leia e favorite', VisualRoutes.biblia),
        const _MenuEntry(Icons.library_music_rounded, 'Cantor Cristão',
            'Hinos por número', VisualRoutes.cantorCristao),
        const _MenuEntry(Icons.auto_stories_rounded, 'Devocionais',
            'Palavra diária', VisualRoutes.devocionais),
        if (AppConfig.escolaDeLouvorHabilitada)
          const _MenuEntry(Icons.school_rounded, 'Escola de Louvor',
              'Formação musical', VisualRoutes.escolaLouvor),
        const _MenuEntry(Icons.settings_outlined, 'Configurações',
            'Preferências e notificações', VisualRoutes.configuracoes),
        const _MenuEntry(Icons.help_outline_rounded, 'Ajuda',
            'Dúvidas e contato', VisualRoutes.ajuda),
      ];

  List<_MenuEntry> get _lideranca => [
        const _MenuEntry(Icons.how_to_reg_outlined, 'Cadastros pendentes',
            'Aprovar novos membros', VisualRoutes.cadastrosPendentes),
        const _MenuEntry(Icons.reviews_outlined, 'Moderação de oração',
            'Aprovar pedidos públicos', VisualRoutes.moderacaoOracao),
        const _MenuEntry(Icons.admin_panel_settings_outlined, 'Gestão',
            'Ferramentas da liderança', VisualRoutes.gestao),
      ];

  @override
  Widget build(BuildContext context) {
    final scale = (MediaQuery.sizeOf(context).width / 394)
        .clamp(0.86, 1.0)
        .toDouble();
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.82,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20 * scale)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(height: 10 * scale),
          Container(
            width: 40 * scale,
            height: 4 * scale,
            decoration: BoxDecoration(
              color: _line,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(20 * scale, 14 * scale, 20 * scale, 4 * scale),
            child: Row(
              children: [
                Text(
                  'Mais',
                  style: GoogleFonts.montserrat(
                    fontSize: 20 * scale,
                    fontWeight: FontWeight.w700,
                    color: _title,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  icon: Icon(Icons.close_rounded, size: 22 * scale, color: _muted),
                  splashRadius: 22 * scale,
                ),
              ],
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              padding: EdgeInsets.only(bottom: bottomInset + 16 * scale),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final e in _principais) _MenuRow(entry: e, scale: scale),
                  if (isLider) ...[
                    SizedBox(height: 8 * scale),
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                          20 * scale, 12 * scale, 20 * scale, 8 * scale),
                      child: Text(
                        'LIDERANÇA',
                        style: GoogleFonts.inter(
                          fontSize: 12 * scale,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.6 * scale,
                          color: _muted,
                        ),
                      ),
                    ),
                    for (final e in _lideranca) _MenuRow(entry: e, scale: scale),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({required this.entry, required this.scale});

  final _MenuEntry entry;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.of(context).pop();
        Navigator.pushNamed(context, entry.rota);
      },
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20 * scale, vertical: 12 * scale),
        child: Row(
          children: [
            Container(
              width: 44 * scale,
              height: 44 * scale,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: _MaisMenuSheet._soft,
                shape: BoxShape.circle,
              ),
              child: Icon(entry.icone,
                  color: _MaisMenuSheet._primary, size: 22 * scale),
            ),
            SizedBox(width: 14 * scale),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.titulo,
                    style: GoogleFonts.montserrat(
                      fontSize: 16 * scale,
                      fontWeight: FontWeight.w700,
                      color: _MaisMenuSheet._title,
                    ),
                  ),
                  SizedBox(height: 2 * scale),
                  Text(
                    entry.subtitulo,
                    style: GoogleFonts.inter(
                      fontSize: 13 * scale,
                      color: _MaisMenuSheet._muted,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                size: 22 * scale, color: _MaisMenuSheet._muted),
          ],
        ),
      ),
    );
  }
}
