import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../mock_data.dart';
import '../visual_router.dart';
import 'auth_widgets.dart';

enum LeaderNavItem {
  home,
  notices,
  schedule,
  prayer,
  contribute,
  profile,
  management,
}

class LeaderBottomNavigation extends StatelessWidget {
  const LeaderBottomNavigation({
    super.key,
    required this.activeItem,
    required this.scale,
    required this.bottomPadding,
  });

  static const _primary = Color(0xFF7A0022);
  static const _muted = Color(0xFF6B7280);
  static const _line = Color(0xFFE5E7EB);
  static const _soft = Color(0xFFF5E6EC);

  final LeaderNavItem activeItem;
  final double scale;
  final double bottomPadding;

  @override
  Widget build(BuildContext context) {
    final items = <_LeaderNavigationData>[
      _LeaderNavigationData(
        LeaderNavItem.home,
        'Início',
        asset: HomeAssets.home,
        width: 60.78,
        iconWidth: 16,
        iconHeight: 18,
        route: VisualRoutes.homeLeader,
      ),
      _LeaderNavigationData(
        LeaderNavItem.notices,
        'Avisos',
        asset: HomeAssets.notification,
        width: 46,
        iconWidth: 16,
        iconHeight: 20,
        fontSize: 11,
        route: VisualRoutes.avisosLeader,
      ),
      _LeaderNavigationData(
        LeaderNavItem.schedule,
        'Programação',
        asset: HomeAssets.schedule,
        width: 74,
        iconWidth: 16.5,
        iconHeight: 20.333,
        fontSize: 11,
        route: VisualRoutes.programacaoLeader,
      ),
      _LeaderNavigationData(
        LeaderNavItem.prayer,
        'Oração',
        asset: HomeAssets.prayer,
        width: 60.78,
        iconWidth: 20,
        iconHeight: 20,
        route: VisualRoutes.oracaoLeader,
      ),
      _LeaderNavigationData(
        LeaderNavItem.contribute,
        'Contribuir',
        asset: HomeAssets.contribute,
        width: 60,
        iconWidth: 18.333,
        iconHeight: 18.821,
        fontSize: 11,
        route: VisualRoutes.contribuirLeader,
      ),
      _LeaderNavigationData(
        LeaderNavItem.profile,
        'Perfil',
        asset: HomeAssets.profile,
        width: 34,
        iconWidth: 14.667,
        iconHeight: 16.667,
        route: VisualRoutes.perfilLeader,
      ),
      _LeaderNavigationData(
        LeaderNavItem.management,
        'Gestão',
        asset: HomeAssets.management,
        width: 50,
        iconWidth: 18,
        iconHeight: 20,
        route: VisualRoutes.gestao,
      ),
    ];

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
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SizedBox(
                    height: 56 * scale,
                    child: _LeaderBottomNavigationItem(
                      item: item,
                      scale: scale,
                      selected: item.item == activeItem,
                      maxWidth: constraints.maxWidth,
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _LeaderBottomNavigationItem extends StatelessWidget {
  const _LeaderBottomNavigationItem({
    required this.item,
    required this.scale,
    required this.selected,
    required this.maxWidth,
  });

  final _LeaderNavigationData item;
  final double scale;
  final bool selected;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final color = selected
        ? LeaderBottomNavigation._primary
        : LeaderBottomNavigation._muted;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        if (item.route == null) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              const SnackBar(
                content: Text('Seção indisponível.'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          return;
        }

        if (ModalRoute.of(context)?.settings.name == item.route) {
          return;
        }

        Navigator.pushNamed(context, item.route!);
      },
      child: Center(child: _navigationContent(color)),
    );
  }

  Widget _navigationContent(Color color) {
    final labelWidth = (selected ? maxWidth : maxWidth - 4 * scale)
        .clamp(28 * scale, 90 * scale)
        .toDouble();

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
        SizedBox(
          width: labelWidth,
          // Legenda de ícone em barra de altura fixa — ver
          // app_bottom_navigation.dart. O conteúdo de leitura do aplicativo
          // continua respeitando a ampliação de fonte do sistema.
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

    if (!selected) {
      return SizedBox(
        height: 44.8 * scale,
        child: Center(child: content),
      );
    }

    return Container(
      width: maxWidth,
      height: 39 * scale,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: LeaderBottomNavigation._soft,
        borderRadius: BorderRadius.circular(999),
      ),
      child: content,
    );
  }
}

class _LeaderNavigationData {
  const _LeaderNavigationData(
    this.item,
    this.label, {
    required this.width,
    required this.iconWidth,
    required this.iconHeight,
    required this.asset,
    this.route,
    this.fontSize = 12,
  });

  final LeaderNavItem item;
  final String label;
  final double width;
  final double iconWidth;
  final double iconHeight;
  final String asset;
  final String? route;
  final double fontSize;
}
