import 'package:flutter/services.dart';

class GestureChannel {
  static const _channel = MethodChannel('com.example.spartial_touch/gestures');
  static const _eventChannel = EventChannel('com.example.spartial_touch/gesture_events');
  static const _cameraFrameChannel = EventChannel('com.example.spartial_touch/camera_frames');

  static Future<void> startService() => _channel.invokeMethod('startService');
  static Future<void> stopService()  => _channel.invokeMethod('stopService');

  static Future<void> performAction(String action) => 
      _channel.invokeMethod('performAction', action);

  static Stream<String> get gestureStream =>
      _eventChannel.receiveBroadcastStream().map((e) => e as String);

  static Stream<Uint8List> get cameraFrameStream =>
      _cameraFrameChannel.receiveBroadcastStream().map((e) => e as Uint8List);
}
