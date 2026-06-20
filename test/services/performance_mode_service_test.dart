import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spartial_touch/core/services/performance_mode_service.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  // ── PerformanceModeX extension ─────────────────────────────────────────────

  group('PerformanceModeX.label', () {
    test('batterySaver has correct label', () {
      expect(PerformanceMode.batterySaver.label, equals('Battery Saver'));
    });

    test('balanced has correct label', () {
      expect(PerformanceMode.balanced.label, equals('Balanced'));
    });

    test('performance has correct label', () {
      expect(PerformanceMode.performance.label, equals('Performance'));
    });
  });

  group('PerformanceModeX.fps', () {
    test('batterySaver fps is 5', () {
      expect(PerformanceMode.batterySaver.fps, equals(5));
    });

    test('balanced fps is 15', () {
      expect(PerformanceMode.balanced.fps, equals(15));
    });

    test('performance fps is 30', () {
      expect(PerformanceMode.performance.fps, equals(30));
    });

    test('all modes have positive fps', () {
      for (final mode in PerformanceMode.values) {
        expect(mode.fps, greaterThan(0), reason: '${mode.name} fps must be positive');
      }
    });

    test('fps increases with mode intensity', () {
      expect(PerformanceMode.batterySaver.fps, lessThan(PerformanceMode.balanced.fps));
      expect(PerformanceMode.balanced.fps, lessThan(PerformanceMode.performance.fps));
    });
  });

  group('PerformanceModeX.cooldownMs', () {
    test('batterySaver cooldownMs is 2000', () {
      expect(PerformanceMode.batterySaver.cooldownMs, equals(2000));
    });

    test('balanced cooldownMs is 800', () {
      expect(PerformanceMode.balanced.cooldownMs, equals(800));
    });

    test('performance cooldownMs is 300', () {
      expect(PerformanceMode.performance.cooldownMs, equals(300));
    });

    test('cooldownMs decreases with mode intensity', () {
      expect(PerformanceMode.batterySaver.cooldownMs,
          greaterThan(PerformanceMode.balanced.cooldownMs));
      expect(PerformanceMode.balanced.cooldownMs,
          greaterThan(PerformanceMode.performance.cooldownMs));
    });

    test('all modes have positive cooldownMs', () {
      for (final mode in PerformanceMode.values) {
        expect(mode.cooldownMs, greaterThan(0),
            reason: '${mode.name} cooldownMs must be positive');
      }
    });
  });

  group('PerformanceModeX.description', () {
    test('batterySaver description contains fps and cooldown info', () {
      final desc = PerformanceMode.batterySaver.description;
      expect(desc, contains('5 FPS'));
      expect(desc, contains('2000 ms'));
    });

    test('balanced description contains fps and cooldown info', () {
      final desc = PerformanceMode.balanced.description;
      expect(desc, contains('15 FPS'));
      expect(desc, contains('800 ms'));
    });

    test('performance description contains fps and cooldown info', () {
      final desc = PerformanceMode.performance.description;
      expect(desc, contains('30 FPS'));
      expect(desc, contains('300 ms'));
    });

    test('all modes have non-empty description', () {
      for (final mode in PerformanceMode.values) {
        expect(mode.description, isNotEmpty,
            reason: '${mode.name} must have a description');
      }
    });
  });

  // ── PerformanceModeService persistence ────────────────────────────────────

  group('PerformanceModeService.load', () {
    test('returns balanced as default when nothing is saved', () async {
      final mode = await PerformanceModeService.load();
      expect(mode, equals(PerformanceMode.balanced));
    });

    test('returns batterySaver after saving batterySaver', () async {
      await PerformanceModeService.save(PerformanceMode.batterySaver);
      final mode = await PerformanceModeService.load();
      expect(mode, equals(PerformanceMode.batterySaver));
    });

    test('returns balanced after saving balanced', () async {
      await PerformanceModeService.save(PerformanceMode.balanced);
      final mode = await PerformanceModeService.load();
      expect(mode, equals(PerformanceMode.balanced));
    });

    test('returns performance after saving performance', () async {
      await PerformanceModeService.save(PerformanceMode.performance);
      final mode = await PerformanceModeService.load();
      expect(mode, equals(PerformanceMode.performance));
    });

    test('falls back to balanced for unknown stored value', () async {
      // Simulate a corrupted or removed mode name
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('performance_mode', 'unknownMode');
      final mode = await PerformanceModeService.load();
      expect(mode, equals(PerformanceMode.balanced));
    });

    test('falls back to balanced for empty string stored value', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('performance_mode', '');
      final mode = await PerformanceModeService.load();
      expect(mode, equals(PerformanceMode.balanced));
    });
  });

  group('PerformanceModeService.save', () {
    test('save persists mode name correctly for batterySaver', () async {
      await PerformanceModeService.save(PerformanceMode.batterySaver);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('performance_mode'), equals('batterySaver'));
    });

    test('save persists mode name correctly for balanced', () async {
      await PerformanceModeService.save(PerformanceMode.balanced);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('performance_mode'), equals('balanced'));
    });

    test('save persists mode name correctly for performance', () async {
      await PerformanceModeService.save(PerformanceMode.performance);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('performance_mode'), equals('performance'));
    });

    test('successive saves overwrite previous value', () async {
      await PerformanceModeService.save(PerformanceMode.batterySaver);
      await PerformanceModeService.save(PerformanceMode.performance);
      final mode = await PerformanceModeService.load();
      expect(mode, equals(PerformanceMode.performance));
    });
  });

  group('PerformanceMode enum coverage', () {
    test('enum has exactly 3 values', () {
      expect(PerformanceMode.values.length, equals(3));
    });

    test('enum names match expected identifiers', () {
      final names = PerformanceMode.values.map((m) => m.name).toList();
      expect(names, containsAll(['batterySaver', 'balanced', 'performance']));
    });
  });
}
