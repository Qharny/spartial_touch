import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:spartial_touch/core/services/gesture_channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('com.example.spartial_touch/gestures');

  // Collect all MethodCall invocations for assertion.
  final List<MethodCall> capturedCalls = [];

  setUp(() {
    capturedCalls.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall call) async {
      capturedCalls.add(call);
      return null;
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  // ── setPerformanceMode ─────────────────────────────────────────────────────

  group('GestureChannel.setPerformanceMode', () {
    test('invokes setPerformanceMode on the method channel', () async {
      await GestureChannel.setPerformanceMode(fps: 15, cooldownMs: 800);

      expect(capturedCalls, hasLength(1));
      expect(capturedCalls.first.method, equals('setPerformanceMode'));
    });

    test('passes fps argument correctly', () async {
      await GestureChannel.setPerformanceMode(fps: 30, cooldownMs: 300);

      final args = capturedCalls.first.arguments as Map;
      expect(args['fps'], equals(30));
    });

    test('passes cooldownMs argument correctly', () async {
      await GestureChannel.setPerformanceMode(fps: 5, cooldownMs: 2000);

      final args = capturedCalls.first.arguments as Map;
      expect(args['cooldownMs'], equals(2000));
    });

    test('passes both fps and cooldownMs in the same call', () async {
      await GestureChannel.setPerformanceMode(fps: 15, cooldownMs: 800);

      final args = capturedCalls.first.arguments as Map;
      expect(args['fps'], equals(15));
      expect(args['cooldownMs'], equals(800));
    });

    test('battery-saver preset values are forwarded correctly', () async {
      await GestureChannel.setPerformanceMode(fps: 5, cooldownMs: 2000);

      final args = capturedCalls.first.arguments as Map;
      expect(args['fps'], equals(5));
      expect(args['cooldownMs'], equals(2000));
    });

    test('performance preset values are forwarded correctly', () async {
      await GestureChannel.setPerformanceMode(fps: 30, cooldownMs: 300);

      final args = capturedCalls.first.arguments as Map;
      expect(args['fps'], equals(30));
      expect(args['cooldownMs'], equals(300));
    });
  });

  // ── setCalibration ─────────────────────────────────────────────────────────

  group('GestureChannel.setCalibration', () {
    test('invokes setCalibration on the method channel', () async {
      await GestureChannel.setCalibration(
        confidenceThreshold: 0.80,
        motionThreshold: 0.15,
      );

      expect(capturedCalls, hasLength(1));
      expect(capturedCalls.first.method, equals('setCalibration'));
    });

    test('passes confidenceThreshold argument correctly', () async {
      await GestureChannel.setCalibration(
        confidenceThreshold: 0.80,
        motionThreshold: 0.15,
      );

      final args = capturedCalls.first.arguments as Map;
      expect(args['confidenceThreshold'], closeTo(0.80, 0.001));
    });

    test('passes motionThreshold argument correctly', () async {
      await GestureChannel.setCalibration(
        confidenceThreshold: 0.80,
        motionThreshold: 0.18,
      );

      final args = capturedCalls.first.arguments as Map;
      expect(args['motionThreshold'], closeTo(0.18, 0.001));
    });

    test('both calibration arguments are sent in the same invocation', () async {
      await GestureChannel.setCalibration(
        confidenceThreshold: 0.75,
        motionThreshold: 0.12,
      );

      final args = capturedCalls.first.arguments as Map;
      expect(args['confidenceThreshold'], closeTo(0.75, 0.001));
      expect(args['motionThreshold'], closeTo(0.12, 0.001));
    });

    test('passes boundary confidence value 0.50 without modification', () async {
      await GestureChannel.setCalibration(
        confidenceThreshold: 0.50,
        motionThreshold: 0.06,
      );

      final args = capturedCalls.first.arguments as Map;
      expect(args['confidenceThreshold'], closeTo(0.50, 0.001));
    });

    test('passes boundary confidence value 0.95 without modification', () async {
      await GestureChannel.setCalibration(
        confidenceThreshold: 0.95,
        motionThreshold: 0.25,
      );

      final args = capturedCalls.first.arguments as Map;
      expect(args['confidenceThreshold'], closeTo(0.95, 0.001));
    });
  });

  // ── setHapticsEnabled ──────────────────────────────────────────────────────

  group('GestureChannel.setHapticsEnabled', () {
    test('invokes setHapticsEnabled on the method channel', () async {
      await GestureChannel.setHapticsEnabled(true);

      expect(capturedCalls, hasLength(1));
      expect(capturedCalls.first.method, equals('setHapticsEnabled'));
    });

    test('passes true as the argument when enabling haptics', () async {
      await GestureChannel.setHapticsEnabled(true);

      expect(capturedCalls.first.arguments, isTrue);
    });

    test('passes false as the argument when disabling haptics', () async {
      await GestureChannel.setHapticsEnabled(false);

      expect(capturedCalls.first.arguments, isFalse);
    });

    test('each call results in exactly one channel invocation', () async {
      await GestureChannel.setHapticsEnabled(true);
      await GestureChannel.setHapticsEnabled(false);

      expect(capturedCalls, hasLength(2));
    });

    test('toggling haptics sends two separate invocations with correct values', () async {
      await GestureChannel.setHapticsEnabled(true);
      await GestureChannel.setHapticsEnabled(false);

      expect(capturedCalls[0].arguments, isTrue);
      expect(capturedCalls[1].arguments, isFalse);
    });
  });

  // ── Channel name invariant ─────────────────────────────────────────────────

  group('GestureChannel channel name', () {
    test('setPerformanceMode uses the correct channel name', () async {
      bool invoked = false;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        invoked = true;
        return null;
      });

      await GestureChannel.setPerformanceMode(fps: 15, cooldownMs: 800);
      expect(invoked, isTrue);
    });

    test('setCalibration uses the correct channel name', () async {
      bool invoked = false;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        invoked = true;
        return null;
      });

      await GestureChannel.setCalibration(
        confidenceThreshold: 0.75,
        motionThreshold: 0.12,
      );
      expect(invoked, isTrue);
    });

    test('setHapticsEnabled uses the correct channel name', () async {
      bool invoked = false;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        invoked = true;
        return null;
      });

      await GestureChannel.setHapticsEnabled(true);
      expect(invoked, isTrue);
    });
  });
}