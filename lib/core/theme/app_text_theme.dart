import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// SpartialTouch — Typography
///
/// Font family : Inter (via google_fonts)
///
/// Colors are NOT set here — they come from the active [ColorScheme]
/// so text automatically adapts to light / dark mode.
abstract final class AppTextTheme {
  /// Light-mode text theme (dark text).
  static TextTheme get lightTextTheme =>
      GoogleFonts.interTextTheme(_baseTextTheme(Brightness.light));

  /// Dark-mode text theme (light text).
  static TextTheme get darkTextTheme =>
      GoogleFonts.interTextTheme(_baseTextTheme(Brightness.dark));

  /// Legacy getter — kept so un-migrated code compiles. Points to dark.
  static TextTheme get textTheme => darkTextTheme;

  static TextTheme _baseTextTheme(Brightness brightness) {
    final bool isDark = brightness == Brightness.dark;

    final Color textHigh = isDark ? const Color(0xFFFFFFFF) : const Color(0xFF0A0A0A);
    final Color textMed = isDark ? const Color(0xFFB0AFAF) : const Color(0xFF6B6B6B);
    final Color textLow = isDark ? const Color(0xFF555555) : const Color(0xFFB0B0B0);

    return TextTheme(
      // ── Display ─────────────────────────────────────────────────────
      displayLarge: TextStyle(
        fontSize: 57,
        fontWeight: FontWeight.w300,
        letterSpacing: -0.25,
        color: textHigh,
      ),
      displayMedium: TextStyle(
        fontSize: 45,
        fontWeight: FontWeight.w300,
        letterSpacing: 0,
        color: textHigh,
      ),
      displaySmall: TextStyle(
        fontSize: 36,
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
        color: textHigh,
      ),

      // ── Headline ────────────────────────────────────────────────────
      headlineLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.5,
        color: textHigh,
      ),
      headlineMedium: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.25,
        color: textHigh,
      ),
      headlineSmall: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
        color: textHigh,
      ),

      // ── Title ────────────────────────────────────────────────────────
      titleLarge: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
        color: textHigh,
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.15,
        color: textHigh,
      ),
      titleSmall: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
        color: textMed,
      ),

      // ── Body ─────────────────────────────────────────────────────────
      bodyLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.5,
        color: textHigh,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.25,
        color: textMed,
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.4,
        color: textLow,
      ),

      // ── Label ────────────────────────────────────────────────────────
      labelLarge: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
        color: textHigh,
      ),
      labelMedium: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
        color: textMed,
      ),
      labelSmall: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
        color: textLow,
      ),
    );
  }
}
