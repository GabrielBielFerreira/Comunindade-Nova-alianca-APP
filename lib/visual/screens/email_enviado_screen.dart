import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../mock_data.dart';
import '../visual_router.dart';
import '../widgets/auth_widgets.dart';

class EmailEnviadoScreen extends StatelessWidget {
  const EmailEnviadoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scale = authScaleFor(context, 390);
    final frameHeight = math.max(
      MediaQuery.sizeOf(context).height,
      821 * scale,
    );
    final cardTop = (312 - 28) * scale;

    return AuthCanvas(
      referenceWidth: 390,
      minHeight: frameHeight,
      backgroundColor: AuthColors.white,
      child: SizedBox(
        height: frameHeight,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: AuthHeroHeader(
                height: 312,
                title: EmailEnviadoMockData.headerTitle,
                subtitle: EmailEnviadoMockData.subtitle,
                scale: scale,
              ),
            ),
            Positioned(
              top: cardTop,
              left: 0,
              right: 0,
              bottom: 0,
              child: _EmailSentCard(scale: scale),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmailSentCard extends StatelessWidget {
  const _EmailSentCard({required this.scale});

  final double scale;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        16 * scale,
        32 * scale,
        16 * scale,
        32 * scale,
      ),
      decoration: BoxDecoration(
        color: AuthColors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(12 * scale),
          topRight: Radius.circular(12 * scale),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            offset: Offset(0, -4 * scale),
            blurRadius: 24 * scale,
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 80 * scale,
            height: 80 * scale,
            decoration: const BoxDecoration(
              color: AuthColors.soft,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: SizedBox(
              width: 35 * scale,
              height: 30 * scale,
              child: AuthAssetImage(
                AuthAssets.emailEnviado,
                width: 35 * scale,
                height: 30 * scale,
              ),
            ),
          ),
          SizedBox(height: 24 * scale),
          Text(
            EmailEnviadoMockData.title,
            textAlign: TextAlign.center,
            style: GoogleFonts.montserrat(
              fontSize: 24 * scale,
              fontWeight: FontWeight.w700,
              height: 1.2,
              color: AuthColors.title,
            ),
          ),
          SizedBox(height: 8 * scale),
          Text(
            EmailEnviadoMockData.description,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 14 * scale,
              fontWeight: FontWeight.w400,
              height: 1.5,
              color: AuthColors.muted,
            ),
          ),
          SizedBox(height: 24 * scale),
          AuthPrimaryButton(
            text: EmailEnviadoMockData.backToLogin,
            scale: scale,
            radius: 8,
            shadow: true,
            onTap: () => Navigator.pushNamedAndRemoveUntil(
              context,
              VisualRoutes.entraconta,
              (route) => false,
            ),
          ),
          SizedBox(height: 16 * scale),
          GestureDetector(
            onTap: () => Navigator.pushNamedAndRemoveUntil(
              context,
              VisualRoutes.recuperarSenha,
              (route) => route.settings.name == VisualRoutes.entraconta,
            ),
            // Wrap, e nao Row: as duas frases nao cabem numa linha so em 320 px
            // com a fonte do sistema ampliada, e o link "Tentar novamente"
            // ficava cortado — justo o que a pessoa precisa tocar.
            child: Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 4,
              children: [
                Text(
                  EmailEnviadoMockData.notReceived,
                  style: GoogleFonts.inter(
                    fontSize: 14 * scale,
                    fontWeight: FontWeight.w500,
                    height: 1.4,
                    color: AuthColors.mutedAlt,
                  ),
                ),
                Text(
                  EmailEnviadoMockData.tryAgain,
                  style: GoogleFonts.inter(
                    fontSize: 14 * scale,
                    fontWeight: FontWeight.w500,
                    height: 1.4,
                    color: AuthColors.linkAlt,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
