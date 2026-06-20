import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spartial_touch/core/services/gesture_channel.dart';

void main() {
  const gestureChannel = MethodChannel('com.example.spartial_touch/gestures');

  // Captured calls so we can assert on method name and arguments
  final List<MethodCall> capturedCalls = [];

  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  setUp(() {
    capturedCalls.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(gestureChannel, (call) async {
      capturedCalls.add(call);
      return null;
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(gestureChannel, null);
  });

  // ── setPerformanceMode ────────────────────────────────────────────────────

  group('GestureChannel.setPerformanceMode', () {
    test('invokes setPerformanceMode method on the channel', () async {
      await GestureChannel.setPerformanceMode(fps: 15, cooldownMs: 800);

      expect(capturedCalls.length, equals(1));
      expect(capturedCalls.first.method, equals('setPerformanceMode'));
    });

    test('sends correct fps and cooldownMs arguments', () async {
      await GestureChannel.setPerformanceMode(fps: 30, cooldownMs: 300);

      final args = capturedCalls.first.arguments as Map;
      expect(args['fps'], equals(30));
      expect(args['cooldownMs'], equals(300));
    });

    test('sends batterySaver fps=5 and cooldownMs=2000', () async {
      await GestureChannel.setPerformanceMode(fps: 5, cooldownMs: 2000);

      final args = capturedCalls.first.arguments as Map;
      expect(args['fps'], equals(5));
      expect(args['cooldownMs'], equals(2000));
    });

    test('sends balanced fps=15 and cooldownMs=800', () async {
      await GestureChannel.setPerformanceMode(fps: 15, cooldownMs: 800);

      final args = capturedCalls.first.arguments as Map;
      expect(args['fps'], equals(15));
      expect(args['cooldownMs'], equals(800));
    });

    test('sends performance fps=30 and cooldownMs=300', () async {
      await GestureChannel.setPerformanceMode(fps: 30, cooldownMs: 300);

      final args = capturedCalls.first.arguments as Map;
      expect(args['fps'], equals(30));
      expect(args['cooldownMs'], equals(300));
    });

    test('arguments map contains exactly fps and cooldownMs keys', () async {
      await GestureChannel.setPerformanceMode(fps: 15, cooldownMs: 800);

      final args = capturedCalls.first.arguments as Map;
      expect(args.keys.toSet(), equals({'fps', 'cooldownMs'}));
    });

    test('returns a Future that completes', () async {
      await expectLater(
        GestureChannel.setPerformanceMode(fps: 15, cooldownMs: 800),
        completes,
      );
    });
  });

  // ── setCalibration ────────────────────────────────────────────────────────

  group('GestureChannel.setCalibration', () {
    test('invokes setCalibration method on the channel', () async {
      await GestureChannel.setCalibration(
        confidenceThreshold: 0.75,
        motionThreshold: 0.12,
      );

      expect(capturedCalls.length, equals(1));
      expect(capturedCalls.first.method, equals('setCalibration'));
    });

    test('sends correct confidenceThreshold and motionThreshold', () async {
      await GestureChannel.setCalibration(
        confidenceThreshold: 0.85,
        motionThreshold: 0.18,
      );

      final args = capturedCalls.first.arguments as Map;
      expect(args['confidenceThreshold'], equals(0.85));
      expect(args['motionThreshold'], equals(0.18));
    });

    test('arguments map contains exactly confidenceThreshold and motionThreshold keys',
        () async {
      await GestureChannel.setCalibration(
        confidenceThreshold: 0.75,
        motionThreshold: 0.12,
      );

      final args = capturedCalls.first.arguments as Map;
      expect(args.keys.toSet(), equals({'confidenceThreshold', 'motionThreshold'}));
    });

    test('sends boundary confidence threshold 0.50', () async {
      await GestureChannel.setCalibration(
        confidenceThreshold: 0.50,
        motionThreshold: 0.06,
      );

      final args = capturedCalls.first.arguments as Map;
      expect(args['confidenceThreshold'], equals(0.50));
    });

    test('sends boundary confidence threshold 0.95', () async {
      await GestureChannel.setCalibration(
        confidenceThreshold: 0.95,
        motionThreshold: 0.25,
      );

      final args = capturedCalls.first.arguments as Map;
      expect(args['confidenceThreshold'], equals(0.95));
    });

    test('returns a Future that completes', () async {
      await expectLater(
        GestureChannel.setCalibration(
          confidenceThreshold: 0.75,
          motionThreshold: 0.12,
        ),
        completes,
      );
    });
  });

  // ── setHapticsEnabled ─────────────────────────────────────────────────────

  group('GestureChannel.setHapticsEnabled', () {
    test('invokes setHapticsEnabled method on the channel', () async {
      await GestureChannel.setHapticsEnabled(true);

      expect(capturedCalls.length, equals(1));
      expect(capturedCalls.first.method, equals('setHapticsEnabled'));
    });

    test('sends true as argument when enabling haptics', () async {
      await GestureChannel.setHapticsEnabled(true);

      expect(capturedCalls.first.arguments, isTrue);
    });

    test('sends false as argument when disabling haptics', () async {
      await GestureChannel.setHapticsEnabled(false);

      expect(capturedCalls.first.arguments, isFalse);
    });

    test('returns a Future that completes when enabling', () async {
      await expectLater(GestureChannel.setHapticsEnabled(true), completes);
    });

    test('returns a Future that completes when disabling', () async {
      await expectLater(GestureChannel.setHapticsEnabled(false), completes);
    });

    test('each call generates exactly one channel invocation', () async {
      await GestureChannel.setHapticsEnabled(true);
      await GestureChannel.setHapticsEnabled(false);
      await GestureChannel.setHapticsEnabled(true);

      expect(capturedCalls.length, equals(3));
      expect(capturedCalls[0].arguments, isTrue);
      expect(capturedCalls[1].arguments, isFalse);
      expect(capturedCalls[2].arguments, isTrue);
    });
  });

  // ── Channel name correctness ──────────────────────────────────────────────

  group('GestureChannel channel name', () {
    test('all new methods use the correct channel name', () async {
      // Verify calls land on our mock (if wrong channel name, capturedCalls stays empty)
      await GestureChannel.setPerformanceMode(fps: 15, cooldownMs: 800);
      await GestureChannel.setCalibration(
          confidenceThreshold: 0.75, motionThreshold: 0.12);
      await GestureChannel.setHapticsEnabled(true);

      expect(capturedCalls.length, equals(3));
    });
  });
}