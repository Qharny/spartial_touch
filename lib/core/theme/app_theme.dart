import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_colors.dart';
import 'app_text_theme.dart';

/// SpartialTouch — Master ThemeData
abstract final class AppTheme {
  static ThemeData get light => _buildLight();
  static ThemeData get dark => _buildDark();

  // ───────────────────────────────────────────────────────────────────────────
  // Light Theme
  // ───────────────────────────────────────────────────────────────────────────

  static ThemeData _buildLight() {
    final textTheme = AppTextTheme.lightTextTheme;

    final colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: AppColorsLight.accent,
      onPrimary: Colors.white,
      primaryContainer: AppColorsLight.accentMuted,
      onPrimaryContainer: AppColorsLight.accent,
      secondary: AppColorsLight.neutral,
      onSecondary: Colors.white,
      secondaryContainer: AppColorsLight.surfaceVariant,
      onSecondaryContainer: AppColorsLight.textSecondary,
      tertiary: AppColorsLight.textSecondary,
      onTertiary: AppColorsLight.background,
      tertiaryContainer: AppColorsLight.surface,
      onTertiaryContainer: AppColorsLight.textPrimary,
      error: AppColorsLight.error,
      onError: Colors.white,
      errorContainer: const Color(0xFFFCE4EC),
      onErrorContainer: AppColorsLight.error,
      surface: AppColorsLight.surface,
      onSurface: AppColorsLight.textPrimary,
      surfaceContainerHighest: AppColorsLight.surfaceVariant,
      onSurfaceVariant: AppColorsLight.textSecondary,
      outline: AppColorsLight.outline,
      outlineVariant: const Color(0xFFE8E8E8),
      shadow: Colors.black12,
      scrim: Colors.black26,
      inverseSurface: AppColorsLight.textPrimary,
      onInverseSurface: AppColorsLight.background,
      inversePrimary: AppColorsLight.accentMuted,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColorsLight.background,
      textTheme: textTheme,

      appBarTheme: AppBarTheme(
        backgroundColor: AppColorsLight.background,
        foregroundColor: AppColorsLight.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          systemNavigationBarColor: AppColorsLight.background,
          systemNavigationBarIconBrightness: Brightness.dark,
        ),
        iconTheme: const IconThemeData(color: AppColorsLight.textPrimary),
      ),

      cardTheme: CardThemeData(
        color: AppColorsLight.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColorsLight.outline, width: 1),
        ),
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
      ),

      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColorsLight.surface,
        selectedItemColor: AppColorsLight.accent,
        unselectedItemColor: AppColorsLight.textDisabled,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        showSelectedLabels: true,
        showUnselectedLabels: true,
      ),

      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColorsLight.surface,
        indicatorColor: AppColorsLight.accentMuted,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: AppColorsLight.accent);
          }
          return const IconThemeData(color: AppColorsLight.textDisabled);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final base = textTheme.labelSmall!;
          if (states.contains(WidgetState.selected)) {
            return base.copyWith(color: AppColorsLight.accent);
          }
          return base;
        }),
        elevation: 0,
        height: 64,
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColorsLight.accent,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColorsLight.outline,
          disabledForegroundColor: AppColorsLight.textDisabled,
          elevation: 0,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: textTheme.labelLarge,
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColorsLight.textPrimary,
          side: const BorderSide(color: AppColorsLight.outline),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: textTheme.labelLarge,
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColorsLight.accent,
          textStyle: textTheme.labelLarge,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),

      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: AppColorsLight.textPrimary,
          backgroundColor: AppColorsLight.surfaceVariant,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),

      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColorsLight.textPrimary,
        foregroundColor: AppColorsLight.background,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColorsLight.surfaceVariant,
        hintStyle: textTheme.bodyMedium!.copyWith(color: AppColorsLight.textDisabled),
        labelStyle: textTheme.bodyMedium,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColorsLight.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColorsLight.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColorsLight.accent, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColorsLight.error),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        prefixIconColor: AppColorsLight.textDisabled,
        suffixIconColor: AppColorsLight.textDisabled,
      ),

      dividerTheme: const DividerThemeData(
        color: AppColorsLight.outline,
        thickness: 1,
        space: 1,
      ),

      chipTheme: ChipThemeData(
        backgroundColor: AppColorsLight.surfaceVariant,
        selectedColor: AppColorsLight.accentMuted,
        labelStyle: textTheme.labelMedium!.copyWith(color: AppColorsLight.textSecondary),
        secondaryLabelStyle: textTheme.labelMedium!.copyWith(color: AppColorsLight.accent),
        side: const BorderSide(color: AppColorsLight.outline),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),

      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColorsLight.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        elevation: 8,
        modalElevation: 8,
        dragHandleColor: AppColorsLight.outline,
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: AppColorsLight.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 8,
        titleTextStyle: textTheme.titleLarge,
        contentTextStyle: textTheme.bodyMedium,
      ),

      listTileTheme: ListTileThemeData(
        tileColor: Colors.transparent,
        selectedTileColor: AppColorsLight.accentMuted,
        iconColor: AppColorsLight.textSecondary,
        textColor: AppColorsLight.textPrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),

      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColorsLight.accent;
          return AppColorsLight.textDisabled;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColorsLight.accentMuted;
          return AppColorsLight.outline;
        }),
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColorsLight.textPrimary,
        contentTextStyle: textTheme.bodyMedium!.copyWith(color: AppColorsLight.background),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 4,
      ),

      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColorsLight.accent,
        linearTrackColor: AppColorsLight.outline,
        circularTrackColor: AppColorsLight.outline,
      ),

      sliderTheme: const SliderThemeData(
        activeTrackColor: AppColorsLight.accent,
        inactiveTrackColor: AppColorsLight.outline,
        thumbColor: AppColorsLight.accent,
        overlayColor: AppColorsLight.accentMuted,
        valueIndicatorColor: AppColorsLight.accent,
      ),

      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: AppColorsLight.textPrimary,
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: textTheme.bodySmall!.copyWith(color: AppColorsLight.background),
      ),

      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: _FadeSlidePageTransitionsBuilder(),
          TargetPlatform.iOS: _FadeSlidePageTransitionsBuilder(),
          TargetPlatform.windows: _FadeSlidePageTransitionsBuilder(),
          TargetPlatform.macOS: _FadeSlidePageTransitionsBuilder(),
          TargetPlatform.linux: _FadeSlidePageTransitionsBuilder(),
        },
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Dark Theme
  // ───────────────────────────────────────────────────────────────────────────

  static ThemeData _buildDark() {
    final textTheme = AppTextTheme.darkTextTheme;

    final colorScheme = ColorScheme(
      brightness: Brightness.dark,
      primary: AppColorsDark.accent,
      onPrimary: AppColorsDark.textPrimary,
      primaryContainer: AppColorsDark.accentMuted,
      onPrimaryContainer: AppColorsDark.accent,
      secondary: AppColorsDark.neutral,
      onSecondary: AppColorsDark.textPrimary,
      secondaryContainer: AppColorsDark.surfaceVariant,
      onSecondaryContainer: AppColorsDark.textSecondary,
      tertiary: AppColorsDark.textSecondary,
      onTertiary: AppColorsDark.background,
      tertiaryContainer: AppColorsDark.surface,
      onTertiaryContainer: AppColorsDark.textPrimary,
      error: AppColorsDark.error,
      onError: AppColorsDark.textPrimary,
      errorContainer: const Color(0xFF4A1A22),
      onErrorContainer: AppColorsDark.error,
      surface: AppColorsDark.surface,
      onSurface: AppColorsDark.textPrimary,
      surfaceContainerHighest: AppColorsDark.surfaceVariant,
      onSurfaceVariant: AppColorsDark.textSecondary,
      outline: AppColorsDark.outline,
      outlineVariant: const Color(0xFF1E1E1E),
      shadow: Colors.black,
      scrim: Colors.black54,
      inverseSurface: AppColorsDark.textPrimary,
      onInverseSurface: AppColorsDark.background,
      inversePrimary: AppColorsDark.accentMuted,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColorsDark.background,
      textTheme: textTheme,

      appBarTheme: AppBarTheme(
        backgroundColor: AppColorsDark.background,
        foregroundColor: AppColorsDark.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          systemNavigationBarColor: AppColorsDark.background,
          systemNavigationBarIconBrightness: Brightness.light,
        ),
        iconTheme: const IconThemeData(color: AppColorsDark.textPrimary),
      ),

      cardTheme: CardThemeData(
        color: AppColorsDark.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColorsDark.outline, width: 1),
        ),
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
      ),

      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColorsDark.surface,
        selectedItemColor: AppColorsDark.accent,
        unselectedItemColor: AppColorsDark.textDisabled,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        showSelectedLabels: true,
        showUnselectedLabels: true,
      ),

      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColorsDark.surface,
        indicatorColor: AppColorsDark.accentMuted,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: AppColorsDark.accent);
          }
          return const IconThemeData(color: AppColorsDark.textDisabled);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final base = textTheme.labelSmall!;
          if (states.contains(WidgetState.selected)) {
            return base.copyWith(color: AppColorsDark.accent);
          }
          return base;
        }),
        elevation: 0,
        height: 64,
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColorsDark.accent,
          foregroundColor: AppColorsDark.textPrimary,
          disabledBackgroundColor: AppColorsDark.outline,
          disabledForegroundColor: AppColorsDark.textDisabled,
          elevation: 0,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: textTheme.labelLarge,
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColorsDark.textPrimary,
          side: const BorderSide(color: AppColorsDark.outline),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: textTheme.labelLarge,
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColorsDark.accent,
          textStyle: textTheme.labelLarge,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),

      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: AppColorsDark.textPrimary,
          backgroundColor: AppColorsDark.surfaceVariant,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),

      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColorsDark.accent,
        foregroundColor: AppColorsDark.textPrimary,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColorsDark.surfaceVariant,
        hintStyle: textTheme.bodyMedium!.copyWith(color: AppColorsDark.textDisabled),
        labelStyle: textTheme.bodyMedium,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColorsDark.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColorsDark.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColorsDark.accent, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColorsDark.error),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        prefixIconColor: AppColorsDark.textDisabled,
        suffixIconColor: AppColorsDark.textDisabled,
      ),

      dividerTheme: const DividerThemeData(
        color: AppColorsDark.outline,
        thickness: 1,
        space: 1,
      ),

      chipTheme: ChipThemeData(
        backgroundColor: AppColorsDark.surfaceVariant,
        selectedColor: AppColorsDark.accentMuted,
        labelStyle: textTheme.labelMedium!.copyWith(color: AppColorsDark.textSecondary),
        secondaryLabelStyle: textTheme.labelMedium!.copyWith(color: AppColorsDark.accent),
        side: const BorderSide(color: AppColorsDark.outline),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),

      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColorsDark.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        elevation: 8,
        modalElevation: 8,
        dragHandleColor: AppColorsDark.outline,
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: AppColorsDark.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 8,
        titleTextStyle: textTheme.titleLarge,
        contentTextStyle: textTheme.bodyMedium,
      ),

      listTileTheme: ListTileThemeData(
        tileColor: Colors.transparent,
        selectedTileColor: AppColorsDark.accentMuted,
        iconColor: AppColorsDark.textSecondary,
        textColor: AppColorsDark.textPrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),

      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColorsDark.accent;
          return AppColorsDark.textDisabled;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColorsDark.accentMuted;
          return AppColorsDark.outline;
        }),
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColorsDark.surfaceVariant,
        contentTextStyle: textTheme.bodyMedium,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 4,
      ),

      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColorsDark.accent,
        linearTrackColor: AppColorsDark.outline,
        circularTrackColor: AppColorsDark.outline,
      ),

      sliderTheme: const SliderThemeData(
        activeTrackColor: AppColorsDark.accent,
        inactiveTrackColor: AppColorsDark.outline,
        thumbColor: AppColorsDark.accent,
        overlayColor: AppColorsDark.accentMuted,
        valueIndicatorColor: AppColorsDark.accent,
      ),

      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: AppColorsDark.surfaceVariant,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColorsDark.outline),
        ),
        textStyle: textTheme.bodySmall!.copyWith(color: AppColorsDark.textPrimary),
      ),

      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: _FadeSlidePageTransitionsBuilder(),
          TargetPlatform.iOS: _FadeSlidePageTransitionsBuilder(),
          TargetPlatform.windows: _FadeSlidePageTransitionsBuilder(),
          TargetPlatform.macOS: _FadeSlidePageTransitionsBuilder(),
          TargetPlatform.linux: _FadeSlidePageTransitionsBuilder(),
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Custom Page Transition Builder
// ─────────────────────────────────────────────────────────────────────────────

/// Soft fade + upward slide transition — 300 ms, easeOutCubic.
class _FadeSlidePageTransitionsBuilder extends PageTransitionsBuilder {
  const _FadeSlidePageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return _FadeSlideTransition(
      animation: animation,
      secondaryAnimation: secondaryAnimation,
      child: child,
    );
  }
}

class _FadeSlideTransition extends StatelessWidget {
  const _FadeSlideTransition({
    required this.animation,
    required this.secondaryAnimation,
    required this.child,
  });

  final Animation<double> animation;
  final Animation<double> secondaryAnimation;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final curved = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );

    final slideIn = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(curved);

    final fadeIn = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: animation,
        curve: const Interval(0, 0.7, curve: Curves.easeOut),
      ),
    );

    final scaleOut = Tween<double>(begin: 1, end: 0.97).animate(
      CurvedAnimation(
        parent: secondaryAnimation,
        curve: Curves.easeInCubic,
      ),
    );

    return ScaleTransition(
      scale: scaleOut,
      child: FadeTransition(
        opacity: fadeIn,
        child: SlideTransition(position: slideIn, child: child),
      ),
    );
  }
}
