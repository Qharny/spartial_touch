import 'package:flutter/material.dart';

/// SpartialTouch Design System — Color Tokens
///
/// Primary  : #0A0A0A  (deep matte black)
/// Secondary: #FFFFFF  (pure white)
/// Tertiary : #0B0A09  (warm near-black)
/// Neutral  : #797676  (mid grey)
abstract final class AppColors {
  // ── Brand ────────────────────────────────────────────────────────────────
  static const Color primary = Color(0xFF0A0A0A);
  static const Color secondary = Color(0xFFFFFFFF);
  static const Color tertiary = Color(0xFF0B0A09);
  static const Color neutral = Color(0xFF797676);

  // ── Surfaces ─────────────────────────────────────────────────────────────
  /// Page / scaffold background
  static const Color background = Color(0xFF0D0D0D);

  /// Slightly elevated card surface
  static const Color surface = Color(0xFF1A1A1A);

  /// Second-level card / modal surface
  static const Color surfaceVariant = Color(0xFF252525);

  /// Subtle divider / outline
  static const Color outline = Color(0xFF2E2E2E);

  // ── Text ─────────────────────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB0AFAF);
  static const Color textDisabled = Color(0xFF555555);

  // ── Accent ───────────────────────────────────────────────────────────────
  /// Warm amber accent (matches the "Primary" button highlight in the mockup)
  static const Color accent = Color(0xFFD4823A);
  static const Color accentMuted = Color(0x33D4823A); // 20 % opacity

  // ── Semantic ─────────────────────────────────────────────────────────────
  static const Color error = Color(0xFFCF6679);
  static const Color success = Color(0xFF4CAF8A);
  static const Color warning = Color(0xFFE8A838);

  // ── Gradients ─────────────────────────────────────────────────────────────
  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0D0D0D), Color(0xFF151413)],
  );

  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFD4823A), Color(0xFFB86A28)],
  );

  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF222222), Color(0xFF181818)],
  );

  // ── Shades (for swatch-like usage) ───────────────────────────────────────
  static const List<Color> primaryShades = [
    Color(0xFF0A0A0A),
    Color(0xFF141414),
    Color(0xFF1E1E1E),
    Color(0xFF282828),
    Color(0xFF323232),
    Color(0xFF3C3C3C),
    Color(0xFF464646),
    Color(0xFF505050),
    Color(0xFF5A5A5A),
    Color(0xFF646464),
  ];

  static const List<Color> neutralShades = [
    Color(0xFF797676),
    Color(0xFF8A8787),
    Color(0xFF9B9898),
    Color(0xFFACAA9A),
    Color(0xFFBDBBBB),
    Color(0xFFCECCCC),
    Color(0xFFDFDDDD),
    Color(0xFFEFEEEE),
  ];
}
