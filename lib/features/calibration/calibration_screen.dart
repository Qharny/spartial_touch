import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../main.dart';
import '../../core/theme/theme.dart';
import '../../core/services/calibration_service.dart';
import '../../core/services/gesture_channel.dart';

/// Standalone calibration wizard — reached from Settings ("Redo Calibration").
class CalibrationScreen extends StatefulWidget {
  const CalibrationScreen({super.key});

  @override
  State<CalibrationScreen> createState() => _CalibrationScreenState();
}

class _CalibrationScreenState extends State<CalibrationScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;
  double _confidenceThreshold = 0.75;
  double _motionThreshold = 0.12;
  bool _saving = false;

  String _detectedGesture = 'Waiting...';
  double _detectedConfidence = 0.0;
  StreamSubscription? _gestureSub;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _loadSaved();

    // Start listening to the gesture engine and camera frames
    gestureRecognitionService.startListening();
    _gestureSub = gestureRecognitionService.gestureStream.listen((event) {
      if (mounted) {
        setState(() {
          _detectedGesture = event.name;
          _detectedConfidence = event.confidence;
        });
      }
    });
  }

  Future<void> _loadSaved() async {
    final ct = await CalibrationService.instance.getConfidenceThreshold();
    final mt = await CalibrationService.instance.getMotionThreshold();
    if (mounted) {
      setState(() {
        _confidenceThreshold = ct;
        _motionThreshold = mt;
      });
    }
  }

  Future<void> _saveAndApply() async {
    setState(() => _saving = true);
    await CalibrationService.instance.save(
      confidenceThreshold: _confidenceThreshold,
      motionThreshold: _motionThreshold,
    );
    await GestureChannel.setCalibration(
      confidenceThreshold: _confidenceThreshold,
      motionThreshold: _motionThreshold,
    );
    if (mounted) {
      setState(() => _saving = false);
      Navigator.of(context).pop(true); // true = calibration completed
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    _gestureSub?.cancel();
    gestureRecognitionService.stopListening();
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
            // ── Live Camera Feed ──────────────────────────────────────────────
            Expanded(
              child: Center(
                child: Container(
                  width: 220,
                  height: 220,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColorsShared.accent,
                      width: 3,
                    ),
                  ),
                  child: ClipOval(
                    child: StreamBuilder<Uint8List>(
                      stream: GestureChannel.cameraFrameStream,
                      builder: (context, snapshot) {
                        if (snapshot.hasData) {
                          return RotatedBox(
                            quarterTurns: 1, // Rotate 90 degrees for portrait
                            child: Transform.scale(
                              scaleX: -1, // Mirror front camera
                              child: Image.memory(
                                snapshot.data!,
                                fit: BoxFit.cover,
                                gaplessPlayback: true,
                              ),
                            ),
                          );
                        }
                        return Center(
                          child: Icon(
                            Icons.videocam_off_rounded,
                            size: 64,
                            color: cs.onSurfaceVariant.withValues(alpha: 0.4),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _detectedGesture,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: cs.onSurface,
              ),
            ),
            if (_detectedGesture != 'Waiting...' && _detectedGesture != 'None') ...[
              const SizedBox(height: 4),
              Text(
                '${(_detectedConfidence * 100).toInt()}% CONFIDENCE',
                style: TextStyle(
                  fontFamily: 'Space Mono',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColorsShared.accent,
                  letterSpacing: 1.0,
                ),
              ),
            ],
            const SizedBox(height: 24),

            // ── Confidence slider ─────────────────────────────────────────────
            _SliderRow(
              label: 'Confidence Threshold',
              value: _confidenceThreshold,
              min: 0.50,
              max: 0.95,
              divisions: 9,
              display: '${(_confidenceThreshold * 100).round()}%',
              onChanged: (v) => setState(() => _confidenceThreshold = v),
            ),
            const SizedBox(height: 8),

            // ── Motion threshold slider ───────────────────────────────────────
            _SliderRow(
              label: 'Motion Sensitivity',
              value: _motionThreshold,
              min: 0.06,
              max: 0.25,
              divisions: 19,
              display: _motionThreshold.toStringAsFixed(2),
              onChanged: (v) => setState(() => _motionThreshold = v),
            ),
            const SizedBox(height: 28),

            // ── Save button ──────────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _saving ? null : _saveAndApply,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColorsShared.accent,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _saving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Save & Apply',
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

class _SliderRow extends StatelessWidget {
  const _SliderRow({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.display,
    required this.onChanged,
  });

  final String label;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final String display;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurfaceVariant)),
            Text(display,
                style: TextStyle(
                    fontFamily: 'Space Mono',
                    fontSize: 13,
                    color: AppColorsShared.accent)),
          ],
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: divisions,
          activeColor: AppColorsShared.accent,
          onChanged: onChanged,
        ),
      ],
    );
  }
}
