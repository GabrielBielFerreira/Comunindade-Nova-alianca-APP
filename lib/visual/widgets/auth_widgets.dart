import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

import '../mock_data.dart';
import '../escala_tela.dart';

class AuthColors {
  const AuthColors._();

  static const primary = Color(0xFF7A0022);
  static const background = Color(0xFFF9F9F9);
  static const white = Color(0xFFFFFFFF);
  static const title = Color(0xFF1A1A1A);
  static const nearBlack = Color(0xFF1A1C1C);
  static const formLabel = Color(0xFF584142);
  static const muted = Color(0xFF6B7280);
  static const mutedAlt = Color(0xFF7E8490);
  static const linkAlt = Color(0xFF8B203E);
  static const border = Color(0xFFE5E7EB);
  static const soft = Color(0xFFF5E6EC);
  static const headerSubtitle = Color(0xFFFFB2B7);
}

double authScaleFor(BuildContext context, double referenceWidth) {
  final width = MediaQuery.sizeOf(context).width;
  final effectiveWidth = width > referenceWidth ? referenceWidth : width;
  return (effectiveWidth / referenceWidth).clamp(escalaMinima, 1.0);
}

class AuthCanvas extends StatelessWidget {
  const AuthCanvas({
    super.key,
    required this.referenceWidth,
    required this.minHeight,
    required this.child,
    this.backgroundColor = AuthColors.background,
  });

  final double referenceWidth;
  final double minHeight;
  final Widget child;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        top: false,
        bottom: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final contentMinHeight = minHeight > constraints.maxHeight
                ? minHeight
                : constraints.maxHeight;

            return SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minWidth: constraints.maxWidth,
                  minHeight: contentMinHeight,
                ),
                child: SizedBox(width: constraints.maxWidth, child: child),
              ),
            );
          },
        ),
      ),
    );
  }
}

class AuthHeroHeader extends StatelessWidget {
  const AuthHeroHeader({
    super.key,
    required this.height,
    required this.title,
    required this.subtitle,
    required this.scale,
  });

  final double height;
  final String title;
  final String subtitle;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height * scale,
      width: double.infinity,
      color: AuthColors.primary,
      padding: EdgeInsets.only(top: 48 * scale),
      child: Column(
        children: [
          Container(
            width: 96 * scale,
            height: 96 * scale,
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  offset: Offset(0, 2 * scale),
                  blurRadius: 2 * scale,
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.07),
                  offset: Offset(0, 4 * scale),
                  blurRadius: 3 * scale,
                ),
              ],
            ),
            child: Image.asset(
              AuthAssets.logo,
              fit: BoxFit.cover,
              errorBuilder: (_, error, stackTrace) => const SizedBox.shrink(),
            ),
          ),
          SizedBox(height: 23.9 * scale),
          Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.montserrat(
              fontSize: 24 * scale,
              fontWeight: FontWeight.w700,
              height: 1.2,
              letterSpacing: -0.6 * scale,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 8 * scale),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 14 * scale,
              fontWeight: FontWeight.w400,
              height: 1.5,
              color: AuthColors.headerSubtitle,
            ),
          ),
        ],
      ),
    );
  }
}

class AuthInputField extends StatelessWidget {
  const AuthInputField({
    super.key,
    required this.label,
    required this.hint,
    required this.iconAsset,
    required this.scale,
    this.controller,
    this.trailingIconAsset,
    this.keyboardType,
    this.textInputAction,
    this.obscureText = false,
    this.onTrailingTap,
    this.onFieldSubmitted,
    this.radius = 8,
    this.iconWidth = 16,
    this.iconHeight = 16,
    this.trailingWidth = 18,
    this.trailingHeight = 14,
    this.leftPadding = 45,
    this.rightPadding = 17,
    this.labelColor = AuthColors.formLabel,
  });

  final String label;
  final String hint;
  final String iconAsset;
  final TextEditingController? controller;
  final String? trailingIconAsset;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool obscureText;
  final VoidCallback? onTrailingTap;
  final ValueChanged<String>? onFieldSubmitted;
  final double scale;
  final double radius;
  final double iconWidth;
  final double iconHeight;
  final double trailingWidth;
  final double trailingHeight;
  final double leftPadding;
  final double rightPadding;
  final Color labelColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: 4 * scale),
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 14 * scale,
              fontWeight: FontWeight.w500,
              height: 1.4,
              color: labelColor,
            ),
          ),
        ),
        SizedBox(height: 8 * scale),
        Container(
          height: 52 * scale,
          decoration: BoxDecoration(
            color: AuthColors.white,
            border: Border.all(color: AuthColors.border),
            borderRadius: BorderRadius.circular(radius * scale),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                offset: Offset(0, 1 * scale),
                blurRadius: 2 * scale,
              ),
            ],
          ),
          child: Row(
            children: [
              SizedBox(width: 16 * scale),
              SizedBox(
                width: iconWidth * scale,
                height: iconHeight * scale,
                child: AuthAssetImage(
                  iconAsset,
                  width: iconWidth * scale,
                  height: iconHeight * scale,
                ),
              ),
              SizedBox(width: (leftPadding - 16 - iconWidth) * scale),
              Expanded(
                child: controller == null
                    ? Text(
                        hint,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 16 * scale,
                          fontWeight: FontWeight.w400,
                          color: AuthColors.muted,
                        ),
                      )
                    : TextFormField(
                        controller: controller,
                        keyboardType: keyboardType,
                        textInputAction: textInputAction,
                        obscureText: obscureText,
                        enableSuggestions: !obscureText,
                        autocorrect: !obscureText,
                        onFieldSubmitted: onFieldSubmitted,
                        cursorColor: AuthColors.primary,
                        style: GoogleFonts.inter(
                          fontSize: 16 * scale,
                          fontWeight: FontWeight.w400,
                          color: AuthColors.nearBlack,
                        ),
                        decoration: InputDecoration(
                          hintText: hint,
                          hintStyle: GoogleFonts.inter(
                            fontSize: 16 * scale,
                            fontWeight: FontWeight.w400,
                            color: AuthColors.muted,
                          ),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
              ),
              if (trailingIconAsset != null) ...[
                SizedBox(width: 12 * scale),
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: onTrailingTap,
                  child: SizedBox(
                    width: trailingWidth * scale,
                    height: trailingHeight * scale,
                    child: AuthAssetImage(
                      trailingIconAsset!,
                      width: trailingWidth * scale,
                      height: trailingHeight * scale,
                    ),
                  ),
                ),
                SizedBox(width: rightPadding * scale),
              ] else
                SizedBox(width: rightPadding * scale),
            ],
          ),
        ),
      ],
    );
  }
}

class AuthPrimaryButton extends StatelessWidget {
  const AuthPrimaryButton({
    super.key,
    required this.text,
    required this.scale,
    this.onTap,
    this.iconAsset,
    this.radius = 12,
    this.fontFamily = AuthButtonFont.inter,
    this.width,
    this.shadow = true,
  });

  final String text;
  final double scale;
  final VoidCallback? onTap;
  final String? iconAsset;
  final double radius;
  final AuthButtonFont fontFamily;
  final double? width;
  final bool shadow;

  @override
  Widget build(BuildContext context) {
    final style = fontFamily == AuthButtonFont.montserrat
        ? GoogleFonts.montserrat(
            fontSize: 12 * scale,
            fontWeight: FontWeight.w700,
            height: 1.4,
            letterSpacing: 1.2 * scale,
            color: Colors.white,
          )
        : GoogleFonts.inter(
            fontSize: 14 * scale,
            fontWeight: FontWeight.w700,
            height: 20 / 14,
            letterSpacing: 1.4 * scale,
            color: Colors.white,
          );

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width == null ? double.infinity : width! * scale,
        height: 52 * scale,
        decoration: BoxDecoration(
          color: AuthColors.primary,
          borderRadius: BorderRadius.circular(radius * scale),
          boxShadow: shadow
              ? [
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
                ]
              : null,
        ),
        // FittedBox: a altura do botao e fixa (52 * scale) e a largura vem do
        // desenho. Com a fonte do sistema ampliada o rotulo passava da caixa e
        // era CORTADO. Encolher o conjunto mantem a palavra inteira legivel,
        // que e melhor que reticencias no meio de um botao.
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(text, style: style),
              if (iconAsset != null) ...[
                SizedBox(width: 8 * scale),
                SizedBox(
                  width: 12 * scale,
                  height: 12 * scale,
                  child: AuthAssetImage(
                    iconAsset!,
                    width: 12 * scale,
                    height: 12 * scale,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

enum AuthButtonFont { inter, montserrat }

class AuthAssetImage extends StatelessWidget {
  const AuthAssetImage(
    this.asset, {
    super.key,
    required this.width,
    required this.height,
    this.fit = BoxFit.contain,
  });

  final String asset;
  final double width;
  final double height;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    if (asset.toLowerCase().endsWith('.svg')) {
      return SvgPicture.asset(asset, width: width, height: height, fit: fit);
    }

    return Image.asset(
      asset,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (_, error, stackTrace) => const SizedBox.shrink(),
    );
  }
}
