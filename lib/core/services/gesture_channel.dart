import 'package:flutter/services.dart';

class GestureChannel {
  static const _channel = MethodChannel('kabuteyy.spartial_touch/gestures');
  static const _eventChannel = EventChannel('kabuteyy.spartial_touch/gesture_events');
  static const _cameraFrameChannel = EventChannel('kabuteyy.spartial_touch/camera_frames');
  static const _landmarkChannel = EventChannel('kabuteyy.spartial_touch/landmarks');

  static Future<void> startService() => _channel.invokeMethod('startService');
  static Future<void> stopService()  => _channel.invokeMethod('stopService');

  static Future<void> performAction(String action) => 
      _channel.invokeMethod('performAction', action);

  /// Push all profile mappings to the native ActionDispatcher.
  /// [profiles] is a map of packageName → {gestureKey → actionId}
  static Future<void> loadProfiles(Map<String, Map<String, String>> profiles) =>
      _channel.invokeMethod('loadProfiles', profiles);

  /// Push performance settings to the native gesture engine.
  /// [fps] — camera frames per second (5, 15 or 30)
  /// [cooldownMs] — minimum ms between gesture events (300–2000)
  static Future<void> setPerformanceMode({required int fps, required int cooldownMs}) =>
      _channel.invokeMethod('setPerformanceMode', {'fps': fps, 'cooldownMs': cooldownMs});

  /// Push calibration parameters to the native gesture engine.
  static Future<void> setCalibration({
    required double confidenceThreshold,
    required double motionThreshold,
  }) =>
      _channel.invokeMethod('setCalibration', {
        'confidenceThreshold': confidenceThreshold,
        'motionThreshold': motionThreshold,
      });

  /// Enable or disable haptic feedback on gesture detection.
  static Future<void> setHapticsEnabled(bool enabled) =>
      _channel.invokeMethod('setHapticsEnabled', enabled);

  /// Enable or disable SmartWake sensor gating dynamically.
  static Future<void> setSmartWakeEnabled(bool enabled) =>
      _channel.invokeMethod('setSmartWakeEnabled', enabled);

  /// Enable or disable a gesture dynamically.
  static Future<void> setGestureEnabled(String gestureKey, bool enabled) =>
      _channel.invokeMethod('setGestureEnabled', {
        'gestureKey': gestureKey,
        'enabled': enabled,
      });

  /// Whether SpatialTouchAccessibilityService is actually connected — i.e. the
  /// user has genuinely enabled it in system Accessibility settings, not just
  /// visited the settings screen. Dart can't observe this any other way.
  static Future<bool> isAccessibilityServiceEnabled() async {
    try {
      return await _channel.invokeMethod<bool>('isAccessibilityServiceEnabled') ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Whether the "Usage access" special permission is granted. Without it the native
  /// ForegroundAppMatcher can't tell which app is open, so per-app assignments never apply.
  static Future<bool> hasUsageAccess() async {
    try {
      return await _channel.invokeMethod<bool>('hasUsageAccess') ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Opens Android's Usage access settings screen.
  static Future<void> openUsageAccessSettings() =>
      _channel.invokeMethod('openUsageAccessSettings');

  /// Records the user's on/off choice natively, so a reboot can remind them to resume.
  static Future<void> setServiceEnabled(bool enabled) =>
      _channel.invokeMethod('setServiceEnabled', enabled);

  /// Whether the native gesture service is currently running.
  static Future<bool> isServiceRunning() async {
    try {
      return await _channel.invokeMethod<bool>('isServiceRunning') ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Floating overlay on/off and opacity (0.2–1.0).
  static Future<void> setOverlaySettings({required bool enabled, required double opacity}) =>
      _channel.invokeMethod('setOverlaySettings', {'enabled': enabled, 'opacity': opacity});

  /// A short click sound on each recognised gesture.
  static Future<void> setSoundsEnabled(bool enabled) =>
      _channel.invokeMethod('setSoundsEnabled', enabled);

  /// Ignore gestures while the phone is in a Do Not Disturb mode.
  static Future<void> setPauseInDnd(bool enabled) =>
      _channel.invokeMethod('setPauseInDnd', enabled);

  /// The user's Smart Wake (battery saver) preference. Not the same as
  /// [setSmartWakeEnabled], which screens use to force the camera on while open.
  static Future<void> setSmartWakePreference(bool enabled) =>
      _channel.invokeMethod('setSmartWakePreference', enabled);

  /// The daily window the service listens in. Enforced natively, so it keeps
  /// working after the app's UI is closed.
  static Future<void> setActiveHours({
    required bool enabled,
    required int startMinutes,
    required int endMinutes,
  }) =>
      _channel.invokeMethod('setActiveHours', {
        'enabled': enabled,
        'startMinutes': startMinutes,
        'endMinutes': endMinutes,
      });

  /// Per-gesture sensitivity, 0–1 (0.5 is the calibrated default).
  static Future<void> setGestureSensitivity(String gestureKey, double value) =>
      _channel.invokeMethod('setGestureSensitivity', {'gestureKey': gestureKey, 'value': value});

  /// Replaces the recorded custom poses the native matcher recognises.
  /// [json] is `[{"key": ..., "samples": [[x0, y0, ...], ...]}]`; [names] maps key → display name.
  static Future<void> setCustomPoses({required String json, required Map<String, String> names}) =>
      _channel.invokeMethod('setCustomPoses', {'json': json, 'names': names});

  /// Fetch active profile and gesture counts from the service.
  static Future<Map<String, dynamic>> getServiceStats() async {
    try {
      final Map<dynamic, dynamic>? res =
          await _channel.invokeMethod('getServiceStats');
      if (res != null) {
        return Map<String, dynamic>.from(res);
      }
    } catch (_) {}
    return {
      'activeProfile': 'Standby',
      'totalGestures': 0,
      'todayGestures': 0,
      'pausedBySchedule': false,
    };
  }

  // One shared stream per channel. Each receiveBroadcastStream() call registers its
  // own native listener and the native side keeps only one sink, so two screens
  // listening at once used to steal each other's events — and the first to cancel
  // cut everyone off. A single cached broadcast stream listens natively while
  // anyone in Dart listens.
  static final Stream<String> gestureStream =
      _eventChannel.receiveBroadcastStream().map((e) => e as String);

  static final Stream<Uint8List> cameraFrameStream =
      _cameraFrameChannel.receiveBroadcastStream().map((e) => e as Uint8List);

  /// `[x0, y0, ..., x20, y20, confidence]` per frame with a visible hand.
  static final Stream<List<double>> landmarkStream = _landmarkChannel
      .receiveBroadcastStream()
      .map((e) => (e as List).map((v) => (v as num).toDouble()).toList());
}
