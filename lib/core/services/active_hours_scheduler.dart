import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'gesture_channel.dart';

/// Persists and enforces "active hours" — the daily time window during which
/// the gesture service is allowed to run.
///
/// When outside the active window, [ActiveHoursScheduler] stops the service
/// and starts a timer to restart it when the window opens again.
class ActiveHoursScheduler {
  ActiveHoursScheduler._();
  static final ActiveHoursScheduler instance = ActiveHoursScheduler._();

  static const _enabledKey  = 'active_hours_enabled';
  static const _startHourKey = 'active_hours_start_hour';
  static const _startMinKey  = 'active_hours_start_min';
  static const _endHourKey   = 'active_hours_end_hour';
  static const _endMinKey    = 'active_hours_end_min';

  Timer? _checkTimer;

  // ── Persistence ─────────────────────────────────────────────────────────────

  Future<bool> isEnabled() async {
    final p = await SharedPreferences.getInstance();
    return p.getBool(_enabledKey) ?? false;
  }

  Future<TimeOfDay> getStartTime() async {
    final p = await SharedPreferences.getInstance();
    return TimeOfDay(
      hour:   p.getInt(_startHourKey) ?? 8,
      minute: p.getInt(_startMinKey)  ?? 0,
    );
  }

  Future<TimeOfDay> getEndTime() async {
    final p = await SharedPreferences.getInstance();
    return TimeOfDay(
      hour:   p.getInt(_endHourKey) ?? 22,
      minute: p.getInt(_endMinKey)  ?? 0,
    );
  }

  Future<void> save({
    required bool enabled,
    required TimeOfDay start,
    required TimeOfDay end,
  }) async {
    final p = await SharedPreferences.getInstance();
    await Future.wait([
      p.setBool(_enabledKey,   enabled),
      p.setInt(_startHourKey,  start.hour),
      p.setInt(_startMinKey,   start.minute),
      p.setInt(_endHourKey,    end.hour),
      p.setInt(_endMinKey,     end.minute),
    ]);
    // Restart the scheduler with new settings
    await start_();
  }

  // ── Scheduler lifecycle ──────────────────────────────────────────────────────

  /// Start the polling loop that checks every minute whether we are in the
  /// active window and starts/stops the gesture service accordingly.
  Future<void> start_() async {
    _checkTimer?.cancel();
    if (!await isEnabled()) {
      // Active hours not configured — ensure service is running freely
      await GestureChannel.startService();
      return;
    }
    // Check immediately then every 60 seconds
    await _check();
    _checkTimer = Timer.periodic(const Duration(seconds: 60), (_) => _check());
  }

  void stop() {
    _checkTimer?.cancel();
    _checkTimer = null;
  }

  Future<void> _check() async {
    final enabled = await isEnabled();
    if (!enabled) return;

    final now   = TimeOfDay.now();
    final start = await getStartTime();
    final end   = await getEndTime();

    if (_isInWindow(now, start, end)) {
      await GestureChannel.startService();
    } else {
      await GestureChannel.stopService();
    }
  }

  /// Returns true if [now] falls within the [start]–[end] window.
  /// Handles overnight windows (e.g. 22:00 – 06:00).
  bool _isInWindow(TimeOfDay now, TimeOfDay start, TimeOfDay end) {
    final nowMins   = now.hour   * 60 + now.minute;
    final startMins = start.hour * 60 + start.minute;
    final endMins   = end.hour   * 60 + end.minute;

    if (startMins <= endMins) {
      // Normal window: 08:00 – 22:00
      return nowMins >= startMins && nowMins < endMins;
    } else {
      // Overnight window: 22:00 – 06:00
      return nowMins >= startMins || nowMins < endMins;
    }
  }
}
