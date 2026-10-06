import 'dart:convert';
import 'dart:math' as math;

import 'package:shared_preferences/shared_preferences.dart';

import '../services/gesture_channel.dart';
import 'profile_database.dart';

/// Prefix of every custom gesture key, e.g. `CUSTOM_1712345678901`.
const String kCustomGesturePrefix = 'CUSTOM_';

/// A user-recorded hand pose: a name plus a few samples of the 21 MediaPipe
/// landmarks, each flattened to `[x0, y0, x1, y1, ...]` (42 values).
class CustomPose {
  const CustomPose({
    required this.key,
    required this.name,
    this.description = '',
    required this.samples,
  });

  final String key;
  final String name;
  final String description;
  final List<List<double>> samples;

  Map<String, dynamic> toJson() => {
        'key': key,
        'name': name,
        'description': description,
        'samples': samples,
      };

  factory CustomPose.fromJson(Map<String, dynamic> json) => CustomPose(
        key: json['key'] as String,
        name: json['name'] as String? ?? 'Custom gesture',
        description: json['description'] as String? ?? '',
        samples: [
          for (final s in (json['samples'] as List? ?? const []))
            [for (final v in s as List) (v as num).toDouble()],
        ],
      );
}

/// Pose maths shared by the recorder's live test. Mirrors CustomPoseMatcher.kt —
/// keep the two in sync.
abstract final class PoseMath {
  static const int points = 21;
  static const int _middleMcp = 9;

  /// Mean per-landmark distance (normalised hand units) at default sensitivity.
  static const double baseMatchThreshold = 0.35;

  /// Wrist at the origin, wrist→middle-finger-MCP scaled to 1. Null if [raw]
  /// isn't 42 values or the hand is degenerate.
  static List<double>? normalize(List<double> raw) {
    if (raw.length != points * 2) return null;
    final wx = raw[0], wy = raw[1];
    final mx = raw[_middleMcp * 2] - wx, my = raw[_middleMcp * 2 + 1] - wy;
    final scale = math.sqrt(mx * mx + my * my);
    if (scale < 1e-4) return null;
    return [for (var i = 0; i < raw.length; i++) (raw[i] - (i.isEven ? wx : wy)) / scale];
  }

  /// Mean Euclidean distance between corresponding landmarks.
  static double distance(List<double> a, List<double> b) {
    var sum = 0.0;
    for (var p = 0; p < points; p++) {
      final dx = a[p * 2] - b[p * 2], dy = a[p * 2 + 1] - b[p * 2 + 1];
      sum += math.sqrt(dx * dx + dy * dy);
    }
    return sum / points;
  }

  /// Averages several raw frames of the same held pose into one sample.
  static List<double> average(List<List<double>> frames) {
    final out = List<double>.filled(points * 2, 0);
    for (final f in frames) {
      for (var i = 0; i < out.length; i++) {
        out[i] += f[i];
      }
    }
    return [for (final v in out) v / frames.length];
  }

  /// How much the hand moved while recording: mean distance of each normalised
  /// frame from the normalised average. Lower is steadier.
  static double jitter(List<List<double>> frames) {
    final mean = normalize(average(frames));
    if (mean == null) return double.infinity;
    var total = 0.0;
    var n = 0;
    for (final f in frames) {
      final nf = normalize(f);
      if (nf == null) continue;
      total += distance(nf, mean);
      n++;
    }
    return n == 0 ? double.infinity : total / n;
  }
}

/// Loads, saves and syncs custom poses. The list lives in SharedPreferences and
/// is pushed to the native matcher on every change and at startup.
class CustomPoseStore {
  CustomPoseStore._();
  static final CustomPoseStore instance = CustomPoseStore._();

  static const _prefsKey = 'custom_poses_v2';
  // The old wizard saved name-only entries that the engine could never detect.
  static const _legacyKey = 'custom_gestures';

  List<CustomPose> _poses = const [];
  List<CustomPose> get poses => _poses;

  String? nameFor(String key) {
    if (!key.startsWith(kCustomGesturePrefix)) return null;
    for (final p in _poses) {
      if (p.key == key) return p.name;
    }
    return null;
  }

  Future<List<CustomPose>> load() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_legacyKey);
    final raw = prefs.getString(_prefsKey);
    if (raw == null) {
      _poses = const [];
    } else {
      try {
        _poses = [
          for (final e in jsonDecode(raw) as List) CustomPose.fromJson(e as Map<String, dynamic>),
        ];
      } catch (_) {
        _poses = const [];
      }
    }
    return _poses;
  }

  Future<void> add(CustomPose pose) async {
    await load();
    await _save([..._poses, pose]);
  }

  Future<void> remove(String key) async {
    await load();
    await _save([for (final p in _poses) if (p.key != key) p]);
    await ProfileDatabase.instance.deleteBindingsForGesture(key);
  }

  Future<void> _save(List<CustomPose> poses) async {
    _poses = poses;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, jsonEncode([for (final p in poses) p.toJson()]));
    await syncToNative();
  }

  Future<void> syncToNative() => GestureChannel.setCustomPoses(
        json: jsonEncode([
          for (final p in _poses) {'key': p.key, 'samples': p.samples},
        ]),
        names: {for (final p in _poses) p.key: p.name},
      );
}
