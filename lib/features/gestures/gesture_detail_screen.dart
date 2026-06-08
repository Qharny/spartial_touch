import 'package:flutter/material.dart';
import '../../core/router/router.dart';

class GestureDetailScreen extends StatefulWidget {
  const GestureDetailScreen({super.key});

  @override
  State<GestureDetailScreen> createState() => _GestureDetailScreenState();
}

class _GestureDetailScreenState extends State<GestureDetailScreen> {
  double _sensitivity = 0.6;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Gesture Detail',
          style: TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w700,
            fontSize: 16,
            color: cs.onSurface,
          ),
        ),
        centerTitle: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close_rounded, color: cs.onSurface),
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
                color: cs.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: cs.outline),
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.pan_tool_outlined, size: 64, color: cs.onSurface),
                    const SizedBox(height: 8),
                    Icon(Icons.keyboard_double_arrow_up_rounded, size: 32, color: cs.onSurface),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // ── Title & Description ─────────────────────────────────────────
          Text(
            'Wave Up',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Quick upward motion with an open palm. Hold fingers steady for better detection.',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              color: cs.onSurfaceVariant,
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
              color: cs.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: cs.outline),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Low', style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
                    Text('High', style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
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
                    activeColor: cs.onSurface,
                    inactiveColor: cs.outline,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Higher sensitivity makes the gesture easier to trigger but may increase accidental activations.',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    color: cs.onSurfaceVariant,
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
              color: cs.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: cs.outline),
            ),
            child: Row(
              children: [
                Icon(Icons.keyboard_double_arrow_up_rounded, color: cs.onSurfaceVariant, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Scroll Up',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: cs.onSurface,
                    ),
                  ),
                ),
                Icon(Icons.keyboard_arrow_down_rounded, color: cs.onSurfaceVariant),
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
                  border: Border.all(color: cs.outline),
                ),
                child: Text(
                  'Add App',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface,
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
                decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: cs.onSurfaceVariant)),
              ),
              const SizedBox(width: 12),
              Container(
                width: 16, height: 4,
                decoration: BoxDecoration(color: cs.onSurface, borderRadius: BorderRadius.circular(2)),
              ),
              const SizedBox(width: 12),
              Container(
                width: 8, height: 8,
                decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: cs.onSurfaceVariant)),
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
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Space Mono',
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.0,
              color: cs.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: cs.onSurface,
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
    final cs = Theme.of(context).colorScheme;

    return Text(
      title,
      style: TextStyle(
        fontFamily: 'Inter',
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: cs.onSurface,
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
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outline),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: cs.onSurface),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  appName,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  action,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: cs.onSurfaceVariant),
        ],
      ),
    );
  }
}
