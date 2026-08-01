import 'package:flutter/material.dart';

import '../visual_router.dart';
import '../widgets/visitor_bottom_navigation.dart';
import 'home_screen.dart';

/// Home do Visitante (usuário NÃO logado). Reaproveita a [HomeScreen] com
/// saudação de visitante e a bottom navigation do visitante. Os atalhos que
/// exigem conta (Meu Ministério, Mural) mostram estado apropriado ao serem
/// abertos sem login.
class HomeVisitanteScreen extends StatelessWidget {
  const HomeVisitanteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final scale = (constraints.maxWidth / 394).clamp(0.86, 1.0).toDouble();
        final bottomPadding = MediaQuery.paddingOf(context).bottom;

        return Stack(
          children: [
            const HomeScreen(
              greeting: 'SEJA BEM-VINDO(A)',
              greetingSubtitle: 'Um lugar para viver fé, comunhão e propósito.',
              showSecondaryCard: false,
              showBottomNavigation: false,
              // Visitante pode enviar pedido de oração sem login (vai à
              // moderação). O atalho "Mural de Oração" abre o formulário.
              muralRoute: VisualRoutes.oracaoNovoPedido,
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: VisitorBottomNavigation(
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
