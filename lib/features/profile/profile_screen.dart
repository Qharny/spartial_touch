import 'package:flutter/material.dart';
import '../../core/theme/theme.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Avatar
          Center(
            child: Column(
              children: [
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    gradient: AppColors.accentGradient,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.accent.withValues(alpha: 0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.person_rounded,
                      color: Colors.white, size: 44),
                ),
                const SizedBox(height: 16),
                Text('Your Name', style: tt.headlineSmall),
                const SizedBox(height: 4),
                Text('user@spartialtouch.io', style: tt.bodyMedium),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Stats row
          Row(
            children: [
              _Stat(label: 'Sessions', value: '48'),
              _Stat(label: 'Devices', value: '3'),
              _Stat(label: 'Hours', value: '120'),
            ],
          ),

          const SizedBox(height: 32),

          // Tiles
          Text('Account', style: tt.titleMedium),
          const SizedBox(height: 8),
          _Tile(
              icon: Icons.edit_outlined,
              label: 'Edit Profile',
              onTap: () {}),
          _Tile(
              icon: Icons.lock_outline_rounded,
              label: 'Privacy',
              onTap: () {}),
          _Tile(
              icon: Icons.help_outline_rounded,
              label: 'Help & Support',
              onTap: () {}),

          const SizedBox(height: 24),
          Text('Preferences', style: tt.titleMedium),
          const SizedBox(height: 8),
          _Tile(
              icon: Icons.notifications_none_rounded,
              label: 'Notifications',
              onTap: () {}),
          _Tile(
              icon: Icons.language_rounded,
              label: 'Language',
              onTap: () {}),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});
  final String label, value;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.outline),
        ),
        child: Column(
          children: [
            Text(value,
                style: tt.titleLarge!.copyWith(color: AppColors.accent)),
            const SizedBox(height: 4),
            Text(label, style: tt.labelSmall),
          ],
        ),
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile(
      {required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 18, color: AppColors.textSecondary),
      ),
      title: Text(label, style: Theme.of(context).textTheme.bodyLarge),
      trailing: const Icon(Icons.chevron_right_rounded,
          size: 18, color: AppColors.textDisabled),
      onTap: onTap,
    );
  }
}
