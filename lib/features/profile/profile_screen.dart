import 'package:app_settings/app_settings.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/app_info.dart';
import '../../core/router/router.dart';
import '../../core/theme/theme.dart';
import '../../core/services/performance_mode_service.dart';
import '../../core/services/active_hours_scheduler.dart';
import '../../core/services/gesture_channel.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, this.onNavigateToTab});

  /// Switches the parent shell's tab (1 = Gestures). Null when pushed as a route.
  final void Function(int index)? onNavigateToTab;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with WidgetsBindingObserver {
  bool _enableVisuals = true;
  double _opacity = 0.8;
  bool _hapticsEnabled = true;
  bool _sounds = false;
  bool _dnd = true;
  bool _smartWake = true;

  // Real permission state, refreshed whenever the app returns to the foreground.
  bool _cameraGranted = false;
  bool _accessibilityOn = false;
  bool _usageAccessOn = false;
  bool _overlayGranted = false;
  PerformanceMode _performanceMode = PerformanceMode.balanced;

  bool _activeHoursEnabled = false;
  TimeOfDay _activeHoursStart = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay _activeHoursEnd = const TimeOfDay(hour: 22, minute: 0);

  String _activeAppsSubtitle = 'Loading...';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadActiveApps();
    _loadSettings();
    _refreshPermissions();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Back from a system settings screen.
    if (state == AppLifecycleState.resumed) _refreshPermissions();
  }

  Future<void> _refreshPermissions() async {
    final camera = await Permission.camera.isGranted;
    final overlay = await Permission.systemAlertWindow.isGranted;
    final accessibility = await GestureChannel.isAccessibilityServiceEnabled();
    final usage = await GestureChannel.hasUsageAccess();
    if (!mounted) return;
    setState(() {
      _cameraGranted = camera;
      _overlayGranted = overlay;
      _accessibilityOn = accessibility;
      _usageAccessOn = usage;
    });
  }

  Future<void> _setBool(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  Future<void> _pushOverlay() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('overlay_enabled', _enableVisuals);
    await prefs.setDouble('overlay_opacity', _opacity);
    await GestureChannel.setOverlaySettings(enabled: _enableVisuals, opacity: _opacity);
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final mode = await PerformanceModeService.load();
    final ahEnabled = await ActiveHoursScheduler.instance.isEnabled();
    final ahStart = await ActiveHoursScheduler.instance.getStartTime();
    final ahEnd = await ActiveHoursScheduler.instance.getEndTime();

    if (mounted) {
      setState(() {
        _hapticsEnabled = prefs.getBool('haptics_enabled') ?? true;
        _enableVisuals = prefs.getBool('overlay_enabled') ?? true;
        _opacity = (prefs.getDouble('overlay_opacity') ?? 0.8).clamp(0.2, 1.0);
        _sounds = prefs.getBool('sounds_enabled') ?? false;
        _dnd = prefs.getBool('pause_in_dnd') ?? true;
        _smartWake = prefs.getBool('smart_wake_enabled') ?? true;
        _performanceMode = mode;
        _activeHoursEnabled = ahEnabled;
        _activeHoursStart = ahStart;
        _activeHoursEnd = ahEnd;
      });
    }
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
            // Global actions are set per gesture in the Gestures tab.
            onTap: () => widget.onNavigateToTab != null
                ? widget.onNavigateToTab!(1)
                : Navigator.of(context).pushNamed(AppRoutes.gestureLibrary),
          ),
          
          const SizedBox(height: 32),
          const _SettingsSectionTitle(title: 'Preferences'),
          const SizedBox(height: 12),
          _ExpandableSettingsCard(
            title: 'Overlay & Performance',
            subtitle: 'Visuals, opacity, and performance preset',
            icon: Icons.layers_outlined,
            children: [
              _SettingsRow(
                label: 'Floating Status Overlay',
                trailing: Switch(
                  value: _enableVisuals,
                  onChanged: (v) {
                    setState(() => _enableVisuals = v);
                    _pushOverlay();
                  },
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
                    min: 0.2,
                    max: 1.0,
                    onChanged: _enableVisuals ? (v) => setState(() => _opacity = v) : null,
                    onChangeEnd: (_) => _pushOverlay(),
                    activeColor: cs.onSurface,
                    inactiveColor: cs.outline,
                  ),
                ),
              ),
              _SettingsRow(
                label: 'Smart Wake (saves battery)',
                trailing: Switch(
                  value: _smartWake,
                  onChanged: (v) async {
                    setState(() => _smartWake = v);
                    await _setBool('smart_wake_enabled', v);
                    await GestureChannel.setSmartWakePreference(v);
                  },
                  activeThumbColor: cs.surface,
                  activeTrackColor: AppColorsShared.accent,
                ),
              ),
              _SettingsRow(
                label: 'Performance Preset',
                showDivider: false,
                trailing: DropdownButton<PerformanceMode>(
                  value: _performanceMode,
                  underline: const SizedBox(),
                  onChanged: (mode) async {
                    if (mode != null) {
                      setState(() {
                        _performanceMode = mode;
                      });
                      await PerformanceModeService.save(mode);
                      await GestureChannel.setPerformanceMode(
                        fps: mode.fps,
                        cooldownMs: mode.cooldownMs,
                      );
                    }
                  },
                  items: PerformanceMode.values.map((mode) {
                    return DropdownMenuItem<PerformanceMode>(
                      value: mode,
                      child: Text(
                        mode.label,
                        style: TextStyle(color: cs.onSurface),
                      ),
                    );
                  }).toList(),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _performanceMode.description,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          _ExpandableSettingsCard(
            title: 'Feedback & Schedule',
            subtitle: 'Haptics, sounds, and active hours',
            icon: Icons.vibration_rounded,
            children: [
              _SettingsRow(
                label: 'Haptic Feedback',
                trailing: Switch(
                  value: _hapticsEnabled,
                  onChanged: (v) async {
                    setState(() => _hapticsEnabled = v);
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setBool('haptics_enabled', v);
                    await GestureChannel.setHapticsEnabled(v);
                  },
                  activeThumbColor: cs.surface,
                  activeTrackColor: AppColorsShared.accent,
                ),
              ),
              _SettingsRow(
                label: 'Click Sound on Gesture',
                trailing: Switch(
                  value: _sounds,
                  onChanged: (v) async {
                    setState(() => _sounds = v);
                    await _setBool('sounds_enabled', v);
                    await GestureChannel.setSoundsEnabled(v);
                  },
                  activeThumbColor: cs.surface,
                  activeTrackColor: AppColorsShared.accent,
                ),
              ),
              _SettingsRow(
                label: 'Pause During Do Not Disturb',
                trailing: Switch(
                  value: _dnd,
                  onChanged: (v) async {
                    setState(() => _dnd = v);
                    await _setBool('pause_in_dnd', v);
                    await GestureChannel.setPauseInDnd(v);
                  },
                  activeThumbColor: cs.surface,
                  activeTrackColor: AppColorsShared.accent,
                ),
              ),
              _SettingsRow(
                label: 'Enable Active Hours',
                showDivider: _activeHoursEnabled,
                trailing: Switch(
                  value: _activeHoursEnabled,
                  onChanged: (v) async {
                    setState(() => _activeHoursEnabled = v);
                    await ActiveHoursScheduler.instance.save(
                      enabled: v,
                      start: _activeHoursStart,
                      end: _activeHoursEnd,
                    );
                  },
                  activeThumbColor: cs.surface,
                  activeTrackColor: AppColorsShared.accent,
                ),
              ),
              if (_activeHoursEnabled) ...[
                _SettingsRow(
                  label: 'Start Time',
                  trailing: Text(
                    _activeHoursStart.format(context),
                    style: TextStyle(
                      color: cs.primary,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Inter',
                    ),
                  ),
                  onTap: () async {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: _activeHoursStart,
                    );
                    if (time != null) {
                      setState(() => _activeHoursStart = time);
                      await ActiveHoursScheduler.instance.save(
                        enabled: _activeHoursEnabled,
                        start: time,
                        end: _activeHoursEnd,
                      );
                    }
                  },
                ),
                _SettingsRow(
                  label: 'End Time',
                  showDivider: false,
                  trailing: Text(
                    _activeHoursEnd.format(context),
                    style: TextStyle(
                      color: cs.primary,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Inter',
                    ),
                  ),
                  onTap: () async {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: _activeHoursEnd,
                    );
                    if (time != null) {
                      setState(() => _activeHoursEnd = time);
                      await ActiveHoursScheduler.instance.save(
                        enabled: _activeHoursEnabled,
                        start: _activeHoursStart,
                        end: time,
                      );
                    }
                  },
                ),
              ],
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
              _PermissionRow(
                label: 'Camera',
                granted: _cameraGranted,
                onFix: () async {
                  final status = await Permission.camera.request();
                  if (status.isPermanentlyDenied) await openAppSettings();
                  _refreshPermissions();
                },
              ),
              _PermissionRow(
                label: 'Accessibility Service',
                granted: _accessibilityOn,
                onFix: () => AppSettings.openAppSettings(type: AppSettingsType.accessibility),
              ),
              _PermissionRow(
                label: 'Usage Access (per-app profiles)',
                granted: _usageAccessOn,
                onFix: GestureChannel.openUsageAccessSettings,
              ),
              _PermissionRow(
                label: 'Display Over Other Apps',
                granted: _overlayGranted,
                showDivider: false,
                onFix: () async {
                  await Permission.systemAlertWindow.request();
                  _refreshPermissions();
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          const SizedBox(height: 32),
          const _SettingsSectionTitle(title: 'Support'),
          const SizedBox(height: 12),
          _SettingsCard(
            title: 'Help & Tutorials',
            subtitle: 'Learn how to use SpatialTouch',
            icon: Icons.help_outline_rounded,
            onTap: () => Navigator.of(context).pushNamed(AppRoutes.help),
          ),
          const SizedBox(height: 12),
          _SettingsCard(
            title: 'About',
            subtitle: 'Version $kAppVersion',
            icon: Icons.info_outline_rounded,
            onTap: () => Navigator.of(context).pushNamed(AppRoutes.about),
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

/// A permission's real state, with a one-tap way to fix it when it's missing.
class _PermissionRow extends StatelessWidget {
  const _PermissionRow({
    required this.label,
    required this.granted,
    required this.onFix,
    this.showDivider = true,
  });

  final String label;
  final bool granted;
  final VoidCallback onFix;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return _SettingsRow(
      label: label,
      showDivider: showDivider,
      onTap: granted ? null : onFix,
      trailing: granted
          ? Text('Allowed', style: TextStyle(color: cs.onSurfaceVariant))
          : const Text('Enable',
              style: TextStyle(color: AppColorsShared.accent, fontWeight: FontWeight.w700)),
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
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
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
            Icon(Icons.chevron_right_rounded, color: cs.onSurfaceVariant),
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

