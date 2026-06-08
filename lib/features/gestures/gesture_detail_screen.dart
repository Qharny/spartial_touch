import 'package:flutter/material.dart';
import '../../core/router/router.dart';
import '../../core/theme/theme.dart';

class GestureDetailScreen extends StatefulWidget {
  const GestureDetailScreen({super.key});

  @override
  State<GestureDetailScreen> createState() => _GestureDetailScreenState();
}

class _GestureDetailScreenState extends State<GestureDetailScreen> {
  double _sensitivity = 0.6;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Gesture Detail',
          style: TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w700,
            fontSize: 16,
            color: Colors.white,
          ),
        ),
        centerTitle: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        children: [
          // ── Gesture Large Icon ──────────────────────────────────────────
          GestureDetector(
            onTap: () => Navigator.of(context).pushNamed(AppRoutes.gestureTester),
            child: Container(
              height: 220,
              decoration: BoxDecoration(
                color: const Color(0xFF111118),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.outline),
              ),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.pan_tool_outlined, size: 64, color: Colors.white),
                    SizedBox(height: 8),
                    Icon(Icons.keyboard_double_arrow_up_rounded, size: 32, color: Colors.white),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // ── Title & Description ─────────────────────────────────────────
          const Text(
            'Wave Up',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Quick upward motion with an open palm. Hold fingers steady for better detection.',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              color: Color(0xFFB0B0C0),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 24),

          // ── Stats ────────────────────────────────────────────────────────
          const Row(
            children: [
              Expanded(
                child: _StatCard(
                  label: 'ACCURACY',
                  value: '98.4%',
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: _StatCard(
                  label: 'DAILY USAGE',
                  value: '142',
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // ── Sensitivity ──────────────────────────────────────────────────
          const _SectionHeader(title: 'Sensitivity'),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.outline),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Low', style: TextStyle(fontSize: 12, color: Color(0xFF7A7890))),
                    Text('High', style: TextStyle(fontSize: 12, color: Color(0xFF7A7890))),
                  ],
                ),
                const SizedBox(height: 8),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 4,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
                  ),
                  child: Slider(
                    value: _sensitivity,
                    onChanged: (v) => setState(() => _sensitivity = v),
                    activeColor: Colors.white,
                    inactiveColor: const Color(0xFF2A2A3A),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Higher sensitivity makes the gesture easier to trigger but may increase accidental activations.',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    color: Color(0xFFB0B0C0),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // ── Global Action ────────────────────────────────────────────────
          const _SectionHeader(title: 'Global Action'),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.outline),
            ),
            child: const Row(
              children: [
                Icon(Icons.keyboard_double_arrow_up_rounded, color: Color(0xFF7A7890), size: 20),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Scroll Up',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
                Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF7A7890)),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // ── App Overrides ────────────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const _SectionHeader(title: 'App Overrides'),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.outline),
                ),
                child: const Text(
                  'Add App',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const _AppOverrideCard(
            appName: 'Spotify',
            action: 'Next Song',
            icon: Icons.music_note_rounded,
          ),
          const SizedBox(height: 12),
          const _AppOverrideCard(
            appName: 'Chrome',
            action: 'Refresh Page',
            icon: Icons.language_rounded,
          ),

          const SizedBox(height: 48),

          // ── Bottom Dots (Mocked Pager Indicator) ──────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 8, height: 8,
                decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: const Color(0xFF7A7890))),
              ),
              const SizedBox(width: 12),
              Container(
                width: 16, height: 4,
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(2)),
              ),
              const SizedBox(width: 12),
              Container(
                width: 8, height: 8,
                decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: const Color(0xFF7A7890))),
              ),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Space Mono',
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.0,
              color: Color(0xFF7A7890),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontFamily: 'Inter',
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: Colors.white,
      ),
    );
  }
}

class _AppOverrideCard extends StatelessWidget {
  const _AppOverrideCard({
    required this.appName,
    required this.action,
    required this.icon,
  });

  final String appName;
  final String action;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.outline),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFF111118),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: Colors.white),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  appName,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  action,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    color: Color(0xFF7A7890),
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: Color(0xFF7A7890)),
        ],
      ),
    );
  }
}
