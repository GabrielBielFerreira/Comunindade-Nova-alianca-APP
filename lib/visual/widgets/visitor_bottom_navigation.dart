import 'package:flutter/material.dart';

import '../mock_data.dart';
import '../visual_router.dart';
import 'app_bottom_navigation.dart';

enum VisitorNavItem { home, conhecer, schedule, contribute, entrar }

/// Bottom navigation da Home do Visitante e demais telas do visitante.
///
/// Usa a mesma [AppBottomNavigation] do membro/gestão (paridade visual
/// garantida), fornecendo os 5 itens do visitante: Início / Conhecer /
/// Programação / Contribuir / Entrar. Reaproveita os SVGs de [HomeAssets]
/// quando existem; "Conhecer" e "Entrar" usam ícones do Material.
///
/// Cada item aponta para as **rotas exclusivas do visitante** (padrão igual ao
/// da liderança com `LeaderBottomNavigation`), mantendo o visitante sempre
/// dentro da sua própria navegação — sem cair na área do membro logado.
class VisitorBottomNavigation extends StatelessWidget {
  const VisitorBottomNavigation({
    super.key,
    required this.scale,
    required this.bottomPadding,
    this.activeItem = VisitorNavItem.home,
  });

  final double scale;
  final double bottomPadding;
  final VisitorNavItem activeItem;

  @override
  Widget build(BuildContext context) {
    final items = <AppNavItem>[
      AppNavItem(
        label: 'Início',
        asset: HomeAssets.home,
        iconWidth: 16,
        iconHeight: 18,
        selected: activeItem == VisitorNavItem.home,
        onTap: (context) => _go(context, VisualRoutes.visitorHome),
      ),
      AppNavItem(
        label: 'Conhecer',
        icon: Icons.church,
        iconWidth: 24,
        iconHeight: 24,
        fontSize: 11,
        selected: activeItem == VisitorNavItem.conhecer,
        onTap: (context) => _go(context, VisualRoutes.conhecerVisitante),
      ),
      AppNavItem(
        label: 'Programação',
        asset: HomeAssets.schedule,
        iconWidth: 16.5,
        iconHeight: 20.333,
        fontSize: 11,
        selected: activeItem == VisitorNavItem.schedule,
        onTap: (context) => _go(context, VisualRoutes.programacaoVisitante),
      ),
      AppNavItem(
        label: 'Contribuir',
        asset: HomeAssets.contribute,
        iconWidth: 18.333,
        iconHeight: 18.821,
        fontSize: 11,
        selected: activeItem == VisitorNavItem.contribute,
        onTap: (context) => _go(context, VisualRoutes.contribuirVisitante),
      ),
      AppNavItem(
        label: 'Entrar',
        icon: Icons.person_outline,
        iconWidth: 24,
        iconHeight: 24,
        selected: activeItem == VisitorNavItem.entrar,
        onTap: (context) => Navigator.pushNamed(context, VisualRoutes.entraconta),
      ),
    ];

    return AppBottomNavigation(
      items: items,
      scale: scale,
      bottomPadding: bottomPadding,
    );
  }

  void _go(BuildContext context, String route) {
    if (ModalRoute.of(context)?.settings.name == route) {
      return;
    }
    Navigator.pushNamed(context, route);
  }
}
