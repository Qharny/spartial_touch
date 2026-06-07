import 'package:flutter/material.dart';
import '../../core/theme/theme.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Notifications'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _notifications.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (_, i) {
          final n = _notifications[i];
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.outline),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: n.read ? AppColors.surfaceVariant : AppColors.accentMuted,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    n.icon,
                    size: 18,
                    color: n.read ? AppColors.textDisabled : AppColors.accent,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(n.title, style: tt.titleSmall),
                      const SizedBox(height: 4),
                      Text(n.body, style: tt.bodySmall),
                    ],
                  ),
                ),
                Text(n.time, style: tt.bodySmall),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _NotifItem {
  const _NotifItem({
    required this.icon,
    required this.title,
    required this.body,
    required this.time,
    this.read = false,
  });
  final IconData icon;
  final String title, body, time;
  final bool read;
}

const _notifications = [
  _NotifItem(
    icon: Icons.spatial_audio_off_rounded,
    title: 'Audio session started',
    body: 'Your spatial audio session is now active.',
    time: '2m ago',
  ),
  _NotifItem(
    icon: Icons.vibration_rounded,
    title: 'Haptic pattern saved',
    body: 'Pattern "Wave 3" has been saved successfully.',
    time: '1h ago',
    read: true,
  ),
  _NotifItem(
    icon: Icons.sensors_rounded,
    title: 'Sensor calibrated',
    body: 'IMU sensor calibration completed.',
    time: '3h ago',
    read: true,
  ),
];
