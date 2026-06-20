import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:spartial_touch/core/services/calibration_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  // ── Default values ─────────────────────────────────────────────────────────

  group('CalibrationService defaults', () {
    test('isCalibrated returns false when no calibration saved', () async {
      final result = await CalibrationService.instance.isCalibrated();
      expect(result, isFalse);
    });

    test('getConfidenceThreshold returns 0.75 by default', () async {
      final result = await CalibrationService.instance.getConfidenceThreshold();
      expect(result, equals(0.75));
    });

    test('getMotionThreshold returns 0.12 by default', () async {
      final result = await CalibrationService.instance.getMotionThreshold();
      expect(result, equals(0.12));
    });
  });

  // ── Save and retrieve ───────────────────────────────────────────────────────

  group('CalibrationService.save', () {
    test('save marks isCalibrated as true', () async {
      await CalibrationService.instance.save(
        confidenceThreshold: 0.80,
        motionThreshold: 0.15,
      );
      final calibrated = await CalibrationService.instance.isCalibrated();
      expect(calibrated, isTrue);
    });

    test('save persists confidence threshold within valid range', () async {
      await CalibrationService.instance.save(
        confidenceThreshold: 0.80,
        motionThreshold: 0.15,
      );
      final result = await CalibrationService.instance.getConfidenceThreshold();
      expect(result, closeTo(0.80, 0.001));
    });

    test('save persists motion threshold within valid range', () async {
      await CalibrationService.instance.save(
        confidenceThreshold: 0.80,
        motionThreshold: 0.18,
      );
      final result = await CalibrationService.instance.getMotionThreshold();
      expect(result, closeTo(0.18, 0.001));
    });

    test('save overwrites previously saved calibration values', () async {
      await CalibrationService.instance.save(
        confidenceThreshold: 0.70,
        motionThreshold: 0.10,
      );
      await CalibrationService.instance.save(
        confidenceThreshold: 0.85,
        motionThreshold: 0.20,
      );
      expect(
        await CalibrationService.instance.getConfidenceThreshold(),
        closeTo(0.85, 0.001),
      );
      expect(
        await CalibrationService.instance.getMotionThreshold(),
        closeTo(0.20, 0.001),
      );
    });
  });

  // ── Clamping ───────────────────────────────────────────────────────────────

  group('CalibrationService.save clamping — confidence threshold', () {
    test('confidence below 0.50 is clamped to 0.50', () async {
      await CalibrationService.instance.save(
        confidenceThreshold: 0.30,
        motionThreshold: 0.12,
      );
      final result = await CalibrationService.instance.getConfidenceThreshold();
      expect(result, closeTo(0.50, 0.001));
    });

    test('confidence above 0.95 is clamped to 0.95', () async {
      await CalibrationService.instance.save(
        confidenceThreshold: 0.99,
        motionThreshold: 0.12,
      );
      final result = await CalibrationService.instance.getConfidenceThreshold();
      expect(result, closeTo(0.95, 0.001));
    });

    test('confidence at lower boundary 0.50 is not clamped', () async {
      await CalibrationService.instance.save(
        confidenceThreshold: 0.50,
        motionThreshold: 0.12,
      );
      final result = await CalibrationService.instance.getConfidenceThreshold();
      expect(result, closeTo(0.50, 0.001));
    });

    test('confidence at upper boundary 0.95 is not clamped', () async {
      await CalibrationService.instance.save(
        confidenceThreshold: 0.95,
        motionThreshold: 0.12,
      );
      final result = await CalibrationService.instance.getConfidenceThreshold();
      expect(result, closeTo(0.95, 0.001));
    });

    test('confidence of 0.0 is clamped to 0.50 (hard floor)', () async {
      await CalibrationService.instance.save(
        confidenceThreshold: 0.0,
        motionThreshold: 0.12,
      );
      final result = await CalibrationService.instance.getConfidenceThreshold();
      expect(result, closeTo(0.50, 0.001));
    });

    test('confidence of 1.0 is clamped to 0.95 (hard ceiling)', () async {
      await CalibrationService.instance.save(
        confidenceThreshold: 1.0,
        motionThreshold: 0.12,
      );
      final result = await CalibrationService.instance.getConfidenceThreshold();
      expect(result, closeTo(0.95, 0.001));
    });
  });

  group('CalibrationService.save clamping — motion threshold', () {
    test('motion below 0.06 is clamped to 0.06', () async {
      await CalibrationService.instance.save(
        confidenceThreshold: 0.75,
        motionThreshold: 0.01,
      );
      final result = await CalibrationService.instance.getMotionThreshold();
      expect(result, closeTo(0.06, 0.001));
    });

    test('motion above 0.25 is clamped to 0.25', () async {
      await CalibrationService.instance.save(
        confidenceThreshold: 0.75,
        motionThreshold: 0.30,
      );
      final result = await CalibrationService.instance.getMotionThreshold();
      expect(result, closeTo(0.25, 0.001));
    });

    test('motion at lower boundary 0.06 is not clamped', () async {
      await CalibrationService.instance.save(
        confidenceThreshold: 0.75,
        motionThreshold: 0.06,
      );
      final result = await CalibrationService.instance.getMotionThreshold();
      expect(result, closeTo(0.06, 0.001));
    });

    test('motion at upper boundary 0.25 is not clamped', () async {
      await CalibrationService.instance.save(
        confidenceThreshold: 0.75,
        motionThreshold: 0.25,
      );
      final result = await CalibrationService.instance.getMotionThreshold();
      expect(result, closeTo(0.25, 0.001));
    });

    test('motion of 0.0 is clamped to 0.06 (hard floor)', () async {
      await CalibrationService.instance.save(
        confidenceThreshold: 0.75,
        motionThreshold: 0.0,
      );
      final result = await CalibrationService.instance.getMotionThreshold();
      expect(result, closeTo(0.06, 0.001));
    });
  });

  // ── Reset ──────────────────────────────────────────────────────────────────

  group('CalibrationService.reset', () {
    test('reset after save makes isCalibrated return false', () async {
      await CalibrationService.instance.save(
        confidenceThreshold: 0.80,
        motionThreshold: 0.15,
      );
      await CalibrationService.instance.reset();
      final calibrated = await CalibrationService.instance.isCalibrated();
      expect(calibrated, isFalse);
    });

    test('reset restores confidence threshold to default 0.75', () async {
      await CalibrationService.instance.save(
        confidenceThreshold: 0.90,
        motionThreshold: 0.15,
      );
      await CalibrationService.instance.reset();
      final result = await CalibrationService.instance.getConfidenceThreshold();
      expect(result, equals(0.75));
    });

    test('reset restores motion threshold to default 0.12', () async {
      await CalibrationService.instance.save(
        confidenceThreshold: 0.80,
        motionThreshold: 0.20,
      );
      await CalibrationService.instance.reset();
      final result = await CalibrationService.instance.getMotionThreshold();
      expect(result, equals(0.12));
    });

    test('reset on a clean state does not throw', () async {
      expect(
        () async => CalibrationService.instance.reset(),
        returnsNormally,
      );
    });

    test('can save again after reset', () async {
      await CalibrationService.instance.save(
        confidenceThreshold: 0.80,
        motionThreshold: 0.15,
      );
      await CalibrationService.instance.reset();
      await CalibrationService.instance.save(
        confidenceThreshold: 0.65,
        motionThreshold: 0.10,
      );
      expect(
        await CalibrationService.instance.isCalibrated(),
        isTrue,
      );
      expect(
        await CalibrationService.instance.getConfidenceThreshold(),
        closeTo(0.65, 0.001),
      );
    });
  });

  // ── Shared key names ───────────────────────────────────────────────────────

  group('CalibrationService pref key verification', () {
    test('save writes to calib_confidence_threshold key', () async {
      await CalibrationService.instance.save(
        confidenceThreshold: 0.80,
        motionThreshold: 0.15,
      );
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getDouble('calib_confidence_threshold'), closeTo(0.80, 0.001));
    });

    test('save writes to calib_motion_threshold key', () async {
      await CalibrationService.instance.save(
        confidenceThreshold: 0.80,
        motionThreshold: 0.18,
      );
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getDouble('calib_motion_threshold'), closeTo(0.18, 0.001));
    });

    test('save writes true to calib_completed key', () async {
      await CalibrationService.instance.save(
        confidenceThreshold: 0.80,
        motionThreshold: 0.15,
      );
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('calib_completed'), isTrue);
    });
  });
}