import 'package:flutter/material.dart';
import '../../core/theme/theme.dart';

class ProfileEditorScreen extends StatelessWidget {
  const ProfileEditorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'SpatialTouch',
          style: TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w800,
            fontSize: 22,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu_rounded), // Using menu icon to match the design (though usually back)
          onPressed: () => Navigator.of(context).pop(), // but it acts as a back/close
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        children: [
          // ── ACTIVE APPLICATION ───────────────────────────────────────────
          const Text(
            'ACTIVE APPLICATION',
            style: TextStyle(
              fontFamily: 'Space Mono',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.0,
              color: Color(0xFF7A7890),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.outline),
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                    color: Color(0xFF1DB954), // Spotify green mock
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.music_note_rounded,
                      color: Colors.white, size: 18),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Text(
                    'Spotify',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
                const Icon(Icons.keyboard_arrow_down_rounded,
                    color: Color(0xFF7A7890)),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // ── GESTURE CONFIGURATION ────────────────────────────────────────
          const Text(
            'GESTURE CONFIGURATION',
            style: TextStyle(
              fontFamily: 'Space Mono',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.0,
              color: Color(0xFF7A7890),
            ),
          ),
          const SizedBox(height: 12),

          const _GestureRow(
            title: 'Wave Up',
            subtitle: 'Vertical motion sensor',
            action: 'Next Track',
          ),
          const Divider(height: 1),
          const _GestureRow(
            title: 'Wave Down',
            subtitle: 'Vertical motion sensor',
            action: 'Previous Track',
          ),
          const Divider(height: 1),
          const _GestureRow(
            title: 'Double Tap Air',
            subtitle: 'Depth recognition pulse',
            action: 'Play/Pause',
          ),
          const Divider(height: 1),
          const _GestureRow(
            title: 'Circular Motion',
            subtitle: 'Rotary spatial input',
            action: 'Volume Control',
          ),

          const SizedBox(height: 48),

          // ── Save Button ──────────────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent, // Match design's dark button -> map to our accent
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Save Profile',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GestureRow extends StatelessWidget {
  const _GestureRow({
    required this.title,
    required this.subtitle,
    required this.action,
  });

  final String title;
  final String subtitle;
  final String action;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    color: Color(0xFF7A7890),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant, // Muted button background
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.outline),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  action,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.unfold_more_rounded,
                    size: 16, color: Color(0xFF7A7890)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
