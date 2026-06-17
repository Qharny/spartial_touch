import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../../core/app_session.dart';
import '../../core/router/router.dart';
import '../../core/theme/theme.dart';

/// Splash screen — attempts to play hand.lottie; falls back to a static
/// gradient logo if the composition fails to parse (e.g. 0-frame dotLottie).
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  // Drives the text + logo fade-in for both the Lottie and fallback paths
  late AnimationController _fadeCtrl;
  late Animation<double> _textFade;
  late Animation<double> _textSlide;

  LottieComposition? _composition; // non-null → Lottie rendered successfully

  @override
  void initState() {
    super.initState();

    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _textFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut),
    );

    _textSlide = Tween<double>(begin: 18, end: 0).animate(
      CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOutCubic),
    );

    // ── Fixed 3-second splash ───────────────────────────────────────────────
    // Navigation always fires at the 3s mark, regardless of Lottie load time.
    // Fork: first launch → onboarding; returning users → Dashboard.
    Future<void>.delayed(
      const Duration(seconds: 3),
      () {
        if (!mounted) return;
        final next = AppSession.instance.onboardingComplete
            ? AppRoutes.shell
            : AppRoutes.onboarding;
        Navigator.of(context).pushReplacementNamed(next);
      },
    );

    // Text slides up at 1.5 s so it fills the second half of the splash.
    Future<void>.delayed(
      const Duration(milliseconds: 1500),
      () { if (mounted) _fadeCtrl.forward(); },
    );

    _loadLottie();
  }

  Future<void> _loadLottie() async {
    try {
      final comp = await AssetLottie('assets/hand.json').load();

      // Guard against the 0-frame case without crashing
      if (comp.startFrame == comp.endFrame) {
        throw Exception('hand.json has zero frames — skipping Lottie.');
      }

      if (!mounted) return;
      setState(() => _composition = comp);
    } catch (_) {
    }
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Hero area ──────────────────────────────────────────────────
            if (_composition != null)
              // ✅ Lottie loaded successfully
              Lottie(
                composition: _composition!,
                width: 220,
                height: 220,
                repeat: false,
                delegates: LottieDelegates(
                  values: [
                    ValueDelegate.color(
                      const ['**'],
                      value: AppColorsShared.accent,
                    ),
                  ],
                ),
              )
            else
              // ⏳ Loading — show a small spinner
              const SizedBox(
                width: 48,
                height: 48,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColorsShared.accent,
                ),
              ),

            const SizedBox(height: 16),

            // ── App name + tagline ─────────────────────────────────────────
            AnimatedBuilder(
              animation: _fadeCtrl,
              builder: (_, _) => Transform.translate(
                offset: Offset(0, _textSlide.value),
                child: Opacity(
                  opacity: _textFade.value,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Spartial Touch',
                        style: tt.headlineMedium!
                            .copyWith(letterSpacing: -0.5),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Feel the space.',
                        style: tt.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
