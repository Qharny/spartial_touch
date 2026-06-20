import 'dart:async';
import 'package:spartial_touch/core/services/gesture_channel.dart';

/// Represents a recognized gesture with its real confidence score from MediaPipe.
class GestureEvent {
  final String name;
  final double confidence;

  GestureEvent({required this.name, required this.confidence});

  /// Parses the native bridge payload format: "GESTURE_NAME:0.9200"
  factory GestureEvent.fromPayload(String payload) {
    final parts = payload.split(':');
    if (parts.length == 2) {
      return GestureEvent(
        name: _formatGestureName(parts[0]),
        confidence: double.tryParse(parts[1]) ?? 0.0,
      );
    }
    return GestureEvent(name: payload, confidence: 0.0);
  }

  static String _formatGestureName(String raw) {
    // Convert "WAVE_UP" -> "Wave Up"
    return raw
        .split('_')
        .map((w) => w[0].toUpperCase() + w.substring(1).toLowerCase())
        .join(' ');
  }

  @override
  String toString() => '$name (${(confidence * 100).toStringAsFixed(0)}%)';
}

class GestureRecognitionService {
  final StreamController<GestureEvent> _gestureStreamController =
      StreamController<GestureEvent>.broadcast();

  StreamSubscription? _platformSubscription;

  Stream<GestureEvent> get gestureStream => _gestureStreamController.stream;

  void startListening() {
    GestureChannel.startService();
    _platformSubscription ??=
        GestureChannel.gestureStream.listen((payload) {
      _gestureStreamController.add(GestureEvent.fromPayload(payload));
    }, onError: (error) {
      // ignore: avoid_print
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
