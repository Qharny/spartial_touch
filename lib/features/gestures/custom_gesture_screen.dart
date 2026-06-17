import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/theme.dart';

class CustomGestureScreen extends StatefulWidget {
  const CustomGestureScreen({super.key});

  @override
  State<CustomGestureScreen> createState() => _CustomGestureScreenState();
}

class _CustomGestureScreenState extends State<CustomGestureScreen> {
  final _nameController = TextEditingController();
  String _selectedBaseGesture = 'Wave';
  String _selectedAction = 'Open App';
  double _sensitivity = 0.5;

  final List<String> _baseGestures = ['Wave', 'Swipe', 'Pinch', 'Circle', 'Spread'];
  final List<String> _actions = ['Open App', 'Media Play/Pause', 'Scroll Up', 'Scroll Down', 'Custom Shortcut'];

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _saveGesture() async {
    final prefs = await SharedPreferences.getInstance();
    final gestures = prefs.getStringList('custom_gestures') ?? [];
    
    final newGesture = {
      'name': _nameController.text.trim().isNotEmpty ? _nameController.text.trim() : 'Untitled Gesture',
      'baseGesture': _selectedBaseGesture,
      'action': _selectedAction,
      'sensitivity': _sensitivity,
    };
    
    gestures.add(jsonEncode(newGesture));
    await prefs.setStringList('custom_gestures', gestures);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Custom gesture saved locally!')),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Custom Gesture',
          style: TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w800,
            fontSize: 22,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _saveGesture,
            child: const Text('Save', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Gesture Name',
                hintText: 'e.g. My Custom Wave',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 24),
            Text('Base Gesture', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                border: Border.all(color: cs.outline),
                borderRadius: BorderRadius.circular(12),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedBaseGesture,
                  isExpanded: true,
                  items: _baseGestures.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedBaseGesture = val);
                  },
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text('Action Mapping', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                border: Border.all(color: cs.outline),
                borderRadius: BorderRadius.circular(12),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedAction,
                  isExpanded: true,
                  items: _actions.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedAction = val);
                  },
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text('Sensitivity', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Slider(
              value: _sensitivity,
              onChanged: (val) => setState(() => _sensitivity = val),
              activeColor: AppColorsShared.accent,
            ),
          ],
        ),
      ),
    );
  }
}
