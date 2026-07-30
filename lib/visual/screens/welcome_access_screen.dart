import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../mock_data.dart';
import '../visual_router.dart';
import '../widgets/auth_widgets.dart';

class WelcomeAccessScreen extends StatefulWidget {
  const WelcomeAccessScreen({super.key});

  @override
  State<WelcomeAccessScreen> createState() => _WelcomeAccessScreenState();
}

class _WelcomeAccessScreenState extends State<WelcomeAccessScreen> {
  static const _designWidth = 390.0;
  static const _designHeight = 844.0;
  static const _topHeight = 337.59;
  static const _cardOverlap = 40.59;

  bool _acceptedTerms = true;

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: AuthColors.primary,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: AuthColors.primary,
        body: SafeArea(
          top: false,
          bottom: false,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final height = constraints.maxHeight;
              final scale = (math.min(width, _designWidth) / _designWidth)
                  .clamp(0.86, 1.0)
                  .toDouble();
              final heightScale = (height / _designHeight)
                  .clamp(0.92, 1.08)
                  .toDouble();
              final topHeight = _topHeight * heightScale;
              final bottomPadding = MediaQuery.paddingOf(context).bottom;

              return Stack(
                children: [
                  Positioned.fill(child: Container(color: AuthColors.primary)),
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    height: topHeight,
                    child: _WelcomeHero(scale: scale),
                  ),
                  Positioned(
                    top: topHeight - (_cardOverlap * scale),
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: _WelcomeCard(
                      scale: scale,
                      bottomPadding: bottomPadding,
                      acceptedTerms: _acceptedTerms,
                      onToggleAccepted: () {
                        setState(() => _acceptedTerms = !_acceptedTerms);
                      },
                      onLogin: () {
                        if (!_acceptedTerms) {
                          _showTermsMessage();
                          return;
                        }
                        Navigator.of(context).pushNamed(VisualRoutes.login);
                      },
                      onContinue: () {
                        if (!_acceptedTerms) {
                          _showTermsMessage();
                          return;
                        }
                        Navigator.of(
                          context,
                        ).pushNamed(VisualRoutes.visitorHome);
                      },
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

  void _showTermsMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(WelcomeAccessMockData.acceptTermsMessage),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class _WelcomeHero extends StatelessWidget {
  const _WelcomeHero({required this.scale});

  final double scale;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AuthColors.primary,
      padding: EdgeInsets.only(bottom: 48 * scale),
      alignment: Alignment.center,
      child: Container(
        width: 112 * scale,
        height: 112 * scale,
        padding: EdgeInsets.all(4 * scale),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: AuthColors.primary, width: 4 * scale),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.10),
              offset: Offset(0, 10 * scale),
              blurRadius: 15 * scale,
              spreadRadius: -3 * scale,
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.10),
              offset: Offset(0, 4 * scale),
              blurRadius: 6 * scale,
              spreadRadius: -4 * scale,
            ),
          ],
        ),
        child: ClipOval(
          child: Image.asset(
            WelcomeAssets.logo,
            fit: BoxFit.cover,
            errorBuilder: (_, error, stackTrace) =>
                Image.asset(AuthAssets.logo, fit: BoxFit.cover),
          ),
        ),
      ),
    );
  }
}

class _WelcomeCard extends StatelessWidget {
  const _WelcomeCard({
    required this.scale,
    required this.bottomPadding,
    required this.acceptedTerms,
    required this.onToggleAccepted,
    required this.onLogin,
    required this.onContinue,
  });

  final double scale;
  final double bottomPadding;
  final bool acceptedTerms;
  final VoidCallback onToggleAccepted;
  final VoidCallback onLogin;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(40 * scale)),
      ),
      child: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: MediaQuery.sizeOf(context).height * 0.58 + bottomPadding,
          ),
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              32 * scale,
              50.895 * scale,
              32 * scale,
              (40 * scale) + bottomPadding,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  WelcomeAccessMockData.title,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.montserrat(
                    fontSize: 32 * scale,
                    fontWeight: FontWeight.w700,
                    height: 38.4 / 32,
                    letterSpacing: -0.8 * scale,
                    color: const Color(0xFF111827),
                  ),
                ),
                SizedBox(height: 31 * scale),
                _ConsentRow(
                  scale: scale,
                  acceptedTerms: acceptedTerms,
                  onTap: onToggleAccepted,
                ),
                SizedBox(height: 32 * scale),
                _WelcomeButton(
                  text: WelcomeAccessMockData.login,
                  scale: scale,
                  onTap: onLogin,
                ),
                SizedBox(height: 16 * scale),
                _WelcomeButton(
                  text: WelcomeAccessMockData.continueWithoutLogin,
                  scale: scale,
                  onTap: onContinue,
                  outlined: true,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ConsentRow extends StatelessWidget {
  const _ConsentRow({
    required this.scale,
    required this.acceptedTerms,
    required this.onTap,
  });

  final double scale;
  final bool acceptedTerms;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24 * scale,
            height: 24 * scale,
            decoration: BoxDecoration(
              color: acceptedTerms ? AuthColors.primary : Colors.white,
              border: Border.all(
                color: acceptedTerms ? Colors.transparent : AuthColors.primary,
              ),
              borderRadius: BorderRadius.circular(4 * scale),
            ),
            child: acceptedTerms
                ? Center(
                    child: AuthAssetImage(
                      WelcomeAssets.check,
                      width: 22 * scale,
                      height: 22 * scale,
                    ),
                  )
                : null,
          ),
          SizedBox(width: 10 * scale),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: GoogleFonts.inter(
                  fontSize: 15 * scale,
                  fontWeight: FontWeight.w500,
                  height: 20.63 / 15,
                  color: const Color(0xFF374151),
                ),
                children: [
                  const TextSpan(text: WelcomeAccessMockData.consentPrefix),
                  _linkSpan(WelcomeAccessMockData.privacyPolicy, scale),
                  const TextSpan(text: WelcomeAccessMockData.consentMiddle),
                  _linkSpan(WelcomeAccessMockData.terms, scale),
                  const TextSpan(text: '.'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  TextSpan _linkSpan(String text, double scale) {
    return TextSpan(
      text: text,
      style: GoogleFonts.inter(
        fontSize: 15 * scale,
        fontWeight: FontWeight.w600,
        height: 20.63 / 15,
        color: AuthColors.primary,
        decoration: TextDecoration.underline,
        decorationColor: AuthColors.primary,
      ),
    );
  }
}

class _WelcomeButton extends StatelessWidget {
  const _WelcomeButton({
    required this.text,
    required this.scale,
    required this.onTap,
    this.outlined = false,
  });

  final String text;
  final double scale;
  final VoidCallback onTap;
  final bool outlined;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 61.5 * scale,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: outlined ? Colors.white : AuthColors.primary,
          border: outlined
              ? Border.all(color: AuthColors.primary, width: 2 * scale)
              : null,
          borderRadius: BorderRadius.circular(12 * scale),
          boxShadow: outlined
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    offset: Offset(0, 1 * scale),
                    blurRadius: 1 * scale,
                  ),
                ],
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 17 * scale,
            fontWeight: FontWeight.w700,
            height: 25.5 / 17,
            letterSpacing: 0.425 * scale,
            color: outlined ? AuthColors.primary : Colors.white,
          ),
        ),
      ),
    );
  }
}

class VisitorHomePlaceholderScreen extends StatelessWidget {
  const VisitorHomePlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AuthColors.background,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                WelcomeAccessMockData.visitorTitle,
                style: GoogleFonts.montserrat(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: AuthColors.nearBlack,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                WelcomeAccessMockData.visitorBody,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: AuthColors.muted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
