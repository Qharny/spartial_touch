import 'package:flutter/material.dart';
import '../../core/services/gesture_channel.dart'; // Ensure this matches your gesture channel file path

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _lastGesture = 'None';

  @override
  void initState() {
    super.initState();
    // Assuming GestureChannel.gestureStream is available
    // Replace with your actual stream listening logic if different
    GestureChannel.gestureStream.listen((gesture) {
      if (mounted) {
        setState(() {
          _lastGesture = gesture;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Gesture Testing',
          style: TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w700,
            fontSize: 22,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.back_hand_rounded,
                size: 64,
                color: cs.primary,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Last Detected Gesture:',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 16,
                color: cs.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _lastGesture,
              style: TextStyle(
                fontFamily: 'Space Mono',
                fontWeight: FontWeight.w800,
                fontSize: 32,
                color: cs.onSurface,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 48),
            const Text(
              'Perform gestures in front of the camera\nto test detection accuracy.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
