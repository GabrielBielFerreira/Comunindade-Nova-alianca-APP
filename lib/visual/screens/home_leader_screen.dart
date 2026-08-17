import 'package:flutter/material.dart';

import '../mock_data.dart';
import '../visual_router.dart';
import '../widgets/leader_bottom_navigation.dart';
import 'home_screen.dart';
import '../escala_tela.dart';

class HomeLeaderScreen extends StatelessWidget {
  const HomeLeaderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final scale = (constraints.maxWidth / 394).clamp(escalaMinima, 1.0).toDouble();
        final bottomPadding = MediaQuery.paddingOf(context).bottom;

        return Stack(
          children: [
            const HomeScreen(
              secondaryCardLabel: HomeMockData.leaderMinistryLabel,
              showBottomNavigation: false,
              muralRoute: VisualRoutes.muralOracaoLeader,
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: LeaderBottomNavigation(
                activeItem: LeaderNavItem.home,
                scale: scale,
                bottomPadding: bottomPadding,
              ),
            ),
          ],
        );
      },
    );
  }
}
