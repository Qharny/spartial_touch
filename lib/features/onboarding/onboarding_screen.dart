import 'package:app_settings/app_settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../core/app_session.dart';
import '../../core/router/router.dart';
import '../../core/theme/theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Page data model
// ─────────────────────────────────────────────────────────────────────────────

enum _PageStyle { light, dark }

/// Identifies the behaviour behind each onboarding page's primary action.
enum OnboardingStep { welcome, camera, accessibility, overlay, calibration, profile }

class _Page {
  const _Page({
    required this.step,
    required this.style,
    required this.illustration,
    required this.title,
    required this.body,
    required this.primaryLabel,
    required this.secondaryLabel,
  });

  final OnboardingStep step;
  final _PageStyle style;
  final Widget illustration;
  final String title;
  final String body;
  final String primaryLabel;
  final String secondaryLabel;
}

// ─────────────────────────────────────────────────────────────────────────────
// Page definitions
// ─────────────────────────────────────────────────────────────────────────────

final List<_Page> _pages = [
  const _Page(
    step: OnboardingStep.welcome,
    style: _PageStyle.light,
    illustration: _WelcomeIllustration(),
    title: 'Control your phone with air',
    body:
        'Control any Android app with mid-air hand gestures. Wave your hand to scroll, tap, and swipe, no screen contact required.',
    primaryLabel: 'Get Started',
    secondaryLabel: 'Skip for returning users',
  ),
  const _Page(
    step: OnboardingStep.camera,
    style: _PageStyle.light,
    illustration: _CameraIllustration(),
    title: 'Camera Permission',
    body:
        'Used ONLY on-device to detect hand gestures. Never recorded or transmitted.',
    primaryLabel: 'Grant Camera Access',
    secondaryLabel: 'How to enable manually',
  ),
  const _Page(
    step: OnboardingStep.accessibility,
    style: _PageStyle.dark,
    illustration: _AccessibilityIllustration(),
    title: 'Accessibility Service',
    body:
        'We need Accessibility Service enabled to inject scroll and tap events into your apps.',
    primaryLabel: 'Open Accessibility Settings',
    secondaryLabel: 'I have already enabled it',
  ),
  const _Page(
    step: OnboardingStep.overlay,
    style: _PageStyle.dark,
    illustration: _OverlayIllustration(),
    title: 'Overlay Permission',
    body:
        'The floating indicator bubble lets you know when gestures are detected. Optional but recommended.',
    primaryLabel: 'Enable Overlay',
    secondaryLabel: 'Skip for now',
  ),
  const _Page(
    step: OnboardingStep.calibration,
    style: _PageStyle.light,
    illustration: _CalibrationIllustration(),
    title: 'Calibration',
    body:
        'Let\'s tailor the detection to your environment. Hold your hand at a natural distance so we can measure lighting and distance thresholds.',
    primaryLabel: 'Calibration Complete',
    secondaryLabel: 'Skip',
  ),
  const _Page(
    step: OnboardingStep.profile,
    style: _PageStyle.light,
    illustration: _FirstProfileIllustration(),
    title: 'Create your first profile',
    body:
        'Pick an app to control with gestures. You can fine-tune mappings any time from the Profiles tab.',
    primaryLabel: 'Finish Setup',
    secondaryLabel: 'Skip for now',
  ),
];

// ─────────────────────────────────────────────────────────────────────────────
// Main screen
// ─────────────────────────────────────────────────────────────────────────────

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _ctrl = PageController();
  int _page = 0;

  /// Steps the user has satisfied (granted, visited, or calibrated).
  final Set<OnboardingStep> _done = {};

  /// True while an async permission request is in flight (locks the button).
  bool _busy = false;

  /// True while the calibration sweep is running.
  bool _calibrating = false;

  // ── helpers ────────────────────────────────────────────────────────────────

  _Page get _current => _pages[_page];
  bool get _isLight => _current.style == _PageStyle.light;

  Color get _fg => _isLight ? const Color(0xFF0A0A0A) : Colors.white;
  Color get _bg => _isLight ? Colors.white : AppColors.background;

  /// Label shown on the primary button — reflects in-flight / completed state.
  String get _primaryLabel {
    if (_calibrating) return 'Calibrating…';
    final step = _current.step;
    final done = _done.contains(step);
    if (done &&
        step != OnboardingStep.welcome &&
        step != OnboardingStep.profile) {
      return 'Continue';
    }
    return _current.primaryLabel;
  }

  void _next() {
    if (_page < _pages.length - 1) {
      _ctrl.nextPage(
        duration: const Duration(milliseconds: 380),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _finish();
    }
  }

  Future<void> _finish() async {
    // Persist completion so a later Splash forks straight to the Dashboard.
    await AppSession.instance.setOnboardingComplete(true);
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed(AppRoutes.shell);
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  // ── Primary action — branches on the current step ──────────────────────────

  Future<void> _onPrimary() async {
    if (_busy || _calibrating) return;
    final step = _current.step;

    // Already satisfied → just advance.
    if (_done.contains(step) &&
        step != OnboardingStep.welcome &&
        step != OnboardingStep.profile) {
      _next();
      return;
    }

    switch (step) {
      case OnboardingStep.welcome:
        _next();
      case OnboardingStep.camera:
        await _requestCamera();
      case OnboardingStep.accessibility:
        await _openAccessibilitySettings();
      case OnboardingStep.overlay:
        await _requestOverlay();
      case OnboardingStep.calibration:
        await _runCalibration();
      case OnboardingStep.profile:
        await _finish();
    }
  }

  // ── Secondary action — the "skip / manual / already done" link ──────────────

  Future<void> _onSecondary() async {
    if (_busy || _calibrating) return;
    switch (_current.step) {
      case OnboardingStep.welcome:
        await _finish(); // skip the whole funnel
      case OnboardingStep.camera:
        await AppSettings.openAppSettings(); // enable manually
      case OnboardingStep.accessibility:
        setState(() => _done.add(OnboardingStep.accessibility));
        _next(); // "I have already enabled it"
      case OnboardingStep.overlay:
        _next(); // skip (optional)
      case OnboardingStep.calibration:
        _next(); // skip
      case OnboardingStep.profile:
        await _finish(); // skip for now
    }
  }

  // ── Step implementations ────────────────────────────────────────────────────

  Future<void> _requestCamera() async {
    setState(() => _busy = true);
    final status = await Permission.camera.request();
    if (!mounted) return;
    setState(() => _busy = false);

    if (status.isGranted) {
      setState(() => _done.add(OnboardingStep.camera));
      _next();
    } else if (status.isPermanentlyDenied) {
      _snack('Camera access was blocked. Enable it in Settings to continue.');
      await AppSettings.openAppSettings();
    } else {
      _snack('Camera access is required to detect gestures.');
    }
  }

  Future<void> _openAccessibilitySettings() async {
    // We can't reliably detect the service from Dart, so opening the settings
    // marks the step as "visited" — the button then becomes "Continue".
    await AppSettings.openAppSettings(type: AppSettingsType.accessibility);
    if (!mounted) return;
    setState(() => _done.add(OnboardingStep.accessibility));
    _snack('Enable SpartialTouch, then return and tap Continue.');
  }

  Future<void> _requestOverlay() async {
    setState(() => _busy = true);
    final status = await Permission.systemAlertWindow.request();
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (status.isGranted) _done.add(OnboardingStep.overlay);
    });
    _next(); // optional — always advance
  }

  Future<void> _runCalibration() async {
    setState(() => _calibrating = true);
    await Future<void>.delayed(const Duration(milliseconds: 2200));
    if (!mounted) return;
    setState(() {
      _calibrating = false;
      _done.add(OnboardingStep.calibration);
    });
    _next();
  }

  void _back() {
    if (_page > 0) {
      _ctrl.previousPage(
        duration: const Duration(milliseconds: 380),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  // ── build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isFirst = _page == 0;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: _isLight ? Brightness.dark : Brightness.light,
        systemNavigationBarColor: _bg,
        systemNavigationBarIconBrightness: _isLight
            ? Brightness.dark
            : Brightness.light,
      ),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 380),
        curve: Curves.easeOut,
        color: _bg,
        child: SafeArea(
          child: Scaffold(
            backgroundColor: Colors.transparent,
            body: Column(
              children: [
                // ── Header bar ───────────────────────────────────────────
                SizedBox(
                  height: 52,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 48,
                          child: isFirst
                              ? null
                              : GestureDetector(
                                  onTap: _back,
                                  behavior: HitTestBehavior.opaque,
                                  child: Center(
                                    child: Icon(
                                      Icons.arrow_back_ios_new_rounded,
                                      color: _fg,
                                      size: 20,
                                    ),
                                  ),
                                ),
                        ),

                        // Title — hidden on first page
                        Expanded(
                          child: Center(
                            child: isFirst
                                ? null
                                : AnimatedDefaultTextStyle(
                                    duration: const Duration(milliseconds: 250),
                                    style: TextStyle(
                                      color: _fg,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: -0.3,
                                      fontFamily: 'Inter',
                                      decoration: TextDecoration.none,
                                    ),
                                    child: const Text('SpartialTouch'),
                                  ),
                          ),
                        ),

                        const SizedBox(width: 48),
                      ],
                    ),
                  ),
                ),

                // ── Dot indicator ────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: _DotIndicator(
                    total: _pages.length,
                    current: _page,
                    fg: _fg,
                  ),
                ),

                // ── Page content ─────────────────────────────────────────
                Expanded(
                  child: PageView.builder(
                    controller: _ctrl,
                    itemCount: _pages.length,
                    onPageChanged: (i) => setState(() => _page = i),
                    itemBuilder: (_, i) {
                      final p = _pages[i];
                      final fg = p.style == _PageStyle.light
                          ? const Color(0xFF0A0A0A)
                          : Colors.white;
                      return _PageContent(page: p, fg: fg);
                    },
                  ),
                ),

                // ── Bottom actions ───────────────────────────────────────
                _BottomActions(
                  primaryLabel: _primaryLabel,
                  secondaryLabel: _current.secondaryLabel,
                  isLight: _isLight,
                  fg: _fg,
                  busy: _busy || _calibrating,
                  granted: _done.contains(_current.step) &&
                      _current.step != OnboardingStep.welcome &&
                      _current.step != OnboardingStep.profile,
                  onPrimary: _onPrimary,
                  onSecondary: _onSecondary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Dot indicator
// ─────────────────────────────────────────────────────────────────────────────

class _DotIndicator extends StatelessWidget {
  const _DotIndicator({
    required this.total,
    required this.current,
    required this.fg,
  });

  final int total, current;
  final Color fg;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(total, (i) {
        final active = i == current;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: active ? 22 : 7,
          height: 7,
          decoration: BoxDecoration(
            color: active ? fg : fg.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Page content
// ─────────────────────────────────────────────────────────────────────────────

class _PageContent extends StatelessWidget {
  const _PageContent({required this.page, required this.fg});

  final _Page page;
  final Color fg;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 36),
      child: Column(
        children: [
          // Illustration
          Expanded(flex: 5, child: Center(child: page.illustration)),

          // Title
          Text(
            page.title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: fg,
              fontSize: 26,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
              height: 1.2,
              fontFamily: 'Inter',
              decoration: TextDecoration.none,
            ),
          ),
          const SizedBox(height: 14),

          // Body
          Text(
            page.body,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: fg.withValues(alpha: 0.55),
              fontSize: 15,
              fontWeight: FontWeight.w400,
              height: 1.55,
              fontFamily: 'Inter',
              decoration: TextDecoration.none,
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Bottom actions
// ─────────────────────────────────────────────────────────────────────────────

class _BottomActions extends StatelessWidget {
  const _BottomActions({
    required this.primaryLabel,
    required this.secondaryLabel,
    required this.isLight,
    required this.fg,
    required this.busy,
    required this.granted,
    required this.onPrimary,
    required this.onSecondary,
  });

  final String primaryLabel;
  final String secondaryLabel;
  final bool isLight;
  final Color fg;
  final bool busy;
  final bool granted;
  final VoidCallback onPrimary, onSecondary;

  @override
  Widget build(BuildContext context) {
    final btnBg = isLight ? const Color(0xFF0A0A0A) : Colors.white;
    final btnFg = isLight ? Colors.white : const Color(0xFF0A0A0A);

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Granted status chip
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            child: granted
                ? Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.check_circle_rounded,
                          color: Color(0xFF03DAC6),
                          size: 18,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Permission granted',
                          style: TextStyle(
                            color: fg.withValues(alpha: 0.7),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            fontFamily: 'Inter',
                            decoration: TextDecoration.none,
                          ),
                        ),
                      ],
                    ),
                  )
                : const SizedBox.shrink(),
          ),

          // Primary button
          SizedBox(
            width: double.infinity,
            height: 54,
            child: _PressableButton(
              label: primaryLabel,
              busy: busy,
              backgroundColor: btnBg,
              foregroundColor: btnFg,
              onTap: onPrimary,
            ),
          ),

          const SizedBox(height: 16),

          // Secondary link
          GestureDetector(
            onTap: busy ? null : onSecondary,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(
                secondaryLabel,
                style: TextStyle(
                  color: fg.withValues(alpha: busy ? 0.2 : 0.45),
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  fontFamily: 'Inter',
                  decoration: TextDecoration.none,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Pressable button with spring-scale feedback + busy spinner
class _PressableButton extends StatefulWidget {
  const _PressableButton({
    required this.label,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.onTap,
    this.busy = false,
  });

  final String label;
  final Color backgroundColor, foregroundColor;
  final VoidCallback onTap;
  final bool busy;

  @override
  State<_PressableButton> createState() => _PressableButtonState();
}

class _PressableButtonState extends State<_PressableButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 130),
      reverseDuration: const Duration(milliseconds: 200),
    );
    _scale = Tween<double>(
      begin: 1,
      end: 0.965,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final disabled = widget.busy;

    return GestureDetector(
      onTapDown: disabled ? null : (_) => _ctrl.forward(),
      onTapUp: disabled
          ? null
          : (_) {
              _ctrl.reverse();
              widget.onTap();
            },
      onTapCancel: disabled ? null : () => _ctrl.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          decoration: BoxDecoration(
            color: widget.backgroundColor.withValues(alpha: disabled ? 0.6 : 1),
            borderRadius: BorderRadius.circular(14),
          ),
          alignment: Alignment.center,
          child: widget.busy
              ? SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.4,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(widget.foregroundColor),
                  ),
                )
              : Text(
                  widget.label,
                  style: TextStyle(
                    color: widget.foregroundColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Inter',
                    letterSpacing: -0.2,
                    decoration: TextDecoration.none,
                  ),
                ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Illustrations
// ─────────────────────────────────────────────────────────────────────────────

/// Screen 1 — large dark circle with waving-hand icon
class _WelcomeIllustration extends StatelessWidget {
  const _WelcomeIllustration();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      height: 220,
      decoration: const BoxDecoration(
        color: Color(0xFF0A0A0A),
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.waving_hand_rounded,
        color: Colors.white,
        size: 88,
      ),
    );
  }
}

/// Screen 2 — camera icon in a rounded card with a privacy shield
class _CameraIllustration extends StatelessWidget {
  const _CameraIllustration();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 140,
      height: 140,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: const Color(0xFFE4E4E4), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.07),
                  blurRadius: 24,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: const Icon(
              Icons.photo_camera_outlined,
              size: 54,
              color: Color(0xFF0A0A0A),
            ),
          ),
          Positioned(
            bottom: 0,
            right: 4,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFF03DAC6), // teal shield
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFF7F7F7), width: 4),
              ),
              child: const Icon(
                Icons.shield_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Screen 3 — Accessibility Service visual guide
class _AccessibilityIllustration extends StatelessWidget {
  const _AccessibilityIllustration();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 140,
      height: 140,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: const Color(0xFF222222),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF333333), width: 1.5),
            ),
            child: const Icon(
              Icons.settings_accessibility_rounded,
              color: Color(0xFFAAAAAA),
              size: 54,
            ),
          ),
          Positioned(
            bottom: 0,
            right: 4,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.accent, // purple badge
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.background, width: 4),
              ),
              child: const Icon(
                Icons.touch_app_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Screen 3 — two overlapping window cards on a dark background
class _OverlayIllustration extends StatelessWidget {
  const _OverlayIllustration();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200,
      height: 170,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Back card
          Positioned(
            bottom: 0,
            left: 0,
            child: Container(
              width: 140,
              height: 110,
              decoration: BoxDecoration(
                color: const Color(0xFF222222),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFF333333), width: 1.5),
              ),
            ),
          ),

          // Front card
          Positioned(
            top: 0,
            right: 0,
            child: Container(
              width: 140,
              height: 110,
              decoration: BoxDecoration(
                color: const Color(0xFF2E2E2E),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFF484848), width: 1.5),
              ),
              child: const Center(
                child: Icon(
                  Icons.picture_in_picture_alt_rounded,
                  color: Color(0xFFAAAAAA),
                  size: 40,
                ),
              ),
            ),
          ),

          // Permission badge (top-right corner of front card)
          Positioned(
            top: 0,
            right: 0,
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: const Color(0xFF585858),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.background, width: 2.5),
              ),
              child: const Icon(
                Icons.touch_app_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Screen 4 — stick-figure person + phone icons
class _CalibrationIllustration extends StatelessWidget {
  const _CalibrationIllustration();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Person
        const Icon(
          Icons.accessibility_new_rounded,
          size: 90,
          color: Color(0xFF0A0A0A),
        ),
        const SizedBox(height: 20),

        // Phone + distance label row
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Phone 1
            _PhoneOutline(),
            const SizedBox(width: 10),

            // Distance pill
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFD8D8D8), width: 1.5),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                '1–2 ft',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFFB0B0B0),
                  fontFamily: 'Inter',
                ),
              ),
            ),

            const SizedBox(width: 10),

            // Phone 2 (slightly smaller — the user's phone)
            _PhoneOutline(size: 48),
          ],
        ),
      ],
    );
  }
}

/// Screen 6 — app tile picker hint: a primary app card with a + badge
class _FirstProfileIllustration extends StatelessWidget {
  const _FirstProfileIllustration();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 160,
      height: 160,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 130,
            height: 130,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: const Color(0xFFE4E4E4), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.07),
                  blurRadius: 24,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: const Icon(
              Icons.apps_rounded,
              size: 58,
              color: Color(0xFF0A0A0A),
            ),
          ),
          Positioned(
            bottom: 4,
            right: 8,
            child: Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: AppColorsShared.accent,
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFF7F7F7), width: 4),
              ),
              child: const Icon(
                Icons.add_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PhoneOutline extends StatelessWidget {
  const _PhoneOutline({this.size = 60});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size * 0.55,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFCCCCCC), width: 2),
      ),
      child: Icon(
        Icons.smartphone_outlined,
        size: size * 0.45,
        color: const Color(0xFFCCCCCC),
      ),
    );
  }
}
