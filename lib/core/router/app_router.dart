import 'package:flutter/material.dart';
import '../theme/theme.dart';
import 'app_routes.dart';

// ── Screen imports ────────────────────────────────────────────────────────────
import '../../features/home/home_screen.dart';
import '../../features/search/search_screen.dart';
import '../../features/profile/profile_screen.dart';
import '../../features/profile/profile_editor_screen.dart';
import '../../features/gestures/gesture_library_screen.dart';
import '../../features/gestures/gesture_detail_screen.dart';
import '../../features/gestures/gesture_tester_screen.dart';
import '../../features/calibration/calibration_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../../features/shell/shell_screen.dart';
import '../../features/splash/splash_screen.dart';
import '../../features/notifications/notifications_screen.dart';
import '../../features/item_detail/item_detail_screen.dart';
import '../../features/onboarding/onboarding_screen.dart';

/// Builds the [MaterialApp.onGenerateRoute] route table.
///
/// All transitions use the app-level [PageTransitionsTheme]; individual routes
/// can override by returning a custom [Route] instead of a [MaterialPageRoute].
abstract final class AppRouter {
  /// Route factory — wired into [MaterialApp.onGenerateRoute].
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    return switch (settings.name) {
      AppRoutes.splash => _fade(const SplashScreen(), settings),
      AppRoutes.onboarding => _fade(const OnboardingScreen(), settings),
      AppRoutes.shell => _fadeSlide(const ShellScreen(), settings),
      AppRoutes.home => _fadeSlide(const HomeScreen(), settings),
      AppRoutes.search => _fadeSlide(const SearchScreen(), settings),
      AppRoutes.profile => _fadeSlide(const ProfileScreen(), settings),
      AppRoutes.profileEditor => _slide(const ProfileEditorScreen(), settings),
      AppRoutes.gestureLibrary => _fadeSlide(const GestureLibraryScreen(), settings),
      AppRoutes.gestureDetail => _slide(const GestureDetailScreen(), settings),
      AppRoutes.gestureTester => _fade(const GestureTesterScreen(), settings),
      AppRoutes.calibration => _slide(const CalibrationScreen(), settings),
      AppRoutes.settings => _slide(const SettingsScreen(), settings),
      AppRoutes.notifications => _slide(const NotificationsScreen(), settings),
      AppRoutes.itemDetail => _slide(const ItemDetailScreen(), settings),
      _ => _notFound(settings),
    };
  }

  // ── Transition helpers ────────────────────────────────────────────────────

  /// Pure fade — used for splash / root transitions.
  static Route<T> _fade<T>(Widget page, RouteSettings settings) =>
      PageRouteBuilder<T>(
        settings: settings,
        transitionDuration: const Duration(milliseconds: 350),
        reverseTransitionDuration: const Duration(milliseconds: 250),
        pageBuilder: (_, _, _) => page,
        transitionsBuilder: (_, anim, _, child) => FadeTransition(
          opacity: CurvedAnimation(parent: anim, curve: Curves.easeInOut),
          child: child,
        ),
      );

  /// Fade + upward slide — main navigation transition.
  static Route<T> _fadeSlide<T>(Widget page, RouteSettings settings) =>
      PageRouteBuilder<T>(
        settings: settings,
        transitionDuration: const Duration(milliseconds: 320),
        reverseTransitionDuration: const Duration(milliseconds: 250),
        pageBuilder: (_, _, _) => page,
        transitionsBuilder: (_, anim, secondaryAnim, child) {
          final curved = CurvedAnimation(
            parent: anim,
            curve: Curves.easeOutCubic,
            reverseCurve: Curves.easeInCubic,
          );
          final slide = Tween<Offset>(
            begin: const Offset(0, 0.06),
            end: Offset.zero,
          ).animate(curved);
          final fade = Tween<double>(begin: 0, end: 1).animate(
            CurvedAnimation(
              parent: anim,
              curve: const Interval(0, 0.65, curve: Curves.easeOut),
            ),
          );
          final scaleOut = Tween<double>(begin: 1, end: 0.97).animate(
            CurvedAnimation(parent: secondaryAnim, curve: Curves.easeInCubic),
          );
          return ScaleTransition(
            scale: scaleOut,
            child: FadeTransition(
              opacity: fade,
              child: SlideTransition(position: slide, child: child),
            ),
          );
        },
      );

  /// Right-to-left slide — used for detail / sub-pages.
  static Route<T> _slide<T>(Widget page, RouteSettings settings) =>
      PageRouteBuilder<T>(
        settings: settings,
        transitionDuration: const Duration(milliseconds: 320),
        reverseTransitionDuration: const Duration(milliseconds: 250),
        pageBuilder: (_, _, _) => page,
        transitionsBuilder: (_, anim, _, child) {
          final curved = CurvedAnimation(
            parent: anim,
            curve: Curves.easeOutCubic,
            reverseCurve: Curves.easeInCubic,
          );
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1, 0),
              end: Offset.zero,
            ).animate(curved),
            child: child,
          );
        },
      );

  /// 404 fallback.
  static Route<dynamic> _notFound(RouteSettings settings) => _fade(
        _NotFoundScreen(routeName: settings.name ?? 'unknown'),
        settings,
      );
}

// ── 404 Screen ────────────────────────────────────────────────────────────────
class _NotFoundScreen extends StatelessWidget {
  const _NotFoundScreen({required this.routeName});
  final String routeName;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.map_outlined, size: 64, color: AppColors.neutral),
            const SizedBox(height: 16),
            Text(
              '404 — Route not found',
              style: AppTextTheme.textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              '"$routeName"',
              style: AppTextTheme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pushNamedAndRemoveUntil(
                AppRoutes.shell,
                (_) => false,
              ),
              child: const Text('Back to Home'),
            ),
          ],
        ),
      ),
    );
  }
}
