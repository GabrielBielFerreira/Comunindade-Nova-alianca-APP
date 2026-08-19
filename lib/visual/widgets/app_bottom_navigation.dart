import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'auth_widgets.dart';

/// Item de navegação da bottom bar.
///
/// Aceita um ícone SVG (via [asset]) OU um ícone do Material (via [icon]).
/// Quando ambos são informados, o [asset] tem prioridade.
class AppNavItem {
  const AppNavItem({
    required this.label,
    this.asset,
    this.icon,
    required this.iconWidth,
    required this.iconHeight,
    this.selected = false,
    this.fontSize = 12,
    this.onTap,
  });

  final String label;
  final String? asset;
  final IconData? icon;
  final double iconWidth;
  final double iconHeight;
  final bool selected;
  final double fontSize;
  final void Function(BuildContext context)? onTap;
}

/// Bottom navigation compartilhada por Membro, Líder e Visitante.
///
/// Render único (mesma pílula ativa, mesmas proporções, mesmas fontes) para
/// garantir paridade visual entre as telas — evita a divergência de duplicar
/// constantes em cada tela. Cada tela apenas fornece a lista de [items] com o
/// respectivo `onTap`.
class AppBottomNavigation extends StatelessWidget {
  const AppBottomNavigation({
    super.key,
    required this.items,
    required this.scale,
    required this.bottomPadding,
  });

  static const _primary = Color(0xFF7A0022);
  static const _muted = Color(0xFF6B7280);
  static const _line = Color(0xFFE5E7EB);
  static const _soft = Color(0xFFF5E6EC);

  final List<AppNavItem> items;
  final double scale;
  final double bottomPadding;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72 * scale + bottomPadding,
      padding: EdgeInsets.fromLTRB(4 * scale, 0, 4 * scale, bottomPadding),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: _line)),
        boxShadow: [
          BoxShadow(
            color: Color(0x0D000000),
            offset: Offset(0, -1),
            blurRadius: 1,
          ),
        ],
      ),
      child: Row(
        children: [
          for (final item in items)
            Expanded(
              child: SizedBox(
                height: 56 * scale,
                child: _AppBottomNavigationItem(item: item, scale: scale),
              ),
            ),
        ],
      ),
    );
  }
}

class _AppBottomNavigationItem extends StatelessWidget {
  const _AppBottomNavigationItem({required this.item, required this.scale});

  final AppNavItem item;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final color = item.selected
        ? AppBottomNavigation._primary
        : AppBottomNavigation._muted;

    final icon = item.asset != null
        ? ColorFiltered(
            colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
            child: AuthAssetImage(
              item.asset!,
              width: item.iconWidth * scale,
              height: item.iconHeight * scale,
            ),
          )
        : Icon(item.icon, size: item.iconHeight * scale, color: color);

    final content = Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        icon,
        SizedBox(height: 2 * scale),
        SizedBox(
          width: 58 * scale,
          // O rótulo é legenda de ícone dentro de uma barra de altura fixa,
          // não texto de leitura. Deixá-lo crescer com a fonte do sistema
          // estourava a barra (~3 px em textScale 1.3) e cortava a navegação.
          // Todo o conteúdo de leitura do aplicativo continua respeitando a
          // ampliação escolhida pela pessoa; só esta legenda é fixada.
          child: MediaQuery.withNoTextScaling(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                item.label,
                maxLines: 1,
                style: GoogleFonts.inter(
                  fontSize: item.fontSize * scale,
                  fontWeight: FontWeight.w500,
                  height: item.fontSize == 11 ? 13 / 11 : 16.8 / 12,
                  color: color,
                  decoration: TextDecoration.none,
                ),
              ),
            ),
          ),
        ),
      ],
    );

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => item.onTap?.call(context),
      child: Center(
        child: item.selected
            ? Container(
                width: 53 * scale,
                height: 39 * scale,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppBottomNavigation._soft,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: content,
              )
            : SizedBox(
                height: 44.8 * scale,
                child: Center(child: content),
              ),
      ),
    );
  }
}
