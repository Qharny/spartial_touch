import 'package:flutter/material.dart';
import '../../core/router/router.dart';
import '../../core/theme/theme.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Profiles',
          style: TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w700,
            fontSize: 22,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        children: const [
          _ProfileCard(
            title: 'Standard Experience',
            subtitle: 'com.spatialtouch.core',
            icon: Icons.gesture_rounded,
            isDefault: true,
            isEnabled: true,
          ),
          SizedBox(height: 12),
          _ProfileCard(
            title: 'Productivity Mode',
            subtitle: 'com.spatialtouch.office',
            icon: Icons.work_outline_rounded,
            isDefault: false,
            isEnabled: false,
          ),
          SizedBox(height: 12),
          _ProfileCard(
            title: 'Immersive Play',
            subtitle: 'com.spatialtouch.gaming',
            icon: Icons.gamepad_outlined,
            isDefault: false,
            isEnabled: false,
          ),
          SizedBox(height: 12),
          _ProfileCard(
            title: 'Creative Canvas',
            subtitle: 'com.spatialtouch.design',
            icon: Icons.palette_outlined,
            isDefault: false,
            isEnabled: false,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.of(context).pushNamed(AppRoutes.profileEditor),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        child: const Icon(Icons.add_rounded, size: 28),
      ),
    );
  }
}

class _ProfileCard extends StatefulWidget {
  const _ProfileCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    this.isDefault = false,
    this.isEnabled = false,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool isDefault;
  final bool isEnabled;

  @override
  State<_ProfileCard> createState() => _ProfileCardState();
}

class _ProfileCardState extends State<_ProfileCard> {
  late bool _enabled;

  @override
  void initState() {
    super.initState();
    _enabled = widget.isEnabled;
  }

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(widget.title),
      direction: widget.isDefault
          ? DismissDirection.none
          : DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
      ),
      child: GestureDetector(
        onTap: () => Navigator.of(context).pushNamed(AppRoutes.profileEditor),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface, // Dark theme surface
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.outline),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(widget.icon, color: Colors.white),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.subtitle,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        color: Color(0xFF7A7890),
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (widget.isDefault)
                    Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'DEFAULT',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: Colors.black,
                          letterSpacing: 0.5,
                        ),
                      ),
                    )
                  else
                    const SizedBox(height: 22),
                  SizedBox(
                    height: 24,
                    child: Switch(
                      value: _enabled,
                      onChanged: (v) => setState(() => _enabled = v),
                      activeThumbColor: Colors.white,
                      activeTrackColor: AppColors.accent,
                      inactiveThumbColor: const Color(0xFF7A7890),
                      inactiveTrackColor: AppColors.surfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
