import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../main.dart';
import '../../core/services/gesture_channel.dart';

class GestureDetailScreen extends StatefulWidget {
  const GestureDetailScreen({super.key});

  @override
  State<GestureDetailScreen> createState() => _GestureDetailScreenState();
}

class _GestureDetailScreenState extends State<GestureDetailScreen> {
  double _sensitivity = 0.6;

  bool _isTesting = false;
  String _detectedGesture = 'Waiting...';
  double _detectedConfidence = 0.0;
  StreamSubscription? _gestureSub;
  bool _successMatched = false;
  Timer? _successTimer;

  @override
  void dispose() {
    _gestureSub?.cancel();
    _successTimer?.cancel();
    if (_isTesting) {
      gestureRecognitionService.stopListening();
      GestureChannel.setSmartWakeEnabled(true);
    }
    super.dispose();
  }

  void _onGestureEvent(event) {
    if (!mounted) return;
    setState(() {
      _detectedGesture = event.name;
      _detectedConfidence = event.confidence;
    });

    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final title = args?['title'] ?? 'Wave Up';

    if (_isGestureMatch(event.name, title)) {
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

  bool _isGestureMatch(String detected, String currentTitle) {
    final detLower = detected.toLowerCase();
    final curLower = currentTitle.toLowerCase();
    if (detLower == curLower) return true;

    // Custom loose matching rules
    if (curLower == 'palm in' && detLower == 'open palm hold') return true;
    if (curLower == 'swipe left' && detLower == 'wave left') return true;
    if (curLower == 'swipe right' && detLower == 'wave right') return true;

    return false;
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

          // ── Global Action ────────────────────────────────────────────────
          const _SectionHeader(title: 'Global Action'),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: cs.outline),
            ),
            child: Row(
              children: [
                Icon(Icons.keyboard_double_arrow_up_rounded, color: cs.onSurfaceVariant, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Scroll Up',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: cs.onSurface,
                    ),
                  ),
                ),
                Icon(Icons.keyboard_arrow_down_rounded, color: cs.onSurfaceVariant),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // ── App Overrides ────────────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const _SectionHeader(title: 'App Overrides'),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: cs.outline),
                ),
                child: Text(
                  'Add App',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const _AppOverrideCard(
            appName: 'Spotify',
            action: 'Next Song',
            icon: Icons.music_note_rounded,
          ),
          const SizedBox(height: 12),
          const _AppOverrideCard(
            appName: 'Chrome',
            action: 'Refresh Page',
            icon: Icons.language_rounded,
          ),

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

class _AppOverrideCard extends StatelessWidget {
  const _AppOverrideCard({
    required this.appName,
    required this.action,
    required this.icon,
  });

  final String appName;
  final String action;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outline),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: cs.onSurface),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  appName,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  action,
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
    );
  }
}
