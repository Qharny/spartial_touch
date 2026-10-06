import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'gesture_channel.dart';

/// Persists the "active hours" daily window and hands it to the native service,
/// which pauses the camera outside the window.
///
/// The window used to be enforced by a Dart [Timer] that stopped and restarted
/// the service. That timer died with the Flutter engine whenever the app's UI was
/// closed, so active hours silently stopped working in the background; the
/// service now checks the window itself.
class ActiveHoursScheduler {
  ActiveHoursScheduler._();
  static final ActiveHoursScheduler instance = ActiveHoursScheduler._();

  static const _enabledKey  = 'active_hours_enabled';
  static const _startHourKey = 'active_hours_start_hour';
  static const _startMinKey  = 'active_hours_start_min';
  static const _endHourKey   = 'active_hours_end_hour';
  static const _endMinKey    = 'active_hours_end_min';

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
    await _pushToNative();
  }

  // ── Service lifecycle ───────────────────────────────────────────────────────

  /// Pushes the window to the native service and starts it. A start failure
  /// (e.g. CAMERA permission revoked) propagates to the caller — the Home
  /// toggle needs to know so it can revert its UI.
  Future<void> start_() async {
    await _pushToNative();
    await GestureChannel.startService();
  }

  /// Kept for callers that pair it with stopping the service; the native side
  /// stops checking the window when the service stops.
  void stop() {}

  Future<void> _pushToNative() async {
    final start = await getStartTime();
    final end = await getEndTime();
    await GestureChannel.setActiveHours(
      enabled: await isEnabled(),
      startMinutes: start.hour * 60 + start.minute,
      endMinutes: end.hour * 60 + end.minute,
    );
  }
}
