import 'package:flutter/services.dart';

class GestureChannel {
  static const _channel = MethodChannel('com.example.spartial_touch/gestures');
  static const _eventChannel = EventChannel('com.example.spartial_touch/gesture_events');

  static Future<void> startService() => _channel.invokeMethod('startService');
  static Future<void> stopService()  => _channel.invokeMethod('stopService');

  static Stream<String> get gestureStream =>
      _eventChannel.receiveBroadcastStream().map((e) => e as String);
}
