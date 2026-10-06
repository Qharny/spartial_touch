import 'package:flutter/material.dart';
import '../../core/theme/theme.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:installed_apps/installed_apps.dart';
import 'package:installed_apps/app_info.dart';
import '../../core/models/custom_pose.dart';
import '../../core/models/gesture_catalog.dart';
import '../../core/models/profile.dart';
import '../../core/models/profile_database.dart';

// Gesture/action vocabulary lives in gesture_catalog.dart — keys must match
// GestureInterpreter.kt / ActionDispatcher.kt exactly. Recorded custom poses
// are appended after the built-ins.
List<(String, String)> get _availableGestures => [
      ...kGestures,
      for (final p in CustomPoseStore.instance.poses) (p.key, p.name),
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
  bool _saving = false;

  /// gestureKey -> actionId, or null if that gesture is unmapped for this
  /// preset. Edits the shared mapping applied to every app in [_activeApps].
  final Map<String, String?> _gestureMappings = {
    for (final g in _availableGestures) g.$1: null,
  };

  @override
  void initState() {
    super.initState();
    _loadInstalledApps();
  }

  Future<void> _loadInstalledApps() async {
    try {
      // Include system apps (YouTube, Chrome, ... ship as system apps); non-launchable
      // ones are still filtered out by the plugin's default.
      List<AppInfo> apps = await InstalledApps.getInstalledApps(excludeSystemApps: false, withIcon: true);
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
      await _loadMappingsForActiveApps();
    } catch (e) {
      if (mounted) {
        setState(() => _loadingApps = false);
      }
    }
  }

  /// Loads the current mapping preset to edit: the first active app's saved
  /// profile if it has one, else the Default profile's, else leaves every
  /// gesture unmapped.
  Future<void> _loadMappingsForActiveApps() async {
    if (_activeApps.isEmpty) return;
    final profile = await ProfileDatabase.instance.getProfileByPackage(_activeApps.first.packageName) ??
        await ProfileDatabase.instance.getProfileByPackage('__default__');
    if (profile == null || !mounted) return;
    setState(() {
      for (final mapping in profile.mappings) {
        if (mapping.enabled && _gestureMappings.containsKey(mapping.gestureKey)) {
          _gestureMappings[mapping.gestureKey] = mapping.actionId;
        }
      }
    });
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
          itemCount: kActions.length + 1,
          itemBuilder: (ctx, index) {
            // Index 0 is the "None" (unmapped) option; the rest are real actions.
            final actionId = index == 0 ? null : kActions[index - 1].id;
            final label = index == 0 ? 'None' : kActions[index - 1].label;
            return ListTile(
              title: Text(
                label,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w500,
                ),
              ),
              trailing: _gestureMappings[gestureKey] == actionId
                  ? Icon(Icons.check_circle_rounded, color: AppColorsShared.accent)
                  : null,
              onTap: () {
                setState(() => _gestureMappings[gestureKey] = actionId);
                Navigator.of(ctx).pop();
              },
            );
          },
        );
      },
    );
  }

  Future<void> _saveProfile() async {
    if (_activeApps.isEmpty || _saving) return;
    setState(() => _saving = true);

    final prefs = await SharedPreferences.getInstance();

    // Save active apps list (which apps this shared preset applies to)
    final activePackages = _activeApps.map((a) => a.packageName).toList();
    final activeNames = _activeApps.map((a) => a.name).toList();
    await prefs.setStringList('active_apps_packages', activePackages);
    await prefs.setStringList('active_apps_names', activeNames);

    final mappings = _gestureMappings.entries
        .where((e) => e.value != null)
        .map((e) => GestureMapping(
              gestureKey: e.key,
              actionId: e.value!,
              actionLabel: actionLabel(e.value!),
            ))
        .toList();

    // Persist one AppProfile per selected app, then push the full set to the
    // native ActionDispatcher — GestureService.loadProfileMappings replaces
    // its whole cache each call, so a partial push isn't meaningful.
    for (final app in _activeApps) {
      await ProfileDatabase.instance.insertProfile(AppProfile(
        packageName: app.packageName,
        displayName: app.name,
        mappings: mappings,
      ));
    }
    await ProfileDatabase.instance.syncToNative();

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

          for (int i = 0; i < _availableGestures.length; i++) ...[
            _GestureRow(
              title: _availableGestures[i].$2,
              action: switch (_gestureMappings[_availableGestures[i].$1]) {
                null => 'None',
                final id => actionLabel(id),
              },
              onTap: () => _showActionSelector(_availableGestures[i].$1),
            ),
            if (i < _availableGestures.length - 1) const Divider(height: 1),
          ],

          const SizedBox(height: 48),

          // ── Save Button ──────────────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _saving ? null : _saveProfile,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColorsShared.accent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text(
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
    required this.action,
    required this.onTap,
  });

  final String title;
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
              child: Text(
                title,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface,
                ),
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
