import 'package:flutter/material.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Permissions & Privacy',
          style: TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        children: [
          Text(
            'PERMISSIONS EXPLAINED',
            style: TextStyle(
              fontFamily: 'Space Mono',
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
              color: cs.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          _PermissionCard(
            title: 'CAMERA',
            subtitle: 'Front camera for hand gesture detection',
            sensitivity: 'High',
            icon: Icons.videocam_rounded,
          ),
          const SizedBox(height: 12),
          _PermissionCard(
            title: 'FOREGROUND_SERVICE',
            subtitle: 'Keep gesture service running in background',
            sensitivity: 'Low',
            icon: Icons.settings_applications_rounded,
          ),
          const SizedBox(height: 12),
          _PermissionCard(
            title: 'FOREGROUND_SERVICE_CAMERA',
            subtitle: 'Android 14+ requirement for background camera use',
            sensitivity: 'High',
            icon: Icons.camera_front_rounded,
          ),
          const SizedBox(height: 12),
          _PermissionCard(
            title: 'SYSTEM_ALERT_WINDOW',
            subtitle: 'Draw floating overlay indicator over other apps',
            sensitivity: 'Medium',
            icon: Icons.picture_in_picture_rounded,
          ),
          const SizedBox(height: 12),
          _PermissionCard(
            title: 'AccessibilityService',
            subtitle: 'Inject scroll/tap/swipe events into foreground apps',
            sensitivity: 'High',
            icon: Icons.accessibility_new_rounded,
          ),
          const SizedBox(height: 12),
          _PermissionCard(
            title: 'RECEIVE_BOOT_COMPLETED',
            subtitle: 'Auto-start service on device boot (if user enables)',
            sensitivity: 'Low',
            icon: Icons.power_settings_new_rounded,
          ),
          const SizedBox(height: 12),
          _PermissionCard(
            title: 'VIBRATE',
            subtitle: 'Haptic feedback on gesture recognition',
            sensitivity: 'Low',
            icon: Icons.vibration_rounded,
          ),

          const SizedBox(height: 40),

          Text(
            'PRIVACY COMMITMENTS',
            style: TextStyle(
              fontFamily: 'Space Mono',
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
              color: cs.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest.withOpacity(0.4),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: cs.outline.withOpacity(0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _CommitmentRow(text: 'Zero camera data transmitted off-device — all ML inference is local'),
                const SizedBox(height: 16),
                _CommitmentRow(text: 'Camera frames are processed in-memory and never saved to disk'),
                const SizedBox(height: 16),
                _CommitmentRow(text: 'No analytics SDK, no crash reporting that includes user behaviour data'),
                const SizedBox(height: 16),
                _CommitmentRow(text: 'No account required — app works fully offline'),
                const SizedBox(height: 16),
                _CommitmentRow(text: 'Full privacy policy published at a public URL (required for Play Store)'),
                const SizedBox(height: 16),
                _CommitmentRow(text: 'Foreground notification always visible when camera is active — no silent recording'),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _PermissionCard extends StatelessWidget {
  const _PermissionCard({
    required this.title,
    required this.subtitle,
    required this.sensitivity,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final String sensitivity;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isHigh = sensitivity == 'High';
    final sensitivityColor = isHigh 
        ? Colors.red.shade300 
        : (sensitivity == 'Medium' ? Colors.orange.shade300 : Colors.green.shade300);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outline),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: cs.onSurfaceVariant, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Space Mono',
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: sensitivityColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: sensitivityColor.withOpacity(0.3)),
            ),
            child: Text(
              sensitivity,
              style: TextStyle(
                fontFamily: 'Inter',
                fontWeight: FontWeight.w600,
                fontSize: 11,
                color: sensitivityColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CommitmentRow extends StatelessWidget {
  const _CommitmentRow({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.shield_rounded, color: Theme.of(context).colorScheme.primary, size: 18),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}
