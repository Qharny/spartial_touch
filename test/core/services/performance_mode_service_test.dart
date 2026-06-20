import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:spartial_touch/core/services/performance_mode_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  // ── PerformanceModeX extension ─────────────────────────────────────────────

  group('PerformanceModeX.fps', () {
    test('batterySaver returns 5 fps', () {
      expect(PerformanceMode.batterySaver.fps, equals(5));
    });

    test('balanced returns 15 fps', () {
      expect(PerformanceMode.balanced.fps, equals(15));
    });

    test('performance returns 30 fps', () {
      expect(PerformanceMode.performance.fps, equals(30));
    });
  });

  group('PerformanceModeX.cooldownMs', () {
    test('batterySaver cooldown is 2000 ms', () {
      expect(PerformanceMode.batterySaver.cooldownMs, equals(2000));
    });

    test('balanced cooldown is 800 ms', () {
      expect(PerformanceMode.balanced.cooldownMs, equals(800));
    });

    test('performance cooldown is 300 ms', () {
      expect(PerformanceMode.performance.cooldownMs, equals(300));
    });

    test('fps and cooldownMs are inversely related (higher fps = lower cooldown)', () {
      expect(PerformanceMode.batterySaver.fps < PerformanceMode.balanced.fps, isTrue);
      expect(PerformanceMode.balanced.fps < PerformanceMode.performance.fps, isTrue);
      expect(PerformanceMode.batterySaver.cooldownMs > PerformanceMode.balanced.cooldownMs, isTrue);
      expect(PerformanceMode.balanced.cooldownMs > PerformanceMode.performance.cooldownMs, isTrue);
    });
  });

  group('PerformanceModeX.label', () {
    test('batterySaver label is Battery Saver', () {
      expect(PerformanceMode.batterySaver.label, equals('Battery Saver'));
    });

    test('balanced label is Balanced', () {
      expect(PerformanceMode.balanced.label, equals('Balanced'));
    });

    test('performance label is Performance', () {
      expect(PerformanceMode.performance.label, equals('Performance'));
    });

    test('all modes have non-empty labels', () {
      for (final mode in PerformanceMode.values) {
        expect(mode.label, isNotEmpty);
      }
    });
  });

  group('PerformanceModeX.description', () {
    test('batterySaver description mentions 5 FPS and 2000 ms', () {
      expect(PerformanceMode.batterySaver.description, contains('5 FPS'));
      expect(PerformanceMode.batterySaver.description, contains('2000 ms'));
    });

    test('balanced description mentions 15 FPS and 800 ms', () {
      expect(PerformanceMode.balanced.description, contains('15 FPS'));
      expect(PerformanceMode.balanced.description, contains('800 ms'));
    });

    test('performance description mentions 30 FPS and 300 ms', () {
      expect(PerformanceMode.performance.description, contains('30 FPS'));
      expect(PerformanceMode.performance.description, contains('300 ms'));
    });

    test('all modes have non-empty descriptions', () {
      for (final mode in PerformanceMode.values) {
        expect(mode.description, isNotEmpty);
      }
    });
  });

  // ── PerformanceModeService persistence ────────────────────────────────────

  group('PerformanceModeService.load', () {
    test('returns balanced when no preference is stored', () async {
      SharedPreferences.setMockInitialValues({});
      final mode = await PerformanceModeService.load();
      expect(mode, equals(PerformanceMode.balanced));
    });

    test('returns balanced when stored value is unrecognised', () async {
      SharedPreferences.setMockInitialValues({'performance_mode': 'unknown_mode'});
      final mode = await PerformanceModeService.load();
      expect(mode, equals(PerformanceMode.balanced));
    });

    test('returns batterySaver when stored value matches enum name', () async {
      SharedPreferences.setMockInitialValues({'performance_mode': 'batterySaver'});
      final mode = await PerformanceModeService.load();
      expect(mode, equals(PerformanceMode.batterySaver));
    });

    test('returns performance when stored value matches enum name', () async {
      SharedPreferences.setMockInitialValues({'performance_mode': 'performance'});
      final mode = await PerformanceModeService.load();
      expect(mode, equals(PerformanceMode.performance));
    });

    test('load returns balanced when stored value is empty string', () async {
      SharedPreferences.setMockInitialValues({'performance_mode': ''});
      final mode = await PerformanceModeService.load();
      expect(mode, equals(PerformanceMode.balanced));
    });
  });

  group('PerformanceModeService.save', () {
    test('save then load returns the same mode for batterySaver', () async {
      await PerformanceModeService.save(PerformanceMode.batterySaver);
      final loaded = await PerformanceModeService.load();
      expect(loaded, equals(PerformanceMode.batterySaver));
    });

    test('save then load returns the same mode for balanced', () async {
      await PerformanceModeService.save(PerformanceMode.balanced);
      final loaded = await PerformanceModeService.load();
      expect(loaded, equals(PerformanceMode.balanced));
    });

    test('save then load returns the same mode for performance', () async {
      await PerformanceModeService.save(PerformanceMode.performance);
      final loaded = await PerformanceModeService.load();
      expect(loaded, equals(PerformanceMode.performance));
    });

    test('saving a new mode overwrites the previous one', () async {
      await PerformanceModeService.save(PerformanceMode.batterySaver);
      await PerformanceModeService.save(PerformanceMode.performance);
      final loaded = await PerformanceModeService.load();
      expect(loaded, equals(PerformanceMode.performance));
    });

    test('save persists the mode name string, not an index', () async {
      await PerformanceModeService.save(PerformanceMode.balanced);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('performance_mode'), equals('balanced'));
    });
  });

  group('PerformanceMode enum coverage', () {
    test('all three modes are distinct', () {
      final modes = PerformanceMode.values.toSet();
      expect(modes.length, equals(3));
    });

    test('PerformanceMode.values contains batterySaver, balanced, performance', () {
      expect(PerformanceMode.values, containsAll([
        PerformanceMode.batterySaver,
        PerformanceMode.balanced,
        PerformanceMode.performance,
      ]));
    });
  });
}
