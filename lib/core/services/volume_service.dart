import 'package:flutter/services.dart';

class VolumeService {
  static const MethodChannel _channel = MethodChannel('com.example.spartial_touch/volume');

  static Future<void> volumeUp() async {
    try {
      await _channel.invokeMethod('volumeUp');
    } on PlatformException catch (e) {
      print("Failed to increase volume: '${e.message}'.");
    }
  }

  static Future<void> volumeDown() async {
    try {
      await _channel.invokeMethod('volumeDown');
    } on PlatformException catch (e) {
      print("Failed to decrease volume: '${e.message}'.");
    }
  }
}
