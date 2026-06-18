import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import '../../core/router/router.dart';
import '../../core/theme/theme.dart';
import 'widgets/gesture_card.dart';

class GestureLibraryScreen extends StatefulWidget {
  const GestureLibraryScreen({super.key});

  @override
  State<GestureLibraryScreen> createState() => _GestureLibraryScreenState();
}

class _GestureLibraryScreenState extends State<GestureLibraryScreen> {
  List<Map<String, dynamic>> _customGestures = [];
  List<Map<String, dynamic>> _demoGestures = [];

  final List<Map<String, dynamic>> _initialDemoGestures = [
    {'title': 'Wave Up', 'icon': 'arrow_upward_rounded', 'isActive': true},
    {'title': 'Clockwise Circle', 'icon': 'rotate_right_rounded', 'isActive': false},
    {'title': 'Pinch', 'icon': 'pinch_rounded', 'isActive': false},
    {'title': 'Swipe Left', 'icon': 'arrow_back_rounded', 'isActive': true},
    {'title': 'Double Tap', 'icon': 'touch_app_rounded', 'isActive': false},
    {'title': 'Spread', 'icon': 'open_in_full_rounded', 'isActive': false},
    {'title': 'Palm In', 'icon': 'pan_tool_rounded', 'isActive': true},
    {'title': 'Rotate', 'icon': 'screen_rotation_rounded', 'isActive': false},
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
    
    // Load demo gestures
    List<String>? demoStrs = prefs.getStringList('demo_gestures');
    if (demoStrs == null) {
      demoStrs = _initialDemoGestures.map((e) => jsonEncode(e)).toList();
      await prefs.setStringList('demo_gestures', demoStrs);
    }

    setState(() {
      _customGestures = customStrs.map((s) => jsonDecode(s) as Map<String, dynamic>).toList();
      _demoGestures = demoStrs!.map((s) => jsonDecode(s) as Map<String, dynamic>).toList();
    });
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

  Future<void> _deleteDemoGesture(int index) async {
    final prefs = await SharedPreferences.getInstance();
    final gesturesStrs = prefs.getStringList('demo_gestures') ?? [];
    if (index >= 0 && index < gesturesStrs.length) {
      gesturesStrs.removeAt(index);
      await prefs.setStringList('demo_gestures', gesturesStrs);
      setState(() {
        _demoGestures.removeAt(index);
      });
    }
  }

  IconData _getIconFromString(String iconStr) {
    switch (iconStr) {
      case 'arrow_upward_rounded': return Icons.arrow_upward_rounded;
      case 'rotate_right_rounded': return Icons.rotate_right_rounded;
      case 'pinch_rounded': return Icons.pinch_rounded;
      case 'arrow_back_rounded': return Icons.arrow_back_rounded;
      case 'touch_app_rounded': return Icons.touch_app_rounded;
      case 'open_in_full_rounded': return Icons.open_in_full_rounded;
      case 'pan_tool_rounded': return Icons.pan_tool_rounded;
      case 'screen_rotation_rounded': return Icons.screen_rotation_rounded;
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
          ...List.generate(_demoGestures.length, (index) {
            final gesture = _demoGestures[index];
            return GestureCard(
              title: gesture['title'] ?? '',
              icon: _getIconFromString(gesture['icon'] ?? ''),
              isActive: gesture['isActive'] ?? false,
              onTap: () => Navigator.of(context).pushNamed(AppRoutes.gestureDetail),
              onDelete: () => _deleteDemoGesture(index),
            );
          }),
          ...List.generate(_customGestures.length, (index) {
            final gesture = _customGestures[index];
            IconData iconData = Icons.gesture;
            if (gesture['baseGesture'] == 'Wave') iconData = Icons.waves;
            if (gesture['baseGesture'] == 'Swipe') iconData = Icons.swipe;
            if (gesture['baseGesture'] == 'Pinch') iconData = Icons.pinch;
            if (gesture['baseGesture'] == 'Circle') iconData = Icons.rotate_right;
            if (gesture['baseGesture'] == 'Spread') iconData = Icons.open_in_full;

            return GestureCard(
              title: gesture['name'] ?? 'Custom',
              icon: iconData,
              isActive: true,
              onTap: () => Navigator.of(context).pushNamed(AppRoutes.gestureDetail),
              onDelete: () => _deleteCustomGesture(index),
            );
          }),
        ],
      ),
    );
  }
}
