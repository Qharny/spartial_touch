import 'package:flutter/material.dart';
import '../../core/theme/theme.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:installed_apps/installed_apps.dart';
import 'package:installed_apps/app_info.dart';

const List<String> _availableActions = [
  'Play/Pause',
  'Next Track',
  'Previous Track',
  'Volume Up',
  'Volume Down',
  'Scroll Up',
  'Scroll Down',
  'Like / Double Tap',
  'Go Home',
  'None',
];

class ProfileEditorScreen extends StatefulWidget {
  const ProfileEditorScreen({super.key});

  @override
  State<ProfileEditorScreen> createState() => _ProfileEditorScreenState();
}

class _ProfileEditorScreenState extends State<ProfileEditorScreen> {
  List<AppInfo> _installedApps = [];
  AppInfo? _selectedApp;
  bool _loadingApps = true;

  final Map<String, String> _gestureMappings = {
    'Wave Up': 'Next Track',
    'Wave Down': 'Previous Track',
    'Double Tap Air': 'Play/Pause',
    'Circular Motion': 'Volume Up',
    'Pinch': 'None',
  };

  @override
  void initState() {
    super.initState();
    _loadInstalledApps();
  }

  Future<void> _loadInstalledApps() async {
    try {
      // Get all non-system apps with their icons
      List<AppInfo> apps = await InstalledApps.getInstalledApps(excludeSystemApps: true, withIcon: true);
      // Sort apps alphabetically
      apps.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      
      if (mounted) {
        setState(() {
          _installedApps = apps;
          if (apps.isNotEmpty) {
            _selectedApp = apps.first;
          }
          _loadingApps = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loadingApps = false);
      }
    }
  }

  void _showAppSelector() {
    if (_installedApps.isEmpty) return;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return ListView.builder(
          shrinkWrap: true,
          padding: const EdgeInsets.symmetric(vertical: 16),
          itemCount: _installedApps.length,
          itemBuilder: (ctx, index) {
            final app = _installedApps[index];
            return ListTile(
              leading: app.icon != null
                  ? Image.memory(app.icon!, width: 32, height: 32)
                  : const Icon(Icons.android, size: 32),
              title: Text(
                app.name,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Text(
                app.packageName,
                style: const TextStyle(fontSize: 10),
              ),
              trailing: _selectedApp?.packageName == app.packageName
                  ? Icon(Icons.check_circle_rounded, color: AppColorsShared.accent)
                  : null,
              onTap: () {
                setState(() => _selectedApp = app);
                Navigator.of(ctx).pop();
              },
            );
          },
        );
      },
    );
  }

  void _showActionSelector(String gestureKey) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return ListView.builder(
          shrinkWrap: true,
          padding: const EdgeInsets.symmetric(vertical: 16),
          itemCount: _availableActions.length,
          itemBuilder: (ctx, index) {
            final action = _availableActions[index];
            return ListTile(
              title: Text(
                action,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w500,
                ),
              ),
              trailing: _gestureMappings[gestureKey] == action
                  ? Icon(Icons.check_circle_rounded, color: AppColorsShared.accent)
                  : null,
              onTap: () {
                setState(() => _gestureMappings[gestureKey] = action);
                Navigator.of(ctx).pop();
              },
            );
          },
        );
      },
    );
  }

  Future<void> _saveProfile() async {
    if (_selectedApp == null) return;
    
    final prefs = await SharedPreferences.getInstance();
    
    // Save settings per package name
    final pkg = _selectedApp!.packageName;
    for (var entry in _gestureMappings.entries) {
      await prefs.setString('gesture_${pkg}_${entry.key}', entry.value);
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${_selectedApp!.name} profile saved!'),
          backgroundColor: AppColorsShared.accent,
        ),
      );
      Navigator.of(context).pop();
    }
  }

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
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        children: [
          // ── ACTIVE APPLICATION ───────────────────────────────────────────
          Text(
            'ACTIVE APPLICATION',
            style: TextStyle(
              fontFamily: 'Space Mono',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.0,
              color: cs.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          
          if (_loadingApps)
            const Center(child: CircularProgressIndicator())
          else if (_selectedApp != null)
            GestureDetector(
              onTap: _showAppSelector,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: cs.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: cs.outline),
                ),
                child: Row(
                  children: [
                    _selectedApp!.icon != null
                        ? Image.memory(_selectedApp!.icon!, width: 32, height: 32)
                        : const Icon(Icons.android, size: 32),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _selectedApp!.name,
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: cs.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.keyboard_arrow_down_rounded,
                        color: cs.onSurfaceVariant),
                  ],
                ),
              ),
            )
          else
             const Text('No apps found'),

          const SizedBox(height: 32),

          // ── GESTURE CONFIGURATION ────────────────────────────────────────
          Text(
            'GESTURE CONFIGURATION',
            style: TextStyle(
              fontFamily: 'Space Mono',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.0,
              color: cs.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),

          _GestureRow(
            title: 'Wave Up',
            subtitle: 'Vertical motion sensor',
            action: _gestureMappings['Wave Up']!,
            onTap: () => _showActionSelector('Wave Up'),
          ),
          const Divider(height: 1),
          _GestureRow(
            title: 'Wave Down',
            subtitle: 'Vertical motion sensor',
            action: _gestureMappings['Wave Down']!,
            onTap: () => _showActionSelector('Wave Down'),
          ),
          const Divider(height: 1),
          _GestureRow(
            title: 'Double Tap Air',
            subtitle: 'Depth recognition pulse',
            action: _gestureMappings['Double Tap Air']!,
            onTap: () => _showActionSelector('Double Tap Air'),
          ),
          const Divider(height: 1),
          _GestureRow(
            title: 'Circular Motion',
            subtitle: 'Rotary spatial input',
            action: _gestureMappings['Circular Motion']!,
            onTap: () => _showActionSelector('Circular Motion'),
          ),
          const Divider(height: 1),
          _GestureRow(
            title: 'Pinch',
            subtitle: 'Finger grip detection',
            action: _gestureMappings['Pinch']!,
            onTap: () => _showActionSelector('Pinch'),
          ),

          const SizedBox(height: 48),

          // ── Save Button ──────────────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _saveProfile,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColorsShared.accent,
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
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final String action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      child: Padding(
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
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: cs.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: cs.outline),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    action,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: cs.onSurface,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(Icons.unfold_more_rounded,
                      size: 16, color: cs.onSurfaceVariant),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
