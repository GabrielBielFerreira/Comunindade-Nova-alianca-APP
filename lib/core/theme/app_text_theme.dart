import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTextTheme {
  AppTextTheme._();

  // Display — Montserrat Black, UPPERCASE, impacto máximo
  static TextStyle get display => GoogleFonts.montserrat(
        fontSize: 36,
        fontWeight: FontWeight.w900,
        height: 1.1,
        letterSpacing: -0.72,
        color: AppColors.foreground,
      );

  // H1 — Montserrat Bold, UPPERCASE
  static TextStyle get h1 => GoogleFonts.montserrat(
        fontSize: 30,
        fontWeight: FontWeight.w700,
        height: 1.2,
        letterSpacing: -0.3,
        color: AppColors.foreground,
      );

  // H2 — Montserrat Bold, UPPERCASE
  static TextStyle get h2 => GoogleFonts.montserrat(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        height: 1.3,
        color: AppColors.foreground,
      );

  // H3 — Montserrat Semibold
  static TextStyle get h3 => GoogleFonts.montserrat(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        height: 1.4,
        color: AppColors.foreground,
      );

  // Body — Inter Regular
  static TextStyle get body => GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 1.6,
        color: AppColors.foreground,
      );

  // Body Small
  static TextStyle get bodySm => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.5,
        color: AppColors.foreground,
      );

  // Label — Inter Medium
  static TextStyle get label => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        height: 1.4,
        color: AppColors.foreground,
      );

  // Label Caps — Montserrat Bold UPPERCASE com tracking largo
  static TextStyle get labelCaps => GoogleFonts.montserrat(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        height: 1.4,
        letterSpacing: 2.16,
        color: AppColors.foreground,
      );

  // Caption — timestamps, metadados
  static TextStyle get caption => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        height: 1.4,
        color: AppColors.mutedForeground,
      );
}
