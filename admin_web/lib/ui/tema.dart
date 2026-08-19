import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Identidade visual do painel — a mesma da gestão do aplicativo.
class Cores {
  const Cores._();

  static const primary = Color(0xFF7A0022);
  static const primaryDark = Color(0xFF510014);
  static const soft = Color(0xFFF5E6EC);
  static const background = Color(0xFFFAFAFA);
  static const surface = Colors.white;
  static const titulo = Color(0xFF1A1A1A);
  static const corpo = Color(0xFF584142);
  static const muted = Color(0xFF6B7280);
  static const line = Color(0xFFE5E7EB);

  static const sucesso = Color(0xFF15803D);
  static const alerta = Color(0xFFB45309);
  static const erro = Color(0xFFB91C1C);
  static const info = Color(0xFF1D4ED8);
}

/// Larguras de referência para a navegação responsiva.
class Breakpoints {
  const Breakpoints._();

  /// A partir daqui a barra lateral fica fixa.
  static const double desktop = 1100;

  /// Entre [tablet] e [desktop] a barra vira rail compacto.
  static const double tablet = 760;

  /// Largura da barra lateral em desktop.
  static const double sidebar = 268;
}

/// Montserrat nos títulos, Inter no conteúdo — igual ao aplicativo.
class TemaPainel {
  const TemaPainel._();

  static ThemeData claro() {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Cores.primary,
        primary: Cores.primary,
        brightness: Brightness.light,
        surface: Cores.surface,
      ),
      scaffoldBackgroundColor: Cores.background,
    );

    final textTheme = base.textTheme;

    return base.copyWith(
      textTheme: textTheme.copyWith(
        displayLarge: GoogleFonts.montserrat(textStyle: textTheme.displayLarge),
        displayMedium:
            GoogleFonts.montserrat(textStyle: textTheme.displayMedium),
        displaySmall: GoogleFonts.montserrat(textStyle: textTheme.displaySmall),
        headlineLarge: GoogleFonts.montserrat(
          textStyle: textTheme.headlineLarge,
          fontWeight: FontWeight.w700,
          color: Cores.titulo,
        ),
        headlineMedium: GoogleFonts.montserrat(
          textStyle: textTheme.headlineMedium,
          fontWeight: FontWeight.w700,
          color: Cores.titulo,
        ),
        headlineSmall: GoogleFonts.montserrat(
          textStyle: textTheme.headlineSmall,
          fontWeight: FontWeight.w700,
          color: Cores.titulo,
        ),
        titleLarge: GoogleFonts.montserrat(
          textStyle: textTheme.titleLarge,
          fontWeight: FontWeight.w700,
          color: Cores.titulo,
        ),
        titleMedium: GoogleFonts.inter(
          textStyle: textTheme.titleMedium,
          fontWeight: FontWeight.w600,
          color: Cores.titulo,
        ),
        titleSmall: GoogleFonts.inter(textStyle: textTheme.titleSmall),
        bodyLarge: GoogleFonts.inter(textStyle: textTheme.bodyLarge),
        bodyMedium: GoogleFonts.inter(
          textStyle: textTheme.bodyMedium,
          color: Cores.corpo,
        ),
        bodySmall: GoogleFonts.inter(
          textStyle: textTheme.bodySmall,
          color: Cores.muted,
        ),
        labelLarge: GoogleFonts.inter(
          textStyle: textTheme.labelLarge,
          fontWeight: FontWeight.w600,
        ),
        labelMedium: GoogleFonts.inter(textStyle: textTheme.labelMedium),
        labelSmall: GoogleFonts.inter(textStyle: textTheme.labelSmall),
      ),
      cardTheme: CardThemeData(
        color: Cores.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: Cores.line),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Cores.surface,
        foregroundColor: Cores.titulo,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      dividerTheme: const DividerThemeData(color: Cores.line, space: 1),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Cores.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Cores.line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Cores.line),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: Cores.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: Cores.primary,
          side: const BorderSide(color: Cores.line),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: Cores.primary),
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: Cores.surface,
        selectedColor: Cores.soft,
        side: const BorderSide(color: Cores.line),
        labelStyle: GoogleFonts.inter(fontSize: 13),
      ),
    );
  }
}
