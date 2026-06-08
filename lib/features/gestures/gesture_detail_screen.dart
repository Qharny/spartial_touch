import 'package:flutter/material.dart';
import '../../core/theme/theme.dart';

class GestureDetailScreen extends StatefulWidget {
  const GestureDetailScreen({super.key});

  @override
  State<GestureDetailScreen> createState() => _GestureDetailScreenState();
}

class _GestureDetailScreenState extends State<GestureDetailScreen> {
  double _sensitivity = 0.5;
  double _confidence = 0.8;
  double _cooldown = 0.5;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Wave Up',
          style: TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 48),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Animated Demo Area ─────────────────────────────────────────
            Container(
              width: double.infinity,
              height: 200,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.outline),
              ),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.arrow_upward_rounded,
                        size: 64, color: AppColors.accent),
                    SizedBox(height: 16),
                    Text(
                      'Animation Demo Placeholder',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        color: Color(0xFF7A7890),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),

            // ── Sliders & Inputs ───────────────────────────────────────────
            const Text(
              'CONFIGURATION',
              style: TextStyle(
                fontFamily: 'Space Mono',
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.0,
                color: Color(0xFF7A7890),
              ),
            ),
            const SizedBox(height: 16),

            // Sensitivity
            _ConfigSlider(
              label: 'Sensitivity',
              value: _sensitivity,
              minLabel: 'Low',
              maxLabel: 'High',
              onChanged: (v) => setState(() => _sensitivity = v),
            ),
            const SizedBox(height: 24),

            // Confidence
            _ConfigSlider(
              label: 'Confidence Threshold',
              value: _confidence,
              minLabel: 'Strict',
              maxLabel: 'Lenient',
              onChanged: (v) => setState(() => _confidence = v),
            ),
            const SizedBox(height: 24),

            // Cooldown
            _ConfigSlider(
              label: 'Cooldown Time',
              value: _cooldown,
              minLabel: '0.1s',
              maxLabel: '2.0s',
              onChanged: (v) => setState(() => _cooldown = v),
            ),

            const SizedBox(height: 48),

            // ── Action Buttons ─────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.videocam_outlined),
                label: const Text('Test Live Detection'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  textStyle: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: OutlinedButton(
                onPressed: () {
                  setState(() {
                    _sensitivity = 0.5;
                    _confidence = 0.8;
                    _cooldown = 0.5;
                  });
                },
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.outline),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Reset to Defaults',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
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

class _ConfigSlider extends StatelessWidget {
  const _ConfigSlider({
    required this.label,
    required this.value,
    required this.minLabel,
    required this.maxLabel,
    required this.onChanged,
  });

  final String label;
  final double value;
  final String minLabel;
  final String maxLabel;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 4,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
          ),
          child: Slider(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.accent,
            inactiveColor: AppColors.surfaceVariant,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                minLabel,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  color: Color(0xFF7A7890),
                ),
              ),
              Text(
                maxLabel,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  color: Color(0xFF7A7890),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
