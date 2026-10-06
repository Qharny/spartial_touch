import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spartial_touch/core/models/custom_pose.dart';
import 'package:spartial_touch/core/services/gesture_channel.dart';

/// Represents a recognized gesture with its real confidence score from MediaPipe.
class GestureEvent {
  final String name;
  final double confidence;

  /// The raw engine key, e.g. `WAVE_UP` or `CUSTOM_1712345678901`.
  final String key;

  GestureEvent({required this.name, required this.confidence, String? key})
      : key = key ?? name;

  /// Parses the native bridge payload format: "GESTURE_NAME:0.9200"
  factory GestureEvent.fromPayload(String payload) {
    final parts = payload.split(':');
    if (parts.length == 2) {
      return GestureEvent(
        key: parts[0],
        name: CustomPoseStore.instance.nameFor(parts[0]) ?? _formatGestureName(parts[0]),
        confidence: double.tryParse(parts[1]) ?? 0.0,
      );
    }
    return GestureEvent(name: payload, confidence: 0.0);
  }

  static String _formatGestureName(String raw) {
    // Convert "WAVE_UP" -> "Wave Up"
    return raw
        .split('_')
        .where((w) => w.isNotEmpty)
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

  /// Screens currently listening. The service is only started/stopped on behalf of
  /// testing screens when the user's own toggle hasn't already started it.
  int _listeners = 0;
  bool _startedService = false;

  Stream<GestureEvent> get gestureStream => _gestureStreamController.stream;

  /// Starts receiving gestures for a testing screen. Starts the native service only if
  /// it isn't already running — it used to start and then *stop* it unconditionally, so
  /// closing the gesture tester switched off gesture control the user had turned on.
  Future<void> startListening() async {
    _listeners++;
    _platformSubscription ??= GestureChannel.gestureStream.listen(
      (payload) => _gestureStreamController.add(GestureEvent.fromPayload(payload)),
      onError: (Object error) => debugPrint('Gesture Recognition Error: $error'),
    );
    if (!_startedService && !await GestureChannel.isServiceRunning()) {
      try {
        await GestureChannel.startService();
        _startedService = true;
      } catch (e) {
        // Callers request camera permission first; if it's still missing there's
        // nothing to listen to, and the screen shows its own "waiting" state.
        debugPrint('Could not start gesture service: $e');
      }
    }
  }

  Future<void> stopListening() async {
    if (_listeners > 0) _listeners--;
    if (_listeners > 0) return;
    await _platformSubscription?.cancel();
    _platformSubscription = null;
    if (_startedService) {
      _startedService = false;
      // Only stop what we started, and only if the user hasn't since turned it on.
      final prefs = await SharedPreferences.getInstance();
      if (!(prefs.getBool('gesture_service_enabled') ?? false)) {
        await GestureChannel.stopService();
      }
    }
  }

  void dispose() {
    stopListening();
    _gestureStreamController.close();
  }
}
