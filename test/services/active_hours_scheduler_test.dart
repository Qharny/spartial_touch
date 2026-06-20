import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import 'package:spartial_touch/core/services/active_hours_scheduler.dart';

/// Mirrors the private _isInWindow logic from ActiveHoursScheduler so we can
/// unit-test the window boundary conditions without accessing private members.
bool isInWindow(TimeOfDay now, TimeOfDay start, TimeOfDay end) {
  final nowMins   = now.hour   * 60 + now.minute;
  final startMins = start.hour * 60 + start.minute;
  final endMins   = end.hour   * 60 + end.minute;

  if (startMins <= endMins) {
    return nowMins >= startMins && nowMins < endMins;
  } else {
    return nowMins >= startMins || nowMins < endMins;
  }
}

void main() {
  // Mock the GestureChannel method channel so start_() / _check() don't throw
  const gestureChannel = MethodChannel('com.example.spartial_touch/gestures');
  final List<String> channelCalls = [];

  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(gestureChannel, (call) async {
      channelCalls.add(call.method);
      return null;
    });
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    channelCalls.clear();
    // Ensure the scheduler timer is cancelled between tests
    ActiveHoursScheduler.instance.stop();
  });

  tearDown(() {
    ActiveHoursScheduler.instance.stop();
  });

  // ── Persistence: isEnabled ────────────────────────────────────────────────

  group('ActiveHoursScheduler.isEnabled', () {
    test('defaults to false when no prefs stored', () async {
      final result = await ActiveHoursScheduler.instance.isEnabled();
      expect(result, isFalse);
    });

    test('returns true after save() with enabled=true', () async {
      await ActiveHoursScheduler.instance.save(
        enabled: true,
        start: const TimeOfDay(hour: 8, minute: 0),
        end: const TimeOfDay(hour: 22, minute: 0),
      );
      final result = await ActiveHoursScheduler.instance.isEnabled();
      expect(result, isTrue);
    });

    test('returns false after save() with enabled=false', () async {
      await ActiveHoursScheduler.instance.save(
        enabled: false,
        start: const TimeOfDay(hour: 8, minute: 0),
        end: const TimeOfDay(hour: 22, minute: 0),
      );
      final result = await ActiveHoursScheduler.instance.isEnabled();
      expect(result, isFalse);
    });
  });

  // ── Persistence: getStartTime ─────────────────────────────────────────────

  group('ActiveHoursScheduler.getStartTime', () {
    test('defaults to 08:00 when no prefs stored', () async {
      final result = await ActiveHoursScheduler.instance.getStartTime();
      expect(result.hour, equals(8));
      expect(result.minute, equals(0));
    });

    test('returns saved start time after save()', () async {
      await ActiveHoursScheduler.instance.save(
        enabled: true,
        start: const TimeOfDay(hour: 9, minute: 30),
        end: const TimeOfDay(hour: 22, minute: 0),
      );
      final result = await ActiveHoursScheduler.instance.getStartTime();
      expect(result.hour, equals(9));
      expect(result.minute, equals(30));
    });

    test('midnight start time (00:00) is persisted correctly', () async {
      await ActiveHoursScheduler.instance.save(
        enabled: true,
        start: const TimeOfDay(hour: 0, minute: 0),
        end: const TimeOfDay(hour: 6, minute: 0),
      );
      final result = await ActiveHoursScheduler.instance.getStartTime();
      expect(result.hour, equals(0));
      expect(result.minute, equals(0));
    });
  });

  // ── Persistence: getEndTime ───────────────────────────────────────────────

  group('ActiveHoursScheduler.getEndTime', () {
    test('defaults to 22:00 when no prefs stored', () async {
      final result = await ActiveHoursScheduler.instance.getEndTime();
      expect(result.hour, equals(22));
      expect(result.minute, equals(0));
    });

    test('returns saved end time after save()', () async {
      await ActiveHoursScheduler.instance.save(
        enabled: true,
        start: const TimeOfDay(hour: 8, minute: 0),
        end: const TimeOfDay(hour: 18, minute: 45),
      );
      final result = await ActiveHoursScheduler.instance.getEndTime();
      expect(result.hour, equals(18));
      expect(result.minute, equals(45));
    });

    test('end-of-day time (23:59) is persisted correctly', () async {
      await ActiveHoursScheduler.instance.save(
        enabled: true,
        start: const TimeOfDay(hour: 8, minute: 0),
        end: const TimeOfDay(hour: 23, minute: 59),
      );
      final result = await ActiveHoursScheduler.instance.getEndTime();
      expect(result.hour, equals(23));
      expect(result.minute, equals(59));
    });
  });

  // ── Persistence: save ─────────────────────────────────────────────────────

  group('ActiveHoursScheduler.save', () {
    test('persists all five fields atomically', () async {
      const start = TimeOfDay(hour: 7, minute: 15);
      const end   = TimeOfDay(hour: 21, minute: 45);

      await ActiveHoursScheduler.instance.save(
        enabled: true,
        start: start,
        end: end,
      );

      expect(await ActiveHoursScheduler.instance.isEnabled(), isTrue);
      final savedStart = await ActiveHoursScheduler.instance.getStartTime();
      final savedEnd   = await ActiveHoursScheduler.instance.getEndTime();

      expect(savedStart.hour,   equals(7));
      expect(savedStart.minute, equals(15));
      expect(savedEnd.hour,     equals(21));
      expect(savedEnd.minute,   equals(45));
    });

    test('successive save() calls overwrite previous values', () async {
      await ActiveHoursScheduler.instance.save(
        enabled: true,
        start: const TimeOfDay(hour: 8, minute: 0),
        end: const TimeOfDay(hour: 22, minute: 0),
      );
      await ActiveHoursScheduler.instance.save(
        enabled: false,
        start: const TimeOfDay(hour: 10, minute: 0),
        end: const TimeOfDay(hour: 20, minute: 0),
      );

      expect(await ActiveHoursScheduler.instance.isEnabled(), isFalse);
      final savedStart = await ActiveHoursScheduler.instance.getStartTime();
      expect(savedStart.hour, equals(10));
    });
  });

  // ── Scheduler: stop ───────────────────────────────────────────────────────

  group('ActiveHoursScheduler.stop', () {
    test('stop() does not throw when no timer is active', () {
      expect(() => ActiveHoursScheduler.instance.stop(), returnsNormally);
    });

    test('stop() can be called multiple times without error', () {
      ActiveHoursScheduler.instance.stop();
      ActiveHoursScheduler.instance.stop();
      // Should not throw
    });
  });

  // ── Scheduler: start_ when disabled ──────────────────────────────────────

  group('ActiveHoursScheduler.start_ when active hours disabled', () {
    test('start_() with disabled active hours calls startService', () async {
      // Active hours not enabled -> should just start the service freely
      SharedPreferences.setMockInitialValues({'active_hours_enabled': false});

      await ActiveHoursScheduler.instance.start_();
      ActiveHoursScheduler.instance.stop();

      expect(channelCalls, contains('startService'));
    });
  });

  // ── Window logic: _isInWindow (via mirrored function) ────────────────────

  group('_isInWindow (normal daytime window)', () {
    const start = TimeOfDay(hour: 8, minute: 0);
    const end   = TimeOfDay(hour: 22, minute: 0);

    test('time at start boundary is inside window', () {
      expect(isInWindow(const TimeOfDay(hour: 8, minute: 0), start, end), isTrue);
    });

    test('time well within window is inside', () {
      expect(isInWindow(const TimeOfDay(hour: 12, minute: 0), start, end), isTrue);
    });

    test('time one minute before end is inside window', () {
      expect(isInWindow(const TimeOfDay(hour: 21, minute: 59), start, end), isTrue);
    });

    test('time at end boundary is outside window (exclusive end)', () {
      expect(isInWindow(const TimeOfDay(hour: 22, minute: 0), start, end), isFalse);
    });

    test('time after end is outside window', () {
      expect(isInWindow(const TimeOfDay(hour: 23, minute: 0), start, end), isFalse);
    });

    test('time before start is outside window', () {
      expect(isInWindow(const TimeOfDay(hour: 7, minute: 59), start, end), isFalse);
    });

    test('midnight is outside a daytime window', () {
      expect(isInWindow(const TimeOfDay(hour: 0, minute: 0), start, end), isFalse);
    });
  });

  group('_isInWindow (overnight window)', () {
    // e.g. 22:00 – 06:00 (overnight)
    const start = TimeOfDay(hour: 22, minute: 0);
    const end   = TimeOfDay(hour: 6, minute: 0);

    test('time at overnight start boundary is inside window', () {
      expect(isInWindow(const TimeOfDay(hour: 22, minute: 0), start, end), isTrue);
    });

    test('late-night time is inside overnight window', () {
      expect(isInWindow(const TimeOfDay(hour: 23, minute: 30), start, end), isTrue);
    });

    test('midnight is inside overnight window', () {
      expect(isInWindow(const TimeOfDay(hour: 0, minute: 0), start, end), isTrue);
    });

    test('early morning within window is inside', () {
      expect(isInWindow(const TimeOfDay(hour: 5, minute: 59), start, end), isTrue);
    });

    test('time at end boundary is outside overnight window (exclusive)', () {
      expect(isInWindow(const TimeOfDay(hour: 6, minute: 0), start, end), isFalse);
    });

    test('daytime is outside overnight window', () {
      expect(isInWindow(const TimeOfDay(hour: 12, minute: 0), start, end), isFalse);
    });

    test('one minute before overnight start is outside window', () {
      expect(isInWindow(const TimeOfDay(hour: 21, minute: 59), start, end), isFalse);
    });
  });

  group('_isInWindow (edge cases)', () {
    test('single-minute window: exact minute is inside', () {
      const start = TimeOfDay(hour: 10, minute: 0);
      const end   = TimeOfDay(hour: 10, minute: 1);
      expect(isInWindow(const TimeOfDay(hour: 10, minute: 0), start, end), isTrue);
      expect(isInWindow(const TimeOfDay(hour: 10, minute: 1), start, end), isFalse);
    });

    test('same start and end (zero-duration window): nothing is inside', () {
      const t = TimeOfDay(hour: 12, minute: 0);
      // startMins == endMins -> no time can satisfy nowMins >= start && nowMins < end
      expect(isInWindow(t, t, t), isFalse);
    });
  });
}