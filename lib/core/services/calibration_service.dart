import 'package:shared_preferences/shared_preferences.dart';

/// Stores and loads calibration parameters that tailor gesture detection
/// to the user's specific environment, hand size, and lighting conditions.
class CalibrationService {
  CalibrationService._();
  static final CalibrationService instance = CalibrationService._();

  static const _thresholdKey = 'calib_confidence_threshold';
  static const _motionKey    = 'calib_motion_threshold';
  static const _doneKey      = 'calib_completed';

  // ── Getters ─────────────────────────────────────────────────────────────────

  Future<bool> isCalibrated() async {
    final p = await SharedPreferences.getInstance();
    return p.getBool(_doneKey) ?? false;
  }

  /// Confidence threshold [0.50 – 0.95]. Default 0.75.
  Future<double> getConfidenceThreshold() async {
    final p = await SharedPreferences.getInstance();
    return p.getDouble(_thresholdKey) ?? 0.75;
  }

  /// Motion threshold as a normalised landmark delta [0.06 – 0.25]. Default 0.12.
  Future<double> getMotionThreshold() async {
    final p = await SharedPreferences.getInstance();
    return p.getDouble(_motionKey) ?? 0.12;
  }

  // ── Save ────────────────────────────────────────────────────────────────────

  Future<void> save({
    required double confidenceThreshold,
    required double motionThreshold,
  }) async {
    final p = await SharedPreferences.getInstance();
    await Future.wait([
      p.setDouble(_thresholdKey, confidenceThreshold.clamp(0.50, 0.95)),
      p.setDouble(_motionKey,    motionThreshold.clamp(0.06, 0.25)),
      p.setBool(_doneKey, true),
    ]);
  }

  Future<void> reset() async {
    final p = await SharedPreferences.getInstance();
    await Future.wait([
      p.remove(_thresholdKey),
      p.remove(_motionKey),
      p.remove(_doneKey),
    ]);
  }
}
