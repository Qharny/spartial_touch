import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import '../../core/models/custom_pose.dart';
import '../../core/models/gesture_catalog.dart';
import '../../core/models/profile_database.dart';
import '../../core/router/router.dart';
import '../../core/theme/theme.dart';
import '../../core/services/gesture_channel.dart';
import 'widgets/gesture_card.dart';

class GestureLibraryScreen extends StatefulWidget {
  const GestureLibraryScreen({super.key});

  @override
  State<GestureLibraryScreen> createState() => _GestureLibraryScreenState();
}

class _GestureLibraryScreenState extends State<GestureLibraryScreen> {
  List<CustomPose> _customGestures = [];
  Map<String, bool> _customEnabled = {};
  List<Map<String, dynamic>> _builtInGestures = [];

  /// gestureKey → global actionId, shown as each card's subtitle.
  Map<String, String> _globalActions = {};

  static const List<Map<String, String>> _builtInGesturesList = [
    {
      'key': 'WAVE_UP',
      'title': 'Wave Up',
      'icon': 'arrow_upward_rounded',
      'description': 'Hand moves upward quickly. Used to scroll up.'
    },
    {
      'key': 'WAVE_DOWN',
      'title': 'Wave Down',
      'icon': 'arrow_downward_rounded',
      'description': 'Hand moves downward quickly. Used to scroll down.'
    },
    {
      'key': 'WAVE_LEFT',
      'title': 'Wave Left',
      'icon': 'arrow_back_rounded',
      'description': 'Hand swipes left across the camera view.'
    },
    {
      'key': 'WAVE_RIGHT',
      'title': 'Wave Right',
      'icon': 'arrow_forward_rounded',
      'description': 'Hand swipes right across the camera view.'
    },
    {
      'key': 'OPEN_PALM_HOLD',
      'title': 'Open Palm Hold',
      'icon': 'pan_tool_rounded',
      'description': 'Flat open palm held steady for 1-2 seconds.'
    },
    {
      'key': 'THUMBS_UP',
      'title': 'Thumbs Up',
      'icon': 'thumb_up_rounded',
      'description': 'Fist with thumb extended upward.'
    },
    {
      'key': 'THUMBS_DOWN',
      'title': 'Thumbs Down',
      'icon': 'thumb_down_rounded',
      'description': 'Fist with thumb extended downward.'
    },
    {
      'key': 'INDEX_POINT_UP',
      'title': 'Index Point Up',
      'icon': 'navigation_rounded',
      'description': 'Index finger extended upward.'
    },
    {
      'key': 'PINCH',
      'title': 'Pinch',
      'icon': 'pinch_rounded',
      'description': 'Thumb and index finger closed together.'
    },
    {
      'key': 'TWO_FINGER_SWIPE_RIGHT',
      'title': 'Two-Finger Swipe R',
      'icon': 'swipe_right_rounded',
      'description': 'Index and middle finger swiping right.'
    },
    {
      'key': 'TWO_FINGER_SWIPE_LEFT',
      'title': 'Two-Finger Swipe L',
      'icon': 'swipe_left_rounded',
      'description': 'Index and middle finger swiping left.'
    },
    {
      'key': 'FIST_PUMP',
      'title': 'Fist Pump',
      'icon': 'sports_mma_rounded',
      'description': 'Closed fist pushed quickly toward the camera.'
    },
    {
      'key': 'ROCK_SIGN',
      'title': 'Rock Sign',
      'icon': 'handyman_rounded',
      'description': 'Index and pinky extended, middle and ring curled.'
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadGestures();
  }

  Future<void> _loadGestures() async {
    final prefs = await SharedPreferences.getInstance();
    
    final custom = await CustomPoseStore.instance.load();
    
    // Load built-in gestures and check their enabled state in SharedPreferences
    final List<Map<String, dynamic>> builtIns = [];
    for (final item in _builtInGesturesList) {
      final key = item['key']!;
      final isActive = prefs.getBool('gesture_enabled_$key') ?? true;
      builtIns.add({
        'key': key,
        'title': item['title']!,
        'icon': item['icon']!,
        'description': item['description']!,
        'isActive': isActive,
      });
    }

    final globalActions = await ProfileDatabase.instance.getGlobalActions();

    if (!mounted) return;
    setState(() {
      _customGestures = custom;
      _customEnabled = {
        for (final p in custom) p.key: prefs.getBool('gesture_enabled_${p.key}') ?? true,
      };
      _builtInGestures = builtIns;
      _globalActions = globalActions;
    });
  }

  Future<void> _toggleGesture(String key, bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('gesture_enabled_$key', enabled);
    await GestureChannel.setGestureEnabled(key, enabled);
  }

  Future<void> _deleteCustomGesture(CustomPose pose) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete "${pose.name}"?'),
        content: const Text('Its recorded samples and any actions assigned to it are removed.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed != true) return;
    await CustomPoseStore.instance.remove(pose.key);
    _loadGestures();
  }

  IconData _getIconFromString(String iconStr) {
    switch (iconStr) {
      case 'arrow_upward_rounded': return Icons.arrow_upward_rounded;
      case 'arrow_downward_rounded': return Icons.arrow_downward_rounded;
      case 'arrow_back_rounded': return Icons.arrow_back_rounded;
      case 'arrow_forward_rounded': return Icons.arrow_forward_rounded;
      case 'pan_tool_rounded': return Icons.pan_tool_rounded;
      case 'thumb_up_rounded': return Icons.thumb_up_rounded;
      case 'thumb_down_rounded': return Icons.thumb_down_rounded;
      case 'navigation_rounded': return Icons.navigation_rounded;
      case 'pinch_rounded': return Icons.pinch_rounded;
      case 'swipe_right_rounded': return Icons.swipe_right_rounded;
      case 'swipe_left_rounded': return Icons.swipe_left_rounded;
      case 'sports_mma_rounded': return Icons.sports_mma_rounded;
      case 'handyman_rounded': return Icons.handyman_rounded;
      default: return Icons.gesture;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Gestures',
          style: TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w800,
            fontSize: 22,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.of(context).pushNamed(AppRoutes.customGesture);
          _loadGestures();
        },
        backgroundColor: AppColorsShared.accent,
        child: const Icon(Icons.add, color: Colors.black),
      ),
      body: GridView.count(
        crossAxisCount: 2,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 0.8,
        children: [
          ...List.generate(_builtInGestures.length, (index) {
            final gesture = _builtInGestures[index];
            return GestureCard(
              title: gesture['title'] ?? '',
              icon: _getIconFromString(gesture['icon'] ?? ''),
              isActive: gesture['isActive'] ?? true,
              subtitle: switch (_globalActions[gesture['key']]) {
                null => 'Not assigned',
                final id => actionLabel(id),
              },
              onToggleChanged: (val) => _toggleGesture(gesture['key'], val),
              onTap: () async {
                await Navigator.of(context).pushNamed(
                  AppRoutes.gestureDetail,
                  arguments: {
                    'title': gesture['title'] ?? '',
                    'icon': gesture['icon'] ?? '',
                    'isActive': gesture['isActive'] ?? true,
                    'isCustom': false,
                    'baseGesture': gesture['key'] ?? '',
                    'description': gesture['description'] ?? '',
                  },
                );
                // Assignments may have changed on the detail screen.
                _loadGestures();
              },
            );
          }),
          for (final pose in _customGestures)
            GestureCard(
              title: pose.name,
              icon: Icons.front_hand_outlined,
              isActive: _customEnabled[pose.key] ?? true,
              subtitle: switch (_globalActions[pose.key]) {
                null => 'Not assigned',
                final id => actionLabel(id),
              },
              onToggleChanged: (val) {
                setState(() => _customEnabled[pose.key] = val);
                _toggleGesture(pose.key, val);
              },
              onTap: () async {
                await Navigator.of(context).pushNamed(
                  AppRoutes.gestureDetail,
                  arguments: {
                    'title': pose.name,
                    'icon': 'front_hand_outlined',
                    'isActive': _customEnabled[pose.key] ?? true,
                    'isCustom': true,
                    'baseGesture': pose.key,
                    'description': pose.description,
                  },
                );
                _loadGestures();
              },
              onDelete: () => _deleteCustomGesture(pose),
            ),
        ],
      ),
    );
  }
}
