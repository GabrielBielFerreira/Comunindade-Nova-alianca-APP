import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../visual_router.dart';
import '../widgets/visitor_bottom_navigation.dart';
import 'home_screen.dart';

/// Home do Visitante (usuário NÃO logado).
///
/// Reaproveita 100% da base visual da [HomeScreen] (header, card "Palavra do
/// Dia", grid de Acesso Rápido, cores e tipografia), alterando apenas o que a
/// variante visitante exige: saudação, ausência do card de escalas, bottom nav
/// própria e o comportamento do card "Mural de oração" (dialog de login).
class HomeVisitanteScreen extends StatelessWidget {
  const HomeVisitanteScreen({super.key});

  static const _primary = Color(0xFF7A0022);
  static const _title = Color(0xFF1A1A1A);
  static const _body = Color(0xFF584142);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final scale = (constraints.maxWidth / 394).clamp(0.86, 1.0).toDouble();
        final bottomPadding = MediaQuery.paddingOf(context).bottom;

        return Stack(
          children: [
            HomeScreen(
              greeting: 'SEJA BEM-VINDO(A)',
              greetingSubtitle: 'Um lugar para viver fé, comunhão e propósito.',
              showSecondaryCard: false,
              showBottomNavigation: false,
              onMuralTap: _showMuralLoginDialog,
              onContribuirCardTap: (context) => Navigator.pushNamed(
                context,
                VisualRoutes.contribuirVisitante,
              ),
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

  void _showMuralLoginDialog(BuildContext context) {
    _showLoginDialog(
      context,
      title: 'Mural de Oração',
      message:
          'Para acessar o Mural de Oração, faça login ou crie sua conta.',
    );
  }

  void _showLoginDialog(
    BuildContext context, {
    required String title,
    required String message,
  }) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.montserrat(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    height: 27 / 18,
                    color: _title,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  message,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    height: 21 / 14,
                    color: _body,
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(dialogContext).pop();
                      Navigator.pushNamed(context, VisualRoutes.entraconta);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Entrar',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    style: TextButton.styleFrom(
                      foregroundColor: _body,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(
                      'Cancelar',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
