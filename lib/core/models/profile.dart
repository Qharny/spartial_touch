/// Represents a single gesture-to-action mapping within an app profile.
class GestureMapping {
  final int? id;

  /// The gesture key as emitted by GestureInterpreter (e.g. "WAVE_UP", "PINCH")
  final String gestureKey;

  /// Human-readable action label (e.g. "Scroll Up", "Play / Pause")
  final String actionLabel;

  /// The native action identifier sent over the MethodChannel
  /// (e.g. "scroll_up", "media_play_pause", "back")
  final String actionId;

  /// Whether this mapping is active
  final bool enabled;

  const GestureMapping({
    this.id,
    required this.gestureKey,
    required this.actionLabel,
    required this.actionId,
    this.enabled = true,
  });

  GestureMapping copyWith({
    int? id,
    String? gestureKey,
    String? actionLabel,
    String? actionId,
    bool? enabled,
  }) {
    return GestureMapping(
      id: id ?? this.id,
      gestureKey: gestureKey ?? this.gestureKey,
      actionLabel: actionLabel ?? this.actionLabel,
      actionId: actionId ?? this.actionId,
      enabled: enabled ?? this.enabled,
    );
  }

  Map<String, dynamic> toMap(int profileId) => {
        'profile_id': profileId,
        'gesture_key': gestureKey,
        'action_label': actionLabel,
        'action_id': actionId,
        'enabled': enabled ? 1 : 0,
      };

  factory GestureMapping.fromMap(Map<String, dynamic> map) => GestureMapping(
        id: map['id'] as int?,
        gestureKey: map['gesture_key'] as String,
        actionLabel: map['action_label'] as String,
        actionId: map['action_id'] as String,
        enabled: (map['enabled'] as int) == 1,
      );
}

/// Represents a per-app gesture profile.
class AppProfile {
  final int? id;

  /// Package name of the target app (e.g. "com.zhiliaoapp.musically")
  final String packageName;

  /// Display name shown in the UI
  final String displayName;

  /// Whether this profile is active
  final bool enabled;

  /// The gesture-to-action mappings for this profile
  final List<GestureMapping> mappings;

  const AppProfile({
    this.id,
    required this.packageName,
    required this.displayName,
    this.enabled = true,
    this.mappings = const [],
  });

  AppProfile copyWith({
    int? id,
    String? packageName,
    String? displayName,
    bool? enabled,
    List<GestureMapping>? mappings,
  }) {
    return AppProfile(
      id: id ?? this.id,
      packageName: packageName ?? this.packageName,
      displayName: displayName ?? this.displayName,
      enabled: enabled ?? this.enabled,
      mappings: mappings ?? this.mappings,
    );
  }

  Map<String, dynamic> toMap() => {
        'package_name': packageName,
        'display_name': displayName,
        'enabled': enabled ? 1 : 0,
      };

  factory AppProfile.fromMap(Map<String, dynamic> map,
      {List<GestureMapping> mappings = const []}) =>
      AppProfile(
        id: map['id'] as int?,
        packageName: map['package_name'] as String,
        displayName: map['display_name'] as String,
        enabled: (map['enabled'] as int) == 1,
        mappings: mappings,
      );
}

// ── Built-in starter profiles ────────────────────────────────────────────────

List<AppProfile> get builtInProfiles => [
      _profileFor(
        pkg: 'com.zhiliaoapp.musically',
        name: 'TikTok',
        mappings: {
          'WAVE_UP': ('Next Video', 'scroll_down'),
          'WAVE_DOWN': ('Prev Video', 'scroll_up'),
          'WAVE_LEFT': ('Following Feed', 'swipe_left'),
          'WAVE_RIGHT': ('For You Feed', 'swipe_right'),
          'OPEN_PALM_HOLD': ('Pause / Play', 'media_play_pause'),
        },
      ),
      _profileFor(
        pkg: 'com.google.android.youtube',
        name: 'YouTube',
        mappings: {
          'WAVE_UP': ('Scroll Up', 'scroll_up'),
          'WAVE_DOWN': ('Scroll Down', 'scroll_down'),
          'WAVE_LEFT': ('Skip -10s', 'swipe_left'),
          'WAVE_RIGHT': ('Skip +10s', 'swipe_right'),
          'OPEN_PALM_HOLD': ('Pause / Play', 'media_play_pause'),
        },
      ),
      _profileFor(
        pkg: 'com.instagram.android',
        name: 'Instagram',
        mappings: {
          'WAVE_UP': ('Next Reel', 'scroll_down'),
          'WAVE_DOWN': ('Prev Reel', 'scroll_up'),
          'WAVE_LEFT': ('Go Back', 'back'),
          'THUMBS_UP': ('Like Post', 'tap'),
          'OPEN_PALM_HOLD': ('Pause / Play', 'media_play_pause'),
        },
      ),
      _profileFor(
        pkg: 'com.spotify.music',
        name: 'Spotify',
        mappings: {
          'WAVE_UP': ('Volume Up', 'volume_up'),
          'WAVE_DOWN': ('Volume Down', 'volume_down'),
          'WAVE_LEFT': ('Prev Track', 'media_previous'),
          'WAVE_RIGHT': ('Next Track', 'media_next'),
          'OPEN_PALM_HOLD': ('Pause / Play', 'media_play_pause'),
        },
      ),
      _profileFor(
        pkg: '__default__',
        name: 'Default',
        mappings: {
          'WAVE_UP': ('Scroll Up', 'scroll_up'),
          'WAVE_DOWN': ('Scroll Down', 'scroll_down'),
          'WAVE_LEFT': ('Swipe Left', 'swipe_left'),
          'WAVE_RIGHT': ('Swipe Right', 'swipe_right'),
          'OPEN_PALM_HOLD': ('Pause / Play', 'media_play_pause'),
          'TWO_FINGER_SWIPE_LEFT': ('Go Back', 'back'),
          'TWO_FINGER_SWIPE_RIGHT': ('Go Forward', 'swipe_right'),
          'FIST_PUMP': ('Screenshot', 'screenshot'),
          'INDEX_POINT_UP': ('Scroll to Top', 'scroll_up'),
        },
      ),
    ];

AppProfile _profileFor({
  required String pkg,
  required String name,
  required Map<String, (String, String)> mappings,
}) =>
    AppProfile(
      packageName: pkg,
      displayName: name,
      mappings: mappings.entries
          .map((e) => GestureMapping(
                gestureKey: e.key,
                actionLabel: e.value.$1,
                actionId: e.value.$2,
              ))
          .toList(),
    );
