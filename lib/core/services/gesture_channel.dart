import 'package:flutter/services.dart';

class GestureChannel {
  static const _channel = MethodChannel('com.example.spartial_touch/gestures');
  static const _eventChannel = EventChannel('com.example.spartial_touch/gesture_events');
  static const _cameraFrameChannel = EventChannel('com.example.spartial_touch/camera_frames');

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

  static Stream<String> get gestureStream =>
      _eventChannel.receiveBroadcastStream().map((e) => e as String);

  static Stream<Uint8List> get cameraFrameStream =>
      _cameraFrameChannel.receiveBroadcastStream().map((e) => e as Uint8List);
}
