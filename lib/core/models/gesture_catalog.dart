import 'package:flutter/material.dart';

/// The 13 gestures GestureInterpreter.kt can actually emit, as (key, label).
/// Keys must match exactly — they're sent to the native ActionDispatcher as-is.
const List<(String, String)> kGestures = [
  ('WAVE_UP', 'Wave Up'),
  ('WAVE_DOWN', 'Wave Down'),
  ('WAVE_LEFT', 'Wave Left'),
  ('WAVE_RIGHT', 'Wave Right'),
  ('OPEN_PALM_HOLD', 'Open Palm Hold'),
  ('THUMBS_UP', 'Thumbs Up'),
  ('THUMBS_DOWN', 'Thumbs Down'),
  ('INDEX_POINT_UP', 'Index Point Up'),
  ('PINCH', 'Pinch'),
  ('TWO_FINGER_SWIPE_LEFT', 'Two-Finger Swipe Left'),
  ('TWO_FINGER_SWIPE_RIGHT', 'Two-Finger Swipe Right'),
  ('FIST_PUMP', 'Fist Pump'),
  ('ROCK_SIGN', 'Rock Sign'),
];

/// An action ActionDispatcher.kt knows how to run.
class ActionInfo {
  const ActionInfo(this.id, this.label, this.icon, {this.needsAccessibility = false});

  /// The native actionId — must match ActionDispatcher.execute() exactly.
  final String id;
  final String label;
  final IconData icon;

  /// True if it's injected through the Accessibility Service (touch/system actions),
  /// false if it goes through AudioManager (media/volume) and works without it.
  final bool needsAccessibility;
}

const List<ActionInfo> kActions = [
  ActionInfo('scroll_up', 'Scroll Up', Icons.keyboard_double_arrow_up_rounded, needsAccessibility: true),
  ActionInfo('scroll_down', 'Scroll Down', Icons.keyboard_double_arrow_down_rounded, needsAccessibility: true),
  ActionInfo('swipe_left', 'Swipe Left', Icons.swipe_left_rounded, needsAccessibility: true),
  ActionInfo('swipe_right', 'Swipe Right', Icons.swipe_right_rounded, needsAccessibility: true),
  ActionInfo('tap', 'Tap', Icons.touch_app_rounded, needsAccessibility: true),
  ActionInfo('back', 'Go Back', Icons.arrow_back_rounded, needsAccessibility: true),
  ActionInfo('home', 'Go Home', Icons.home_rounded, needsAccessibility: true),
  ActionInfo('recents', 'Recent Apps', Icons.view_carousel_rounded, needsAccessibility: true),
  ActionInfo('media_play_pause', 'Play / Pause', Icons.play_arrow_rounded),
  ActionInfo('media_next', 'Next Track', Icons.skip_next_rounded),
  ActionInfo('media_previous', 'Previous Track', Icons.skip_previous_rounded),
  ActionInfo('volume_up', 'Volume Up', Icons.volume_up_rounded),
  ActionInfo('volume_down', 'Volume Down', Icons.volume_down_rounded),
  ActionInfo('screenshot', 'Screenshot', Icons.screenshot_rounded, needsAccessibility: true),
];

/// Looks up an action by id, or null for an id we don't know (e.g. from an older DB).
ActionInfo? actionById(String id) {
  for (final a in kActions) {
    if (a.id == id) return a;
  }
  return null;
}

String actionLabel(String actionId) => actionById(actionId)?.label ?? actionId;

IconData actionIcon(String actionId) => actionById(actionId)?.icon ?? Icons.bolt_rounded;

bool actionNeedsAccessibility(String actionId) => actionById(actionId)?.needsAccessibility ?? false;

/// Package name of the global ("Default") profile — its mappings apply everywhere,
/// and app profiles layer overrides on top (see GestureService.applyMappingsFor).
const String kDefaultProfilePackage = '__default__';
