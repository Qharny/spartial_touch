import 'dart:async';
import 'package:flutter/services.dart';

class GestureRecognitionService {
  static const EventChannel _gestureChannel =
      EventChannel('com.example.spartial_touch/gestures');

  final StreamController<String> _gestureStreamController =
      StreamController<String>.broadcast();

  StreamSubscription? _platformSubscription;

  Stream<String> get gestureStream => _gestureStreamController.stream;

  void startListening() {
    _platformSubscription ??=
        _gestureChannel.receiveBroadcastStream().listen((dynamic event) {
      if (event is String) {
        _gestureStreamController.add(event);
      }
    }, onError: (dynamic error) {
      print('Gesture Recognition Error: $error');
    });
  }

  void stopListening() {
    _platformSubscription?.cancel();
    _platformSubscription = null;
  }

  void dispose() {
    stopListening();
    _gestureStreamController.close();
  }
}
