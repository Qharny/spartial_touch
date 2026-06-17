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

  @override
  void initState() {
    super.initState();
    _loadCustomGestures();
  }

  Future<void> _loadCustomGestures() async {
    final prefs = await SharedPreferences.getInstance();
    final gesturesStrs = prefs.getStringList('custom_gestures') ?? [];
    setState(() {
      _customGestures = gesturesStrs.map((s) => jsonDecode(s) as Map<String, dynamic>).toList();
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
          _loadCustomGestures();
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
          GestureCard(
            title: 'Wave Up',
            icon: Icons.arrow_upward_rounded,
            isActive: true,
            onTap: () => Navigator.of(context).pushNamed(AppRoutes.gestureDetail),
          ),
          GestureCard(
            title: 'Clockwise Circle',
            icon: Icons.rotate_right_rounded,
            isActive: false,
            onTap: () => Navigator.of(context).pushNamed(AppRoutes.gestureDetail),
          ),
          GestureCard(
            title: 'Pinch',
            icon: Icons.pinch_rounded,
            isActive: false,
            onTap: () => Navigator.of(context).pushNamed(AppRoutes.gestureDetail),
          ),
          GestureCard(
            title: 'Swipe Left',
            icon: Icons.arrow_back_rounded,
            isActive: true,
            onTap: () => Navigator.of(context).pushNamed(AppRoutes.gestureDetail),
          ),
          GestureCard(
            title: 'Double Tap',
            icon: Icons.touch_app_rounded,
            isActive: false,
            onTap: () => Navigator.of(context).pushNamed(AppRoutes.gestureDetail),
          ),
          GestureCard(
            title: 'Spread',
            icon: Icons.open_in_full_rounded,
            isActive: false,
            onTap: () => Navigator.of(context).pushNamed(AppRoutes.gestureDetail),
          ),
          GestureCard(
            title: 'Palm In',
            icon: Icons.pan_tool_rounded,
            isActive: true,
            onTap: () => Navigator.of(context).pushNamed(AppRoutes.gestureDetail),
          ),
          GestureCard(
            title: 'Rotate',
            icon: Icons.screen_rotation_rounded,
            isActive: false,
            onTap: () => Navigator.of(context).pushNamed(AppRoutes.gestureDetail),
          ),
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
