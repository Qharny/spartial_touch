import 'package:flutter/material.dart';
import '../../core/theme/theme.dart';

/// Standalone calibration wizard — reached from Settings ("Redo Calibration").
/// Mirrors the calibration step from onboarding but stands on its own so users
/// can re-run it any time. Both actions return to wherever they came from.
class CalibrationScreen extends StatefulWidget {
  const CalibrationScreen({super.key});

  @override
  State<CalibrationScreen> createState() => _CalibrationScreenState();
}

class _CalibrationScreenState extends State<CalibrationScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: cs.onSurface, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Calibration',
          style: TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w700,
            fontSize: 16,
            color: cs.onSurface,
          ),
        ),
        centerTitle: false,
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
        child: Column(
          children: [
            // ── Live calibration target ────────────────────────────────────
            Expanded(
              child: Center(
                child: AnimatedBuilder(
                  animation: _pulse,
                  builder: (context, child) {
                    final t = _pulse.value;
                    return Container(
                      width: 220 + 20 * t,
                      height: 220 + 20 * t,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColorsShared.accent.withValues(alpha: 0.08),
                        border: Border.all(
                          color: AppColorsShared.accent.withValues(alpha: 0.5 + 0.5 * t),
                          width: 2,
                        ),
                      ),
                      child: child,
                    );
                  },
                  child: Center(
                    child: Icon(
                      Icons.pan_tool_rounded,
                      size: 96,
                      color: cs.onSurface,
                    ),
                  ),
                ),
              ),
            ),

            // ── Title & instructions ───────────────────────────────────────
            Text(
              'Hold your hand steady',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 24,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Keep your hand at a natural distance while we re-measure lighting '
              'and distance thresholds for your environment.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                height: 1.5,
                color: cs.onSurfaceVariant,
              ),
            ),

            const SizedBox(height: 32),

            // ── Actions ─────────────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColorsShared.accent,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'Finish Calibration',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  color: cs.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
