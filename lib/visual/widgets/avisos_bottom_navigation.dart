import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../mock_data.dart';
import '../visual_router.dart';
import 'auth_widgets.dart';

class MemberAvisosBottomNavigation extends StatelessWidget {
  const MemberAvisosBottomNavigation({
    super.key,
    required this.scale,
    required this.bottomPadding,
  });

  static const _primary = Color(0xFF7A0022);
  static const _muted = Color(0xFF6B7280);
  static const _line = Color(0xFFE5E7EB);
  static const _soft = Color(0xFFF5E6EC);

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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          for (final item in HomeMockData.bottomNavigation)
            SizedBox(
              width: item.width * scale,
              height: 56 * scale,
              child: _MemberAvisosNavigationItem(
                item: item,
                scale: scale,
                selected: item.label == 'Avisos',
              ),
            ),
        ],
      ),
    );
  }
}

class _MemberAvisosNavigationItem extends StatelessWidget {
  const _MemberAvisosNavigationItem({
    required this.item,
    required this.scale,
    required this.selected,
  });

  final HomeBottomNavigationData item;
  final double scale;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final color = selected
        ? MemberAvisosBottomNavigation._primary
        : MemberAvisosBottomNavigation._muted;
    final content = Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ColorFiltered(
          colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
          child: AuthAssetImage(
            item.asset,
            width: item.iconWidth * scale,
            height: item.iconHeight * scale,
          ),
        ),
        SizedBox(height: 2 * scale),
        Text(
          item.label,
          maxLines: 1,
          style: GoogleFonts.inter(
            fontSize: item.fontSize * scale,
            fontWeight: FontWeight.w500,
            height: item.fontSize == 11 ? 13 / 11 : 16.8 / 12,
            color: color,
          ),
        ),
      ],
    );

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        if (selected) {
          return;
        }

        if (item.label == 'Início') {
          Navigator.pushNamedAndRemoveUntil(
            context,
            VisualRoutes.entraconta,
            (route) => false,
          );
          return;
        }

        if (item.label == 'Programação') {
          Navigator.pushNamed(context, VisualRoutes.programacao);
          return;
        }

        if (item.label == 'Oração') {
          Navigator.pushNamed(context, VisualRoutes.oracao);
          return;
        }

        if (item.label == 'Contribuir') {
          Navigator.pushNamed(context, VisualRoutes.contribuir);
          return;
        }

        if (item.asset == HomeAssets.profile) {
          Navigator.pushNamed(context, VisualRoutes.perfil);
          return;
        }

        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(
              content: Text('Seção indisponível.'),
              behavior: SnackBarBehavior.floating,
            ),
          );
      },
      child: Center(
        child: selected
            ? Container(
                width: 53 * scale,
                height: 39 * scale,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: MemberAvisosBottomNavigation._soft,
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
