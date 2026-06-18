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
  List<AppInfo> _activeApps = [];
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
      
      final prefs = await SharedPreferences.getInstance();
      final savedPackages = prefs.getStringList('active_apps_packages') ?? [];
      
      if (mounted) {
        setState(() {
          _installedApps = apps;
          if (savedPackages.isNotEmpty) {
            _activeApps = apps.where((a) => savedPackages.contains(a.packageName)).toList();
          } else if (apps.isNotEmpty) {
            _activeApps = [apps.first];
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
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: StatefulBuilder(
            builder: (BuildContext context, StateSetter setModalState) {
              return DraggableScrollableSheet(
                expand: false,
                initialChildSize: 0.6,
                minChildSize: 0.4,
                maxChildSize: 0.9,
                builder: (_, controller) {
                  return ListView.builder(
                    controller: controller,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    itemCount: _installedApps.length,
                    itemBuilder: (ctx, index) {
                      final app = _installedApps[index];
                      final isSelected = _activeApps.any((a) => a.packageName == app.packageName);
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
                        trailing: isSelected
                            ? Icon(Icons.check_circle_rounded, color: AppColorsShared.accent)
                            : const Icon(Icons.circle_outlined),
                        onTap: () {
                          setModalState(() {
                            if (isSelected) {
                              _activeApps.removeWhere((a) => a.packageName == app.packageName);
                            } else {
                              _activeApps.add(app);
                            }
                          });
                          setState(() {}); // Update the background screen immediately
                        },
                      );
                    },
                  );
                },
              );
            },
          ),
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
    if (_activeApps.isEmpty) return;
    
    final prefs = await SharedPreferences.getInstance();
    
    // Save active apps list
    final activePackages = _activeApps.map((a) => a.packageName).toList();
    final activeNames = _activeApps.map((a) => a.name).toList();
    await prefs.setStringList('active_apps_packages', activePackages);
    await prefs.setStringList('active_apps_names', activeNames);
    
    // Save settings per package name
    for (var app in _activeApps) {
      final pkg = app.packageName;
      for (var entry in _gestureMappings.entries) {
        await prefs.setString('gesture_${pkg}_${entry.key}', entry.value);
      }
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Profile saved for ${_activeApps.length} app(s)!'),
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
          // ── ACTIVE APPLICATIONS ───────────────────────────────────────────
          Text(
            'ACTIVE APPLICATIONS',
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
          else ...[
            if (_activeApps.isNotEmpty)
              Container(
                decoration: BoxDecoration(
                  color: cs.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: cs.outline),
                ),
                child: Column(
                  children: _activeApps.map((app) {
                    return ListTile(
                      leading: app.icon != null
                          ? Image.memory(app.icon!, width: 32, height: 32)
                          : const Icon(Icons.android, size: 32),
                      title: Text(
                        app.name,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: cs.onSurface,
                        ),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent),
                        onPressed: () {
                          setState(() {
                            _activeApps.remove(app);
                          });
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
            
            const SizedBox(height: 12),
            GestureDetector(
              onTap: _showAppSelector,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: cs.outline, style: BorderStyle.solid),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_rounded, color: cs.primary),
                    const SizedBox(width: 8),
                    Text(
                      'Add more apps',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w600,
                        color: cs.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],

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
