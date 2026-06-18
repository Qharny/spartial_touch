import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/router/router.dart';
import '../../core/theme/theme.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _enableVisuals = true;
  double _opacity = 0.8;
  double _haptic = 0.6;
  bool _sounds = false;
  bool _dnd = true;
  bool _highRefresh = true;
  String _activeAppsSubtitle = 'Loading...';

  @override
  void initState() {
    super.initState();
    _loadActiveApps();
  }

  Future<void> _loadActiveApps() async {
    final prefs = await SharedPreferences.getInstance();
    final names = prefs.getStringList('active_apps_names') ?? [];
    if (mounted) {
      setState(() {
        if (names.isEmpty) {
          _activeAppsSubtitle = 'None';
        } else {
          _activeAppsSubtitle = names.join(', ');
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Settings',
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
        children: [
          const _SettingsSectionTitle(title: 'Gestures & Apps'),
          const SizedBox(height: 12),
          _SettingsCard(
            title: 'Connected Apps',
            subtitle: _activeAppsSubtitle,
            icon: Icons.apps_rounded,
            onTap: () async {
              await Navigator.of(context).pushNamed(AppRoutes.profileEditor);
              _loadActiveApps();
            },
          ),
          const SizedBox(height: 12),
          _SettingsCard(
            title: 'Global Gestures',
            subtitle: 'Gestures that work everywhere',
            icon: Icons.public_rounded,
            onTap: () {},
          ),
          
          const SizedBox(height: 32),
          const _SettingsSectionTitle(title: 'Preferences'),
          const SizedBox(height: 12),
          
          _ExpandableSettingsCard(
            title: 'Overlay & Performance',
            subtitle: 'Visuals, opacity, and refresh rate',
            icon: Icons.layers_outlined,
            children: [
              _SettingsRow(
                label: 'Enable Gesture Visuals',
                trailing: Switch(
                  value: _enableVisuals,
                  onChanged: (v) => setState(() => _enableVisuals = v),
                  activeThumbColor: cs.surface,
                  activeTrackColor: AppColorsShared.accent,
                ),
              ),
              _SettingsRow(
                label: 'Overlay Opacity',
                trailing: SizedBox(
                  width: 120,
                  child: Slider(
                    value: _opacity,
                    onChanged: (v) => setState(() => _opacity = v),
                    activeColor: cs.onSurface,
                    inactiveColor: cs.outline,
                  ),
                ),
              ),
              _SettingsRow(
                label: 'High Refresh Rate',
                showDivider: false,
                trailing: Switch(
                  value: _highRefresh,
                  onChanged: (v) => setState(() => _highRefresh = v),
                  activeThumbColor: cs.surface,
                  activeTrackColor: AppColorsShared.accent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          _ExpandableSettingsCard(
            title: 'Feedback & Schedule',
            subtitle: 'Haptics, sounds, and DND',
            icon: Icons.vibration_rounded,
            children: [
              _SettingsRow(
                label: 'Haptic Intensity',
                trailing: SizedBox(
                  width: 120,
                  child: Slider(
                    value: _haptic,
                    onChanged: (v) => setState(() => _haptic = v),
                    activeColor: cs.onSurface,
                    inactiveColor: cs.outline,
                  ),
                ),
              ),
              _SettingsRow(
                label: 'Sound Effects',
                trailing: Switch(
                  value: _sounds,
                  onChanged: (v) => setState(() => _sounds = v),
                  activeThumbColor: cs.surface,
                  activeTrackColor: AppColorsShared.accent,
                ),
              ),
              _SettingsRow(
                label: 'Do Not Disturb',
                showDivider: false,
                trailing: Switch(
                  value: _dnd,
                  onChanged: (v) => setState(() => _dnd = v),
                  activeThumbColor: cs.surface,
                  activeTrackColor: AppColorsShared.accent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          _ExpandableSettingsCard(
            title: 'Calibration & Permissions',
            subtitle: 'Manage access and tracking',
            icon: Icons.tune_rounded,
            children: [
              _SettingsRow(
                label: 'Redo Calibration',
                trailing: Icon(Icons.chevron_right_rounded, color: cs.onSurfaceVariant),
                onTap: () => Navigator.of(context).pushNamed(AppRoutes.calibration),
              ),
              _SettingsRow(
                label: 'Spatial Camera',
                trailing: Text('Allowed', style: TextStyle(color: cs.onSurfaceVariant)),
                showDivider: false,
              ),
            ],
          ),

          const SizedBox(height: 32),
          const _SettingsSectionTitle(title: 'Support'),
          const SizedBox(height: 12),
          _SettingsCard(
            title: 'Help & Tutorials',
            subtitle: 'Learn how to use Spartial Touch',
            icon: Icons.help_outline_rounded,
            onTap: () {},
          ),
          const SizedBox(height: 12),
          _SettingsCard(
            title: 'About',
            subtitle: 'Version 1.0.0',
            icon: Icons.info_outline_rounded,
            onTap: () {},
          ),
          const SizedBox(height: 12),
          _SettingsCard(
            title: 'Permissions & Privacy',
            subtitle: 'Review required permissions and privacy commitments',
            icon: Icons.shield_outlined,
            onTap: () => Navigator.of(context).pushNamed(AppRoutes.privacy),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _SettingsSectionTitle extends StatelessWidget {
  final String title;

  const _SettingsSectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Text(
      title.toUpperCase(),
      style: TextStyle(
        fontFamily: 'Inter',
        fontWeight: FontWeight.w700,
        fontSize: 12,
        letterSpacing: 1.2,
        color: cs.onSurfaceVariant,
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    this.trailing,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Widget? trailing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cs.outline),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: cs.onSurface),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: cs.onSurface,
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
            if (trailing != null) trailing! else Icon(Icons.chevron_right_rounded, color: cs.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}

class _ExpandableSettingsCard extends StatefulWidget {
  const _ExpandableSettingsCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.children,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final List<Widget> children;

  @override
  State<_ExpandableSettingsCard> createState() => _ExpandableSettingsCardState();
}

class _ExpandableSettingsCardState extends State<_ExpandableSettingsCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outline),
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            child: Container(
              padding: const EdgeInsets.all(16),
              color: Colors.transparent,
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(widget.icon, color: cs.onSurface),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                            color: cs.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.subtitle,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 13,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    _isExpanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                    color: cs.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
          if (_isExpanded)
            Column(
              children: [
                const Divider(height: 1),
                ...widget.children,
              ],
            ),
        ],
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.label,
    required this.trailing,
    this.onTap,
    this.showDivider = true,
  });

  final String label;
  final Widget trailing;
  final VoidCallback? onTap;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    Widget content = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: cs.onSurface,
            ),
          ),
          trailing,
        ],
      ),
    );

    if (onTap != null) {
      content = InkWell(
        onTap: onTap,
        child: content,
      );
    }

    if (showDivider) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          content,
          const Divider(height: 1, indent: 16, endIndent: 16),
        ],
      );
    }

    return content;
  }
}

