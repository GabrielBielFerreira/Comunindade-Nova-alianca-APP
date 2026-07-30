import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../widgets/internal_header.dart';

/// Tela de Notificações (membro e liderança — idêntica para ambos).
///
/// Tela interna (push), sem bottom navigation. Estado vazio no protótipo.
class NotificacoesScreen extends StatelessWidget {
  const NotificacoesScreen({super.key});

  static const _designWidth = 394.0;
  static const _background = Color(0xFFFAFAFA);
  static const _muted = Color(0xFF6B7280);

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.white,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: _background,
        body: SafeArea(
          top: false,
          bottom: false,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final scale = (constraints.maxWidth / _designWidth)
                  .clamp(0.86, 1.0)
                  .toDouble();
              final topPadding = MediaQuery.paddingOf(context).top;

              return Column(
                children: [
                  InternalHeader(
                    title: 'Notificações',
                    scale: scale,
                    topPadding: topPadding,
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        'Nenhuma notificação',
                        style: GoogleFonts.inter(
                          fontSize: 16 * scale,
                          fontWeight: FontWeight.w400,
                          height: 24 / 16,
                          color: _muted,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
