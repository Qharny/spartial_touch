import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/router/router.dart';
import '../../core/theme/theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Page data model
// ─────────────────────────────────────────────────────────────────────────────

enum _PageStyle { light, dark }

class _Page {
  const _Page({
    required this.style,
    required this.illustration,
    required this.title,
    required this.body,
    required this.primaryLabel,
    required this.secondaryLabel,
  });

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
    style: _PageStyle.light,
    illustration: _WelcomeIllustration(),
    title: 'Control with a Wave',
    body:
        'SpartialTouch lets you control your phone without touching the screen using advanced air gestures.',
    primaryLabel: 'Get Started',
    secondaryLabel: 'Skip tour',
  ),
  const _Page(
    style: _PageStyle.light,
    illustration: _CameraIllustration(),
    title: 'Spatial Camera',
    body:
        'We use the front camera to track hand movements. All processing happens on-device; no data ever leaves your phone.',
    primaryLabel: 'Allow Camera Access',
    secondaryLabel: 'Learn more about privacy',
  ),
  const _Page(
    style: _PageStyle.dark,
    illustration: _OverlayIllustration(),
    title: 'System Overlay',
    body:
        'Enable the overlay to see visual feedback when a gesture is recognized and keep the service active over other apps.',
    primaryLabel: 'Enable Overlay',
    secondaryLabel: 'Maybe later',
  ),
  const _Page(
    style: _PageStyle.light,
    illustration: _CalibrationIllustration(),
    title: 'Perfect Calibration',
    body:
        "Find a well-lit spot and place your phone about 1–2 feet away. We'll run a quick check to ensure gestures work perfectly.",
    primaryLabel: 'Start Calibration',
    secondaryLabel: "I'll do it later",
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

  // ── helpers ────────────────────────────────────────────────────────────────

  bool get _isLight => _pages[_page].style == _PageStyle.light;

  Color get _fg => _isLight ? const Color(0xFF0A0A0A) : Colors.white;
  Color get _bg => _isLight ? Colors.white : AppColors.background;

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

  void _finish() => Navigator.of(context).pushReplacementNamed(AppRoutes.shell);

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
                  page: _pages[_page],
                  isLight: _isLight,
                  fg: _fg,
                  onPrimary: _next,
                  onSecondary: _finish,
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
    required this.page,
    required this.isLight,
    required this.fg,
    required this.onPrimary,
    required this.onSecondary,
  });

  final _Page page;
  final bool isLight;
  final Color fg;
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
          // Primary button
          SizedBox(
            width: double.infinity,
            height: 54,
            child: _PressableButton(
              label: page.primaryLabel,
              backgroundColor: btnBg,
              foregroundColor: btnFg,
              onTap: onPrimary,
            ),
          ),

          const SizedBox(height: 16),

          // Secondary link
          GestureDetector(
            onTap: onSecondary,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(
                page.secondaryLabel,
                style: TextStyle(
                  color: fg.withValues(alpha: 0.45),
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

// Pressable button with spring-scale feedback
class _PressableButton extends StatefulWidget {
  const _PressableButton({
    required this.label,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.onTap,
  });

  final String label;
  final Color backgroundColor, foregroundColor;
  final VoidCallback onTap;

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
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) {
        _ctrl.reverse();
        widget.onTap();
      },
      onTapCancel: () => _ctrl.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          decoration: BoxDecoration(
            color: widget.backgroundColor,
            borderRadius: BorderRadius.circular(14),
          ),
          alignment: Alignment.center,
          child: Text(
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

/// Screen 2 — camera icon in a rounded card with subtle shadow
class _CameraIllustration extends StatelessWidget {
  const _CameraIllustration();

  @override
  Widget build(BuildContext context) {
    return Container(
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
