import 'package:flutter/material.dart';
import '../../core/router/router.dart';
import '../../core/theme/theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _enableVisuals = true;
  double _opacity = 0.8;
  double _haptic = 0.6;
  bool _sounds = false;
  bool _dnd = true;
  bool _highRefresh = true;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
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
          icon: const Icon(Icons.menu_rounded),
          onPressed: () {},
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        children: [
          const _SectionTitle(title: 'OVERLAY'),
          _SettingsCard(
            children: [
              _SettingsRow(
                label: 'Enable Gesture Visuals',
                trailing: Transform.scale(
                  scale: 0.8,
                  child: Switch(
                    value: _enableVisuals,
                    onChanged: (v) => setState(() => _enableVisuals = v),
                    activeThumbColor: cs.surface,
                    activeTrackColor: AppColorsShared.accent,
                    inactiveThumbColor: cs.onSurfaceVariant,
                    inactiveTrackColor: cs.surfaceContainerHighest,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ),
              _SettingsRow(
                label: 'Overlay Opacity',
                trailing: SizedBox(
                  width: 120,
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 2,
                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                      overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                    ),
                    child: Slider(
                      value: _opacity,
                      onChanged: (v) => setState(() => _opacity = v),
                      activeColor: cs.onSurface,
                      inactiveColor: cs.outline,
                    ),
                  ),
                ),
                showDivider: false,
              ),
            ],
          ),
          const SizedBox(height: 24),

          const _SectionTitle(title: 'FEEDBACK'),
          _SettingsCard(
            children: [
              _SettingsRow(
                label: 'Haptic Intensity',
                trailing: SizedBox(
                  width: 120,
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 2,
                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                      overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                    ),
                    child: Slider(
                      value: _haptic,
                      onChanged: (v) => setState(() => _haptic = v),
                      activeColor: cs.onSurface,
                      inactiveColor: cs.outline,
                    ),
                  ),
                ),
              ),
              _SettingsRow(
                label: 'Sound Effects',
                trailing: Transform.scale(
                  scale: 0.8,
                  child: Switch(
                    value: _sounds,
                    onChanged: (v) => setState(() => _sounds = v),
                    activeThumbColor: cs.surface,
                    activeTrackColor: AppColorsShared.accent,
                    inactiveThumbColor: cs.onSurfaceVariant,
                    inactiveTrackColor: cs.surfaceContainerHighest,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
                showDivider: false,
              ),
            ],
          ),
          const SizedBox(height: 24),

          const _SectionTitle(title: 'SCHEDULE'),
          _SettingsCard(
            children: [
              _SettingsRow(
                label: 'Auto-Start Mode',
                trailing: Icon(Icons.chevron_right_rounded, color: cs.onSurfaceVariant),
                onTap: () {},
              ),
              _SettingsRow(
                label: 'Do Not Disturb',
                trailing: Transform.scale(
                  scale: 0.8,
                  child: Switch(
                    value: _dnd,
                    onChanged: (v) => setState(() => _dnd = v),
                    activeThumbColor: cs.surface,
                    activeTrackColor: AppColorsShared.accent,
                    inactiveThumbColor: cs.onSurfaceVariant,
                    inactiveTrackColor: cs.surfaceContainerHighest,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
                showDivider: false,
              ),
            ],
          ),
          const SizedBox(height: 24),

          const _SectionTitle(title: 'PERFORMANCE'),
          _SettingsCard(
            children: [
              _SettingsRow(
                label: 'High Refresh Rate',
                trailing: Transform.scale(
                  scale: 0.8,
                  child: Switch(
                    value: _highRefresh,
                    onChanged: (v) => setState(() => _highRefresh = v),
                    activeThumbColor: cs.surface,
                    activeTrackColor: AppColorsShared.accent,
                    inactiveThumbColor: cs.onSurfaceVariant,
                    inactiveTrackColor: cs.surfaceContainerHighest,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ),
              _SettingsRow(
                label: 'Battery Optimization',
                trailing: Icon(Icons.chevron_right_rounded, color: cs.onSurfaceVariant),
                onTap: () {},
                showDivider: false,
              ),
            ],
          ),
          const SizedBox(height: 24),

          const _SectionTitle(title: 'CALIBRATION'),
          _SettingsCard(
            children: [
              _SettingsRow(
                label: 'Redo Calibration',
                trailing: Icon(Icons.chevron_right_rounded, color: cs.onSurfaceVariant),
                onTap: () => Navigator.of(context).pushNamed(AppRoutes.calibration),
                showDivider: false,
              ),
            ],
          ),
          const SizedBox(height: 24),

          const _SectionTitle(title: 'PERMISSIONS'),
          _SettingsCard(
            children: [
              _SettingsRow(
                label: 'Spatial Camera',
                trailing: Text(
                  'Allowed',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ),
              _SettingsRow(
                label: 'Motion Sensors',
                trailing: Icon(Icons.chevron_right_rounded, color: cs.onSurfaceVariant),
                onTap: () {},
                showDivider: false,
              ),
            ],
          ),
          const SizedBox(height: 48),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontFamily: 'Space Mono',
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.0,
          color: cs.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outline),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: children,
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
