import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
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
  List<Map<String, dynamic>> _customGestures = [];
  List<Map<String, dynamic>> _builtInGestures = [];

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
    
    // Load custom gestures
    final customStrs = prefs.getStringList('custom_gestures') ?? [];
    
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

    setState(() {
      _customGestures = customStrs.map((s) => jsonDecode(s) as Map<String, dynamic>).toList();
      _builtInGestures = builtIns;
    });
  }

  Future<void> _toggleGesture(String key, bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('gesture_enabled_$key', enabled);
    await GestureChannel.setGestureEnabled(key, enabled);
  }

  Future<void> _deleteCustomGesture(int index) async {
    final prefs = await SharedPreferences.getInstance();
    final gesturesStrs = prefs.getStringList('custom_gestures') ?? [];
    if (index >= 0 && index < gesturesStrs.length) {
      gesturesStrs.removeAt(index);
      await prefs.setStringList('custom_gestures', gesturesStrs);
      setState(() {
        _customGestures.removeAt(index);
      });
    }
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
        leading: IconButton(
          icon: const Icon(Icons.menu_rounded),
          onPressed: () {},
        ),
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
        childAspectRatio: 0.9,
        children: [
          ...List.generate(_builtInGestures.length, (index) {
            final gesture = _builtInGestures[index];
            return GestureCard(
              title: gesture['title'] ?? '',
              icon: _getIconFromString(gesture['icon'] ?? ''),
              isActive: gesture['isActive'] ?? true,
              onToggleChanged: (val) => _toggleGesture(gesture['key'], val),
              onTap: () => Navigator.of(context).pushNamed(
                AppRoutes.gestureDetail,
                arguments: {
                  'title': gesture['title'] ?? '',
                  'icon': gesture['icon'] ?? '',
                  'isActive': gesture['isActive'] ?? true,
                  'isCustom': false,
                  'baseGesture': gesture['key'] ?? '',
                  'description': gesture['description'] ?? '',
                },
              ),
            );
          }),
          ...List.generate(_customGestures.length, (index) {
            final gesture = _customGestures[index];
            IconData iconData = Icons.gesture;
            String iconName = 'gesture';
            if (gesture['baseGesture'] == 'Wave') { iconData = Icons.waves; iconName = 'waves'; }
            if (gesture['baseGesture'] == 'Swipe') { iconData = Icons.swipe; iconName = 'swipe'; }
            if (gesture['baseGesture'] == 'Pinch') { iconData = Icons.pinch; iconName = 'pinch_rounded'; }
            if (gesture['baseGesture'] == 'Circle') { iconData = Icons.rotate_right; iconName = 'rotate_right_rounded'; }
            if (gesture['baseGesture'] == 'Spread') { iconData = Icons.open_in_full; iconName = 'open_in_full_rounded'; }

            // Retrieve custom gesture enabled state
            final bool isCustomEnabled = true;

            return GestureCard(
              title: gesture['name'] ?? 'Custom',
              icon: iconData,
              isActive: isCustomEnabled,
              onToggleChanged: (val) => _toggleGesture(gesture['name'], val),
              onTap: () => Navigator.of(context).pushNamed(
                AppRoutes.gestureDetail,
                arguments: {
                  'title': gesture['name'] ?? 'Custom',
                  'icon': iconName,
                  'isActive': isCustomEnabled,
                  'isCustom': true,
                  'baseGesture': gesture['baseGesture'] ?? '',
                  'description': gesture['description'] ?? '',
                },
              ),
              onDelete: () => _deleteCustomGesture(index),
            );
          }),
        ],
      ),
    );
  }
}
