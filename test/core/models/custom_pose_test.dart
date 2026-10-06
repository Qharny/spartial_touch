import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spartial_touch/core/models/custom_pose.dart';
import 'package:spartial_touch/core/services/gesture_recognition_service.dart';

/// Synthetic open hand (wrist at [cx], [cy]) — same shape as the Kotlin tests use.
List<double> openHand({double cx = 0.5, double cy = 0.8, double size = 0.2}) {
  const base = <double>[
    0, 0, -0.3, -0.2, -0.5, -0.45, -0.65, -0.65, -0.8, -0.85,
    -0.3, -0.9, -0.35, -1.3, -0.38, -1.55, -0.4, -1.8,
    0, -1, 0, -1.45, 0, -1.75, 0, -2,
    0.25, -0.95, 0.3, -1.35, 0.33, -1.6, 0.35, -1.8,
    0.45, -0.8, 0.55, -1.1, 0.6, -1.3, 0.65, -1.45,
  ];
  return [for (var i = 0; i < base.length; i++) (i.isEven ? cx : cy) + base[i] * size];
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PoseMath', () {
    test('normalize is position- and scale-invariant', () {
      final a = PoseMath.normalize(openHand(cx: 0.3, cy: 0.6, size: 0.1))!;
      final b = PoseMath.normalize(openHand(cx: 0.7, cy: 0.9, size: 0.3))!;
      expect(PoseMath.distance(a, b), lessThan(1e-9));
      expect(a[0], 0);
      expect(a[1], 0);
    });

    test('normalize rejects bad input', () {
      expect(PoseMath.normalize([1, 2, 3]), isNull);
      expect(PoseMath.normalize(List.filled(42, 0.5)), isNull);
    });

    test('jitter is zero for a perfectly still hand and grows with movement', () {
      final still = List.generate(10, (_) => openHand());
      expect(PoseMath.jitter(still), closeTo(0, 1e-9));

      final shaky = List.generate(10, (i) {
        final h = openHand();
        h[16] += (i.isEven ? 0.05 : -0.05); // index fingertip x wobbles
        return h;
      });
      expect(PoseMath.jitter(shaky), greaterThan(0.01));
    });

    test('average of identical frames is that frame', () {
      final h = openHand();
      final avg = PoseMath.average([h, h, h]);
      for (var i = 0; i < h.length; i++) {
        expect(avg[i], closeTo(h[i], 1e-12));
      }
    });
  });

  group('CustomPoseStore', () {
    late List<MethodCall> calls;

    setUp(() {
      SharedPreferences.setMockInitialValues({
        'custom_gestures': ['{"name":"old"}'], // legacy, never detectable
      });
      calls = [];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('kabuteyy.spartial_touch/gestures'),
        (call) async {
          calls.add(call);
          return null;
        },
      );
    });

    test('load drops legacy name-only gestures', () async {
      final poses = await CustomPoseStore.instance.load();
      expect(poses, isEmpty);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getStringList('custom_gestures'), isNull);
    });

    test('add persists the pose, pushes it natively and resolves its name', () async {
      await CustomPoseStore.instance.add(
        CustomPose(key: 'CUSTOM_1', name: 'Peace Sign', samples: [openHand()]),
      );

      final reloaded = await CustomPoseStore.instance.load();
      expect(reloaded.single.name, 'Peace Sign');
      expect(reloaded.single.samples.single.length, 42);

      final push = calls.lastWhere((c) => c.method == 'setCustomPoses');
      final args = Map<String, dynamic>.from(push.arguments as Map);
      expect((jsonDecode(args['json'] as String) as List).single['key'], 'CUSTOM_1');
      expect(args['names'], {'CUSTOM_1': 'Peace Sign'});

      expect(CustomPoseStore.instance.nameFor('CUSTOM_1'), 'Peace Sign');
      expect(CustomPoseStore.instance.nameFor('WAVE_UP'), isNull);
      expect(GestureEvent.fromPayload('CUSTOM_1:0.9100').name, 'Peace Sign');
      expect(GestureEvent.fromPayload('CUSTOM_1:0.9100').key, 'CUSTOM_1');
    });
  });

  group('GestureEvent.fromPayload', () {
    test('formats built-in keys and parses confidence', () {
      final e = GestureEvent.fromPayload('TWO_FINGER_SWIPE_LEFT:0.8800');
      expect(e.name, 'Two Finger Swipe Left');
      expect(e.key, 'TWO_FINGER_SWIPE_LEFT');
      expect(e.confidence, closeTo(0.88, 1e-9));
    });
  });
}
