import 'package:flutter/material.dart';
import 'package:installed_apps/app_info.dart';
import 'package:installed_apps/installed_apps.dart';
import '../../../core/models/gesture_catalog.dart';
import '../../../core/theme/theme.dart';

/// Result of [showActionPicker]. The picker returns `null` when dismissed, and this
/// wrapper when the user chose something — so "None" ([actionId] == null) is
/// distinguishable from cancelling.
typedef ActionChoice = ({String? actionId});

/// Bottom sheet listing every action the engine can run.
///
/// [allowNone] adds a leading option that clears the assignment; [noneLabel]
/// describes what that means in context (e.g. "Use global action").
Future<ActionChoice?> showActionPicker(
  BuildContext context, {
  required String title,
  String? currentActionId,
  bool allowNone = true,
  String noneLabel = 'None',
}) {
  return showModalBottomSheet<ActionChoice>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) {
      final cs = Theme.of(ctx).colorScheme;
      return DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        minChildSize: 0.4,
        maxChildSize: 0.92,
        builder: (_, controller) => ListView(
          controller: controller,
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
              child: Text(
                title,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: cs.onSurface,
                ),
              ),
            ),
            if (allowNone)
              _ActionTile(
                icon: Icons.block_rounded,
                label: noneLabel,
                selected: currentActionId == null,
                onTap: () => Navigator.of(ctx).pop((actionId: null)),
              ),
            for (final action in kActions)
              _ActionTile(
                icon: action.icon,
                label: action.label,
                selected: currentActionId == action.id,
                onTap: () => Navigator.of(ctx).pop((actionId: action.id)),
              ),
          ],
        ),
      );
    },
  );
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ListTile(
      leading: Icon(icon, color: selected ? AppColorsShared.accent : cs.onSurfaceVariant),
      title: Text(
        label,
        style: TextStyle(
          fontFamily: 'Inter',
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          color: cs.onSurface,
        ),
      ),
      trailing: selected ? Icon(Icons.check_circle_rounded, color: AppColorsShared.accent) : null,
      onTap: onTap,
    );
  }
}

/// Bottom sheet to pick one installed app. Returns null if dismissed.
/// Apps whose package is in [excludePackages] (e.g. already overridden) are hidden.
Future<AppInfo?> showAppPicker(
  BuildContext context, {
  Set<String> excludePackages = const {},
}) {
  return showModalBottomSheet<AppInfo>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) => _AppPickerSheet(excludePackages: excludePackages),
  );
}

class _AppPickerSheet extends StatefulWidget {
  const _AppPickerSheet({required this.excludePackages});

  final Set<String> excludePackages;

  @override
  State<_AppPickerSheet> createState() => _AppPickerSheetState();
}

class _AppPickerSheetState extends State<_AppPickerSheet> {
  List<AppInfo>? _apps;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    // Include system apps: YouTube, Chrome, Gmail etc. ship as system apps on most
    // devices and would otherwise be missing. Non-launchable ones (services, etc.)
    // are still filtered out, so the list stays limited to apps the user can open.
    final apps = await InstalledApps.getInstalledApps(
      excludeSystemApps: false,
      excludeNonLaunchableApps: true,
      withIcon: true,
    );
    apps.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    if (mounted) setState(() => _apps = apps);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final apps = _apps;
    final visible = apps == null
        ? const <AppInfo>[]
        : apps
            .where((a) => !widget.excludePackages.contains(a.packageName))
            .where((a) => a.name.toLowerCase().contains(_query.toLowerCase()))
            .toList();

    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.8,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
            child: TextField(
              onChanged: (v) => setState(() => _query = v),
              decoration: InputDecoration(
                hintText: 'Search apps',
                prefixIcon: const Icon(Icons.search_rounded),
                filled: true,
                fillColor: cs.surfaceContainerHighest,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: apps == null
                ? const Center(child: CircularProgressIndicator())
                : visible.isEmpty
                    ? Center(
                        child: Text(
                          apps.isEmpty ? 'No apps found' : 'No matching apps',
                          style: TextStyle(fontFamily: 'Inter', color: cs.onSurfaceVariant),
                        ),
                      )
                    : ListView.builder(
                        itemCount: visible.length,
                        itemBuilder: (ctx, i) {
                          final app = visible[i];
                          return ListTile(
                            leading: app.icon != null
                                ? Image.memory(app.icon!, width: 36, height: 36, gaplessPlayback: true)
                                : const Icon(Icons.android, size: 36),
                            title: Text(
                              app.name,
                              style: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600),
                            ),
                            onTap: () => Navigator.of(ctx).pop(app),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
