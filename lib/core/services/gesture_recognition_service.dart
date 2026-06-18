import 'dart:async';
import 'package:spartial_touch/core/services/gesture_channel.dart';

class GestureRecognitionService {
  final StreamController<String> _gestureStreamController =
      StreamController<String>.broadcast();

  StreamSubscription? _platformSubscription;

  Stream<String> get gestureStream => _gestureStreamController.stream;

  void startListening() {
    GestureChannel.startService();
    _platformSubscription ??=
        GestureChannel.gestureStream.listen((event) {
      _gestureStreamController.add(event);
    }, onError: (error) {
      print('Gesture Recognition Error: $error');
    });
  }

  void stopListening() {
    GestureChannel.stopService();
    _platformSubscription?.cancel();
    _platformSubscription = null;
  }

  void dispose() {
    stopListening();
    _gestureStreamController.close();
  }
}
