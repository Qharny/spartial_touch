import 'package:flutter/material.dart';

/// SpartialTouch Design System — Color Tokens
///
/// Two palettes:
///   • **Light** – white backgrounds, dark text
///   • **Dark**  – deep black backgrounds, white text
///
/// Accent / semantic colors are shared across both themes.

// ─────────────────────────────────────────────────────────────────────────────
// Shared tokens (same in both themes)
// ─────────────────────────────────────────────────────────────────────────────

abstract final class AppColorsShared {
  // ── Accent ─────────────────────────────────────────────────────────────
  /// Warm amber accent
  static const Color accent = Color(0xFFD4823A);
  static const Color accentMuted = Color(0x33D4823A); // 20 % opacity

  // ── Semantic ───────────────────────────────────────────────────────────
  static const Color error = Color(0xFFCF6679);
  static const Color success = Color(0xFF4CAF8A);
  static const Color warning = Color(0xFFE8A838);
}

// ─────────────────────────────────────────────────────────────────────────────
// Light palette
// ─────────────────────────────────────────────────────────────────────────────

abstract final class AppColorsLight {
  // ── Brand ──────────────────────────────────────────────────────────────
  static const Color primary = Color(0xFFFFFFFF);
  static const Color secondary = Color(0xFF0A0A0A);
  static const Color tertiary = Color(0xFFF8F7F6);
  static const Color neutral = Color(0xFF797676);

  // ── Surfaces ───────────────────────────────────────────────────────────
  static const Color background = Color(0xFFFFFFFF);
  static const Color surface = Color(0xFFF5F5F5);
  static const Color surfaceVariant = Color(0xFFEBEBEB);
  static const Color outline = Color(0xFFE0E0E0);

  // ── Text ───────────────────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFF0A0A0A);
  static const Color textSecondary = Color(0xFF6B6B6B);
  static const Color textDisabled = Color(0xFFB0B0B0);

  // ── Accent (re-exported for convenience) ───────────────────────────────
  static const Color accent = AppColorsShared.accent;
  static const Color accentMuted = AppColorsShared.accentMuted;

  // ── Semantic ───────────────────────────────────────────────────────────
  static const Color error = AppColorsShared.error;
  static const Color success = AppColorsShared.success;
  static const Color warning = AppColorsShared.warning;

  // ── Gradients ──────────────────────────────────────────────────────────
  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFFFFF), Color(0xFFF8F8F8)],
  );

  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFD4823A), Color(0xFFB86A28)],
  );

  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFF8F8F8), Color(0xFFF0F0F0)],
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Dark palette
// ─────────────────────────────────────────────────────────────────────────────

abstract final class AppColorsDark {
  // ── Brand ──────────────────────────────────────────────────────────────
  static const Color primary = Color(0xFF0A0A0A);
  static const Color secondary = Color(0xFFFFFFFF);
  static const Color tertiary = Color(0xFF0B0A09);
  static const Color neutral = Color(0xFF797676);

  // ── Surfaces ───────────────────────────────────────────────────────────
  static const Color background = Color(0xFF0D0D0D);
  static const Color surface = Color(0xFF1A1A1A);
  static const Color surfaceVariant = Color(0xFF252525);
  static const Color outline = Color(0xFF2E2E2E);

  // ── Text ───────────────────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB0AFAF);
  static const Color textDisabled = Color(0xFF555555);

  // ── Accent (re-exported for convenience) ───────────────────────────────
  static const Color accent = AppColorsShared.accent;
  static const Color accentMuted = AppColorsShared.accentMuted;

  // ── Semantic ───────────────────────────────────────────────────────────
  static const Color error = AppColorsShared.error;
  static const Color success = AppColorsShared.success;
  static const Color warning = AppColorsShared.warning;

  // ── Gradients ──────────────────────────────────────────────────────────
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
}

// ─────────────────────────────────────────────────────────────────────────────
// Legacy alias  — points to Dark values so un-migrated code keeps compiling.
// Screens should migrate to Theme.of(context).colorScheme instead.
// ─────────────────────────────────────────────────────────────────────────────

abstract final class AppColors {
  static const Color primary = AppColorsDark.primary;
  static const Color secondary = AppColorsDark.secondary;
  static const Color tertiary = AppColorsDark.tertiary;
  static const Color neutral = AppColorsDark.neutral;

  static const Color background = AppColorsDark.background;
  static const Color surface = AppColorsDark.surface;
  static const Color surfaceVariant = AppColorsDark.surfaceVariant;
  static const Color outline = AppColorsDark.outline;

  static const Color textPrimary = AppColorsDark.textPrimary;
  static const Color textSecondary = AppColorsDark.textSecondary;
  static const Color textDisabled = AppColorsDark.textDisabled;

  static const Color accent = AppColorsShared.accent;
  static const Color accentMuted = AppColorsShared.accentMuted;

  static const Color error = AppColorsShared.error;
  static const Color success = AppColorsShared.success;
  static const Color warning = AppColorsShared.warning;

  static const LinearGradient backgroundGradient = AppColorsDark.backgroundGradient;
  static const LinearGradient accentGradient = AppColorsDark.accentGradient;
  static const LinearGradient cardGradient = AppColorsDark.cardGradient;
}
