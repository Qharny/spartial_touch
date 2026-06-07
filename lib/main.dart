import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'core/router/router.dart';
import 'core/theme/theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock to portrait by default — remove if landscape is needed.
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Transparent status bar with light icons on dark background.
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: AppColors.background,
    systemNavigationBarIconBrightness: Brightness.light,
  ));

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
      theme: AppTheme.dark,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.dark,

      // ── Routing ────────────────────────────────────────────────────────
      initialRoute: AppRoutes.splash,
      onGenerateRoute: AppRouter.onGenerateRoute,

      // ── Builder: enforce dark status bar & edge-to-edge ───────────────
      builder: (context, child) {
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: const SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.light,
            systemNavigationBarColor: AppColors.background,
          ),
          child: child!,
        );
      },
    );
  }
}
