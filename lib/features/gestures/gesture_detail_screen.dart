import 'dart:async';
import 'package:app_settings/app_settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:installed_apps/installed_apps.dart';
import '../../main.dart';
import '../../core/models/gesture_catalog.dart';
import '../../core/models/profile.dart';
import '../../core/models/profile_database.dart';
import '../../core/services/gesture_channel.dart';
import '../../core/theme/theme.dart';
import 'widgets/pickers.dart';

class GestureDetailScreen extends StatefulWidget {
  const GestureDetailScreen({super.key});

  @override
  State<GestureDetailScreen> createState() => _GestureDetailScreenState();
}

class _GestureDetailScreenState extends State<GestureDetailScreen> with WidgetsBindingObserver {
  double _sensitivity = 0.6;

  bool _isTesting = false;
  String _detectedGesture = 'Waiting...';
  double _detectedConfidence = 0.0;
  StreamSubscription? _gestureSub;
  bool _successMatched = false;
  Timer? _successTimer;

  // ── Action assignment ──────────────────────────────────────────────────────
  bool _argsLoaded = false;
  String? _gestureKey; // null for custom gestures, which the engine can't emit yet
  String _gestureTitle = '';
  GestureBindings _bindings = const GestureBindings();
  bool _accessibilityOn = true;
  bool _usageAccessOn = true;
  final Map<String, Uint8List?> _appIcons = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_argsLoaded) return;
    _argsLoaded = true;
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    _gestureTitle = args?['title'] ?? 'Wave Up';
    final isCustom = args?['isCustom'] ?? false;
    final base = args?['baseGesture'] as String?;
    _gestureKey = (!isCustom && base != null && base.isNotEmpty) ? base : null;
    _refreshAssignments();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // The user comes back from the Accessibility / Usage access settings screens.
    if (state == AppLifecycleState.resumed) _refreshPermissions();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _gestureSub?.cancel();
    _successTimer?.cancel();
    if (_isTesting) {
      gestureRecognitionService.stopListening();
      GestureChannel.setSmartWakeEnabled(true);
    }
    super.dispose();
  }

  Future<void> _refreshAssignments() async {
    final key = _gestureKey;
    if (key == null) return;
    final bindings = await ProfileDatabase.instance.getBindingsForGesture(key);
    if (!mounted) return;
    setState(() => _bindings = bindings);
    _refreshPermissions();
    for (final o in bindings.overrides) {
      _loadIcon(o.packageName);
    }
  }

  Future<void> _refreshPermissions() async {
    final accessibility = await GestureChannel.isAccessibilityServiceEnabled();
    final usage = await GestureChannel.hasUsageAccess();
    if (!mounted) return;
    setState(() {
      _accessibilityOn = accessibility;
      _usageAccessOn = usage;
    });
  }

  Future<void> _loadIcon(String packageName) async {
    if (_appIcons.containsKey(packageName)) return;
    _appIcons[packageName] = null; // mark in-flight so we don't fetch twice
    final info = await InstalledApps.getAppInfo(packageName);
    if (!mounted) return;
    setState(() => _appIcons[packageName] = info?.icon);
  }

  /// Saves one binding, then reloads. Surfaces a failure instead of leaving the
  /// UI claiming an assignment that didn't persist.
  Future<void> _saveBinding({
    required String packageName,
    required String displayName,
    required String? actionId,
  }) async {
    final key = _gestureKey;
    if (key == null) return;
    try {
      await ProfileDatabase.instance.setBinding(
        packageName: packageName,
        displayName: displayName,
        gestureKey: key,
        actionId: actionId,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not save assignment: $e')),
        );
      }
    }
    await _refreshAssignments();
  }

  Future<void> _pickGlobalAction() async {
    final choice = await showActionPicker(
      context,
      title: 'Global action for $_gestureTitle',
      currentActionId: _bindings.globalActionId,
    );
    if (choice == null) return;
    await _saveBinding(
      packageName: kDefaultProfilePackage,
      displayName: 'Default',
      actionId: choice.actionId,
    );
  }

  Future<void> _addOverride() async {
    final app = await showAppPicker(
      context,
      excludePackages: {for (final o in _bindings.overrides) o.packageName},
    );
    if (app == null || !mounted) return;
    _appIcons[app.packageName] = app.icon;
    final choice = await showActionPicker(
      context,
      title: 'What should $_gestureTitle do in ${app.name}?',
      currentActionId: _bindings.globalActionId,
      allowNone: false,
    );
    if (choice?.actionId == null) return;
    await _saveBinding(
      packageName: app.packageName,
      displayName: app.name,
      actionId: choice!.actionId,
    );
  }

  Future<void> _editOverride(AppBinding binding) async {
    final choice = await showActionPicker(
      context,
      title: '$_gestureTitle in ${binding.displayName}',
      currentActionId: binding.actionId,
      noneLabel: 'Use global action',
    );
    if (choice == null) return;
    await _saveBinding(
      packageName: binding.packageName,
      displayName: binding.displayName,
      actionId: choice.actionId,
    );
  }

  Future<void> _testAction(String actionId) async {
    try {
      await GestureChannel.performAction(actionId);
    } on PlatformException catch (e) {
      if (!mounted) return;
      final message = e.code == 'ACCESSIBILITY_NOT_ENABLED'
          ? 'Enable the SpatialTouch accessibility service to run this action.'
          : 'Could not run action: ${e.message ?? e.code}';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  bool get _needsAccessibility {
    final ids = [
      if (_bindings.globalActionId != null) _bindings.globalActionId!,
      for (final o in _bindings.overrides) o.actionId,
    ];
    return ids.any(actionNeedsAccessibility);
  }

  void _onGestureEvent(event) {
    if (!mounted) return;
    setState(() {
      _detectedGesture = event.name;
      _detectedConfidence = event.confidence;
    });

    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final title = args?['title'] ?? 'Wave Up';
    final baseGesture = args?['baseGesture'] ?? '';
    final isCustom = args?['isCustom'] ?? false;

    if (_isGestureMatch(
      detected: event.name,
      baseGesture: baseGesture,
      isCustom: isCustom,
      currentTitle: title,
    )) {
      _successTimer?.cancel();
      setState(() {
        _successMatched = true;
      });
      _successTimer = Timer(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            _successMatched = false;
          });
        }
      });
    }
  }

  bool _isGestureMatch({
    required String detected,
    required String baseGesture,
    required bool isCustom,
    required String currentTitle,
  }) {
    final normalizedDetected = detected.toUpperCase().replaceAll(' ', '_');

    if (isCustom) {
      final cleanDetected = normalizedDetected;
      final cleanBase = baseGesture.toUpperCase();

      if (cleanBase == 'WAVE' && cleanDetected.contains('WAVE')) return true;
      if (cleanBase == 'SWIPE' && cleanDetected.contains('SWIPE')) return true;
      if (cleanBase == 'PINCH' && cleanDetected.contains('PINCH')) return true;
      if (cleanBase == 'CIRCLE' && (cleanDetected.contains('CIRCLE') || cleanDetected.contains('ROTARY'))) return true;
      if (cleanBase == 'SPREAD' && (cleanDetected.contains('SPREAD') || cleanDetected.contains('PALM'))) return true;
      return false;
    } else {
      if (normalizedDetected == baseGesture.toUpperCase()) {
        return true;
      }

      final detLower = detected.toLowerCase();
      final curLower = currentTitle.toLowerCase();
      if (detLower == curLower) return true;

      // Custom loose matching rules
      if (curLower == 'palm in' && detLower == 'open palm hold') return true;
      if (curLower == 'swipe left' && detLower == 'wave left') return true;
      if (curLower == 'swipe right' && detLower == 'wave right') return true;

      return false;
    }
  }

  void _toggleTest() {
    setState(() {
      _isTesting = !_isTesting;
      if (_isTesting) {
        _detectedGesture = 'Waiting...';
        _detectedConfidence = 0.0;
        _successMatched = false;
        gestureRecognitionService.startListening();
        GestureChannel.setSmartWakeEnabled(false); // Bypass SmartWake sensor gating during detail testing
        _gestureSub = gestureRecognitionService.gestureStream.listen(_onGestureEvent);
      } else {
        _gestureSub?.cancel();
        gestureRecognitionService.stopListening();
        GestureChannel.setSmartWakeEnabled(true); // Restore sensor gating on stop
        _successTimer?.cancel();
      }
    });
  }

  IconData _getIconFromString(String iconStr) {
    switch (iconStr) {
      case 'arrow_upward_rounded': return Icons.arrow_upward_rounded;
      case 'rotate_right_rounded': return Icons.rotate_right_rounded;
      case 'pinch_rounded': return Icons.pinch_rounded;
      case 'arrow_back_rounded': return Icons.arrow_back_rounded;
      case 'touch_app_rounded': return Icons.touch_app_rounded;
      case 'open_in_full_rounded': return Icons.open_in_full_rounded;
      case 'pan_tool_rounded': return Icons.pan_tool_rounded;
      case 'screen_rotation_rounded': return Icons.screen_rotation_rounded;
      case 'waves': return Icons.waves;
      case 'swipe': return Icons.swipe;
      default: return Icons.gesture;
    }
  }

  String _getDescription(String title) {
    switch (title.toLowerCase()) {
      case 'wave up':
        return 'Quick upward motion with an open palm. Hold fingers steady for better detection.';
      case 'swipe left':
      case 'wave left':
        return 'Quick swipe from right to left across the camera field of view.';
      case 'swipe right':
      case 'wave right':
        return 'Quick swipe from left to right across the camera field of view.';
      case 'pinch':
        return 'Bring your index finger and thumb together to simulate a pinch gesture.';
      case 'palm in':
      case 'open palm hold':
        return 'Hold an open palm flat towards the camera for 1–2 seconds to play or pause.';
      case 'clockwise circle':
        return 'Trace a clockwise circle in the air with your index finger extended.';
      case 'double tap':
        return 'Simulate a double tap in the air with your index finger.';
      case 'spread':
        return 'Start with a closed fist and spread all fingers outward quickly.';
      case 'rotate':
        return 'Rotate your hand clockwise or counter-clockwise to trigger system shortcuts.';
      default:
        return 'Perform the designated physical gesture within 30cm to 80cm of the front camera.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final title = args?['title'] ?? 'Wave Up';
    final iconStr = args?['icon'] ?? 'arrow_upward_rounded';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Gesture Detail',
          style: TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w700,
            fontSize: 16,
            color: cs.onSurface,
          ),
        ),
        centerTitle: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close_rounded, color: cs.onSurface),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        children: [
          // ── Gesture Large Icon / Live Test Area ──────────────────────────
          GestureDetector(
            onTap: _toggleTest,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: 220,
              decoration: BoxDecoration(
                color: _successMatched 
                    ? const Color(0xFF00C853).withValues(alpha: 0.1)
                    : cs.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _successMatched ? const Color(0xFF00C853) : cs.outline,
                  width: _successMatched ? 3 : 1,
                ),
                boxShadow: _successMatched
                    ? [
                        BoxShadow(
                          color: const Color(0xFF00C853).withValues(alpha: 0.3),
                          blurRadius: 16,
                          spreadRadius: 2,
                        )
                      ]
                    : [],
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_isTesting) ...[
                      Container(
                        width: 140,
                        height: 140,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                        ),
                        child: ClipOval(
                          child: StreamBuilder<Uint8List>(
                            stream: GestureChannel.cameraFrameStream,
                            builder: (context, snapshot) {
                              if (snapshot.hasData) {
                                return RotatedBox(
                                  quarterTurns: 1,
                                  child: Transform.scale(
                                    scaleX: -1,
                                    child: Image.memory(
                                      snapshot.data!,
                                      fit: BoxFit.cover,
                                      gaplessPlayback: true,
                                    ),
                                  ),
                                );
                              }
                              return Center(
                                child: Icon(
                                  Icons.videocam_off_rounded,
                                  size: 48,
                                  color: cs.onSurfaceVariant.withValues(alpha: 0.4),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _successMatched 
                            ? 'SUCCESS: Detected!' 
                            : _detectedGesture == 'Waiting...' 
                                ? 'Perform gesture now' 
                                : 'Detected: $_detectedGesture (${(_detectedConfidence * 100).toInt()}%)',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: _successMatched ? const Color(0xFF00C853) : cs.onSurfaceVariant,
                        ),
                      ),
                    ] else ...[
                      Icon(
                        _getIconFromString(iconStr),
                        size: 64,
                        color: cs.onSurface,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Tap card to start live test',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // ── Title & Description ─────────────────────────────────────────
          Text(
            title,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _getDescription(title),
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              color: cs.onSurfaceVariant,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),

          // ── Live Test button → Toggle test state ─────────────────────────
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: _toggleTest,
              style: ElevatedButton.styleFrom(
                backgroundColor: _isTesting ? Colors.redAccent : cs.onSurface,
                foregroundColor: _isTesting ? Colors.white : Theme.of(context).scaffoldBackgroundColor,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: Icon(
                _isTesting ? Icons.videocam_off_outlined : Icons.videocam_outlined,
                size: 20,
              ),
              label: Text(
                _isTesting ? 'Stop Testing' : 'Test This Gesture',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // ── Stats ────────────────────────────────────────────────────────
          const Row(
            children: [
              Expanded(
                child: _StatCard(
                  label: 'ACCURACY',
                  value: '98.4%',
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: _StatCard(
                  label: 'DAILY USAGE',
                  value: '142',
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // ── Sensitivity ──────────────────────────────────────────────────
          const _SectionHeader(title: 'Sensitivity'),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: cs.outline),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Low', style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
                    Text('High', style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
                  ],
                ),
                const SizedBox(height: 8),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 4,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
                  ),
                  child: Slider(
                    value: _sensitivity,
                    onChanged: (v) => setState(() => _sensitivity = v),
                    activeColor: cs.onSurface,
                    inactiveColor: cs.outline,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Higher sensitivity makes the gesture easier to trigger but may increase accidental activations.',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    color: cs.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // ── Assigned Action ──────────────────────────────────────────────
          if (_gestureKey == null)
            const _InfoNote(
              text: "Custom gestures can't trigger actions yet. Only the built-in "
                  'gestures can be assigned to a task.',
            )
          else ...[
            if (_needsAccessibility && !_accessibilityOn) ...[
              _PermissionBanner(
                icon: Icons.accessibility_new_rounded,
                text: 'This gesture needs the SpatialTouch accessibility service to '
                    'scroll, swipe, tap or navigate.',
                buttonLabel: 'Enable',
                onPressed: () => AppSettings.openAppSettings(type: AppSettingsType.accessibility),
              ),
              const SizedBox(height: 16),
            ],
            const _SectionHeader(title: 'Global Action'),
            const SizedBox(height: 4),
            Text(
              'Runs in every app unless an override below replaces it.',
              style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 12),
            _AssignmentCard(
              leading: Icon(
                _bindings.globalActionId == null
                    ? Icons.block_rounded
                    : actionIcon(_bindings.globalActionId!),
                color: _bindings.globalActionId == null ? cs.onSurfaceVariant : AppColorsShared.accent,
                size: 20,
              ),
              title: _bindings.globalActionId == null
                  ? 'Not assigned'
                  : actionLabel(_bindings.globalActionId!),
              muted: _bindings.globalActionId == null,
              onTap: _pickGlobalAction,
              onTest: _bindings.globalActionId == null
                  ? null
                  : () => _testAction(_bindings.globalActionId!),
            ),
            const SizedBox(height: 32),

            // ── App Overrides ────────────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const _SectionHeader(title: 'App Overrides'),
                InkWell(
                  onTap: _addOverride,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: cs.outline),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add_rounded, size: 14, color: cs.onSurface),
                        const SizedBox(width: 4),
                        Text(
                          'Add App',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: cs.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_bindings.overrides.isNotEmpty && !_usageAccessOn) ...[
              _PermissionBanner(
                icon: Icons.query_stats_rounded,
                text: 'App overrides need Usage access so SpatialTouch can tell which '
                    'app is open. Until it is granted, only the global action runs.',
                buttonLabel: 'Grant',
                onPressed: GestureChannel.openUsageAccessSettings,
              ),
              const SizedBox(height: 12),
            ],
            if (_bindings.overrides.isEmpty)
              Text(
                'No app overrides yet. Add an app to give this gesture a different '
                'action there, e.g. Wave Right → Next Track in Spotify.',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  height: 1.4,
                  color: cs.onSurfaceVariant,
                ),
              )
            else
              for (final o in _bindings.overrides) ...[
                _AssignmentCard(
                  leading: _AppIcon(bytes: _appIcons[o.packageName]),
                  title: o.displayName,
                  subtitle: actionLabel(o.actionId),
                  onTap: () => _editOverride(o),
                  onTest: () => _testAction(o.actionId),
                  onRemove: () => _saveBinding(
                    packageName: o.packageName,
                    displayName: o.displayName,
                    actionId: null,
                  ),
                ),
                const SizedBox(height: 12),
              ],
          ],

          const SizedBox(height: 48),

          // ── Bottom Dots (Mocked Pager Indicator) ──────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 8, height: 8,
                decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: cs.onSurfaceVariant)),
              ),
              const SizedBox(width: 12),
              Container(
                width: 16, height: 4,
                decoration: BoxDecoration(color: cs.onSurface, borderRadius: BorderRadius.circular(2)),
              ),
              const SizedBox(width: 12),
              Container(
                width: 8, height: 8,
                decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: cs.onSurfaceVariant)),
              ),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Space Mono',
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.0,
              color: cs.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: cs.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Text(
      title,
      style: TextStyle(
        fontFamily: 'Inter',
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: cs.onSurface,
      ),
    );
  }
}

/// A tappable row showing one assignment: an icon, a title, an optional subtitle,
/// and optional "test" / "remove" buttons.
class _AssignmentCard extends StatelessWidget {
  const _AssignmentCard({
    required this.leading,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.muted = false,
    this.onTest,
    this.onRemove,
  });

  final Widget leading;
  final String title;
  final String? subtitle;
  final bool muted;
  final VoidCallback onTap;
  final VoidCallback? onTest;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Material(
      color: cs.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: cs.outline),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
          child: Row(
            children: [
              SizedBox(width: 32, height: 32, child: Center(child: leading)),
              const SizedBox(width: 16),
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
                        color: muted ? cs.onSurfaceVariant : cs.onSurface,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (onTest != null)
                IconButton(
                  tooltip: 'Try this action now',
                  icon: Icon(Icons.play_circle_outline_rounded, color: cs.onSurfaceVariant),
                  onPressed: onTest,
                ),
              if (onRemove != null)
                IconButton(
                  tooltip: 'Remove override',
                  icon: Icon(Icons.delete_outline_rounded, color: cs.error),
                  onPressed: onRemove,
                )
              else
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Icon(Icons.chevron_right_rounded, color: cs.onSurfaceVariant),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AppIcon extends StatelessWidget {
  const _AppIcon({required this.bytes});

  final Uint8List? bytes;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    if (bytes == null) {
      return Icon(Icons.android_rounded, color: cs.onSurfaceVariant, size: 28);
    }
    return Image.memory(bytes!, width: 32, height: 32, gaplessPlayback: true);
  }
}

/// A prompt shown when a permission the assigned action depends on is missing.
class _PermissionBanner extends StatelessWidget {
  const _PermissionBanner({
    required this.icon,
    required this.text,
    required this.buttonLabel,
    required this.onPressed,
  });

  final IconData icon;
  final String text;
  final String buttonLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
      decoration: BoxDecoration(
        color: cs.errorContainer.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.error.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Icon(icon, color: cs.error, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12.5,
                height: 1.4,
                color: cs.onSurface,
              ),
            ),
          ),
          TextButton(onPressed: onPressed, child: Text(buttonLabel)),
        ],
      ),
    );
  }
}

class _InfoNote extends StatelessWidget {
  const _InfoNote({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 13,
          height: 1.4,
          color: cs.onSurfaceVariant,
        ),
      ),
    );
  }
}
