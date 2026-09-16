import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/router/router.dart';
import 'core/theme/theme.dart';

import 'core/services/gesture_recognition_service.dart';
import 'core/services/active_hours_scheduler.dart';
import 'core/models/profile_database.dart';

final gestureRecognitionService = GestureRecognitionService();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock to portrait by default — remove if landscape is needed.
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Light-mode defaults: dark icons on transparent status bar.
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    systemNavigationBarColor: Colors.white,
    systemNavigationBarIconBrightness: Brightness.dark,
  ));

  final prefs = await SharedPreferences.getInstance();
  final serviceEnabled = prefs.getBool('gesture_service_enabled') ?? false;
  if (serviceEnabled) {
    try {
      await ActiveHoursScheduler.instance.start_();
      // The native service starts with an empty mapping cache until this is
      // pushed — without it, a service that was already running before the
      // Flutter side even added a profile has nothing to dispatch gestures to.
      await ProfileDatabase.instance.syncToNative();
    } catch (_) {
      // Most likely CAMERA permission was revoked while the app was closed;
      // there's no UI here to report to, home_screen's toggle will surface it.
    }
  }

  runApp(const SpartialTouchApp());
}

class SpartialTouchApp extends StatelessWidget {
  const SpartialTouchApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Spartial Touch',
      debugShowCheckedModeBanner: false,

      // ── Theme ──────────────────────────────────────────────────────────
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system, // follows system; defaults to light

      // ── Routing ────────────────────────────────────────────────────────
      initialRoute: AppRoutes.splash,
      onGenerateRoute: AppRouter.onGenerateRoute,

      // ── Builder: adapt system UI to current brightness ─────────────────
      builder: (context, child) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness:
                isDark ? Brightness.light : Brightness.dark,
            systemNavigationBarColor:
                Theme.of(context).scaffoldBackgroundColor,
            systemNavigationBarIconBrightness:
                isDark ? Brightness.light : Brightness.dark,
          ),
          child: child!,
        );
      },
    );
  }
}
