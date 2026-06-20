import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spartial_touch/core/services/calibration_service.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('CalibrationService.isCalibrated', () {
    test('returns false when no calibration has been saved', () async {
      final result = await CalibrationService.instance.isCalibrated();
      expect(result, isFalse);
    });

    test('returns true after save() is called', () async {
      await CalibrationService.instance.save(
        confidenceThreshold: 0.80,
        motionThreshold: 0.15,
      );
      final result = await CalibrationService.instance.isCalibrated();
      expect(result, isTrue);
    });

    test('returns false after reset()', () async {
      await CalibrationService.instance.save(
        confidenceThreshold: 0.80,
        motionThreshold: 0.15,
      );
      await CalibrationService.instance.reset();
      final result = await CalibrationService.instance.isCalibrated();
      expect(result, isFalse);
    });
  });

  group('CalibrationService.getConfidenceThreshold', () {
    test('returns default 0.75 when nothing is saved', () async {
      final result = await CalibrationService.instance.getConfidenceThreshold();
      expect(result, equals(0.75));
    });

    test('returns the saved value after save()', () async {
      await CalibrationService.instance.save(
        confidenceThreshold: 0.85,
        motionThreshold: 0.12,
      );
      final result = await CalibrationService.instance.getConfidenceThreshold();
      expect(result, equals(0.85));
    });

    test('clamps saved value to minimum 0.50', () async {
      await CalibrationService.instance.save(
        confidenceThreshold: 0.10, // below minimum
        motionThreshold: 0.12,
      );
      final result = await CalibrationService.instance.getConfidenceThreshold();
      expect(result, equals(0.50));
    });

    test('clamps saved value to maximum 0.95', () async {
      await CalibrationService.instance.save(
        confidenceThreshold: 0.99, // above maximum
        motionThreshold: 0.12,
      );
      final result = await CalibrationService.instance.getConfidenceThreshold();
      expect(result, equals(0.95));
    });

    test('accepts boundary value 0.50', () async {
      await CalibrationService.instance.save(
        confidenceThreshold: 0.50,
        motionThreshold: 0.12,
      );
      final result = await CalibrationService.instance.getConfidenceThreshold();
      expect(result, equals(0.50));
    });

    test('accepts boundary value 0.95', () async {
      await CalibrationService.instance.save(
        confidenceThreshold: 0.95,
        motionThreshold: 0.12,
      );
      final result = await CalibrationService.instance.getConfidenceThreshold();
      expect(result, equals(0.95));
    });

    test('returns default after reset()', () async {
      await CalibrationService.instance.save(
        confidenceThreshold: 0.90,
        motionThreshold: 0.12,
      );
      await CalibrationService.instance.reset();
      final result = await CalibrationService.instance.getConfidenceThreshold();
      expect(result, equals(0.75));
    });
  });

  group('CalibrationService.getMotionThreshold', () {
    test('returns default 0.12 when nothing is saved', () async {
      final result = await CalibrationService.instance.getMotionThreshold();
      expect(result, equals(0.12));
    });

    test('returns the saved value after save()', () async {
      await CalibrationService.instance.save(
        confidenceThreshold: 0.75,
        motionThreshold: 0.20,
      );
      final result = await CalibrationService.instance.getMotionThreshold();
      expect(result, equals(0.20));
    });

    test('clamps motion threshold to minimum 0.06', () async {
      await CalibrationService.instance.save(
        confidenceThreshold: 0.75,
        motionThreshold: 0.01, // below minimum
      );
      final result = await CalibrationService.instance.getMotionThreshold();
      expect(result, equals(0.06));
    });

    test('clamps motion threshold to maximum 0.25', () async {
      await CalibrationService.instance.save(
        confidenceThreshold: 0.75,
        motionThreshold: 0.50, // above maximum
      );
      final result = await CalibrationService.instance.getMotionThreshold();
      expect(result, equals(0.25));
    });

    test('accepts boundary value 0.06', () async {
      await CalibrationService.instance.save(
        confidenceThreshold: 0.75,
        motionThreshold: 0.06,
      );
      final result = await CalibrationService.instance.getMotionThreshold();
      expect(result, equals(0.06));
    });

    test('accepts boundary value 0.25', () async {
      await CalibrationService.instance.save(
        confidenceThreshold: 0.75,
        motionThreshold: 0.25,
      );
      final result = await CalibrationService.instance.getMotionThreshold();
      expect(result, equals(0.25));
    });

    test('returns default after reset()', () async {
      await CalibrationService.instance.save(
        confidenceThreshold: 0.75,
        motionThreshold: 0.20,
      );
      await CalibrationService.instance.reset();
      final result = await CalibrationService.instance.getMotionThreshold();
      expect(result, equals(0.12));
    });
  });

  group('CalibrationService.save', () {
    test('save persists both thresholds simultaneously', () async {
      await CalibrationService.instance.save(
        confidenceThreshold: 0.82,
        motionThreshold: 0.18,
      );
      final confidence = await CalibrationService.instance.getConfidenceThreshold();
      final motion = await CalibrationService.instance.getMotionThreshold();
      expect(confidence, equals(0.82));
      expect(motion, equals(0.18));
    });

    test('successive save() calls overwrite previous values', () async {
      await CalibrationService.instance.save(
        confidenceThreshold: 0.70,
        motionThreshold: 0.10,
      );
      await CalibrationService.instance.save(
        confidenceThreshold: 0.90,
        motionThreshold: 0.22,
      );
      final confidence = await CalibrationService.instance.getConfidenceThreshold();
      final motion = await CalibrationService.instance.getMotionThreshold();
      expect(confidence, equals(0.90));
      expect(motion, equals(0.22));
    });
  });

  group('CalibrationService.reset', () {
    test('reset clears all three stored keys', () async {
      await CalibrationService.instance.save(
        confidenceThreshold: 0.88,
        motionThreshold: 0.19,
      );
      await CalibrationService.instance.reset();

      expect(await CalibrationService.instance.isCalibrated(), isFalse);
      expect(await CalibrationService.instance.getConfidenceThreshold(), equals(0.75));
      expect(await CalibrationService.instance.getMotionThreshold(), equals(0.12));
    });

    test('reset on fresh state is a no-op (no errors thrown)', () async {
      // Should not throw even when nothing was saved
      await expectLater(
        CalibrationService.instance.reset(),
        completes,
      );
    });
  });
}