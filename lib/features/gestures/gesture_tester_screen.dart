import 'package:flutter/material.dart';

class GestureTesterScreen extends StatelessWidget {
  const GestureTesterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A), // Extremely dark background
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert_rounded, color: Color(0xFF7A7890)),
            onPressed: () {},
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // ── Circular Camera/Sensor View Mockup ─────────────────────────
            Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF1E1E1E), width: 2),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Outer ring
                  Container(
                    width: 240,
                    height: 240,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFF2A2A3A), width: 4),
                    ),
                  ),
                  // Hand icon mock to simulate hand recognition in the camera feed
                  const Icon(
                    Icons.pan_tool_rounded,
                    size: 100,
                    color: Color(0xFF4A4A5A),
                  ),
                  // Center tracking box
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.3), width: 1),
                    ),
                    child: Center(
                      child: Container(
                        width: 4,
                        height: 4,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                  // Tracking crosshairs
                  Container(
                      width: 280,
                      height: 1,
                      color: Colors.white.withValues(alpha: 0.05)),
                  Container(
                      width: 1,
                      height: 280,
                      color: Colors.white.withValues(alpha: 0.05)),
                ],
              ),
            ),
            const SizedBox(height: 48),

            // ── Result Text ───────────────────────────────────────────────
            const Text(
              'Wave Up',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '98% CONFIDENCE',
              style: TextStyle(
                fontFamily: 'Space Mono',
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
                color: Color(0xFF7A7890),
              ),
            ),
            const SizedBox(height: 48),

            // ── Action Pill ───────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(32),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.skip_next_rounded, color: Colors.black, size: 20),
                  SizedBox(width: 12),
                  Text(
                    'Next Track',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 64), // Balance the spacing visually
          ],
        ),
      ),
    );
  }
}
