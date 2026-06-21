import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/theme.dart';
import '../../core/services/gesture_channel.dart';

class CustomGestureScreen extends StatefulWidget {
  const CustomGestureScreen({super.key});

  @override
  State<CustomGestureScreen> createState() => _CustomGestureScreenState();
}

class _CustomGestureScreenState extends State<CustomGestureScreen> {
  int _currentStep = 1;

  // ── Stage 1 Fields ─────────────────────────────────────────────────────────
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  String _category = 'Motion-based'; // 'Motion-based' | 'Hold-based'
  String _selectedBaseGesture = 'Wave';

  final List<String> _baseGestures = ['Wave', 'Swipe', 'Pinch', 'Circle', 'Spread'];

  // ── Stage 2 Fields ─────────────────────────────────────────────────────────
  bool _cameraReady = false;
  StreamSubscription? _cameraFrameSub;

  // ── Stage 3 Fields ─────────────────────────────────────────────────────────
  int _countdown = 0;
  bool _isRecording = false;
  int _activeSampleIndex = 0;
  Timer? _countdownTimer;
  Timer? _recordProgressTimer;
  double _recordProgress = 0.0;

  final List<Map<String, dynamic>> _samples = [
    {'id': 1, 'captured': false, 'quality': null},
    {'id': 2, 'captured': false, 'quality': null},
    {'id': 3, 'captured': false, 'quality': null},
  ];

  // ── Stage 4 Fields ─────────────────────────────────────────────────────────
  StreamSubscription? _gestureSub;
  bool _testSuccess = false;
  String _detectedGestureName = '';
  double _detectedConfidence = 0.0;
  Timer? _successFlashTimer;

  @override
  void initState() {
    super.initState();
    // Bypassing SmartWake ensures the camera initializes instantly for preview/recording
    GestureChannel.setSmartWakeEnabled(false);
    _startCameraCheck();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _cameraFrameSub?.cancel();
    _countdownTimer?.cancel();
    _recordProgressTimer?.cancel();
    _gestureSub?.cancel();
    _successFlashTimer?.cancel();
    
    // Restore SmartWake when bailing out of the wizard
    GestureChannel.setSmartWakeEnabled(true);
    super.dispose();
  }

  // ── Camera Flow ────────────────────────────────────────────────────────────
  void _startCameraCheck() {
    _cameraFrameSub?.cancel();
    _cameraFrameSub = GestureChannel.cameraFrameStream.listen((_) {
      if (!_cameraReady && mounted) {
        setState(() {
          _cameraReady = true;
        });
      }
    });
  }

  // ── Stage 3 Logic: Recording ────────────────────────────────────────────────
  void _startCountdown(int sampleIndex) {
    setState(() {
      _activeSampleIndex = sampleIndex;
      _countdown = 3;
      _isRecording = false;
      _recordProgress = 0.0;
    });

    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          if (_countdown > 1) {
            _countdown--;
          } else {
            _countdown = 0;
            timer.cancel();
            _startRecording();
          }
        });
      }
    });
  }

  void _startRecording() {
    setState(() {
      _isRecording = true;
      _recordProgress = 0.0;
    });

    const totalTicks = 30; // 30 ticks over 1.5 seconds (50ms interval)
    int currentTick = 0;

    _recordProgressTimer?.cancel();
    _recordProgressTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (mounted) {
        setState(() {
          currentTick++;
          _recordProgress = currentTick / totalTicks;
          if (currentTick >= totalTicks) {
            timer.cancel();
            _isRecording = false;
            _finalizeSample();
          }
        });
      }
    });
  }

  void _finalizeSample() {
    // Simulated quality score based on camera availability (Excellent/Good)
    final random = Random();
    final quality = random.nextBool() ? 'Excellent' : 'Good';

    setState(() {
      _samples[_activeSampleIndex]['captured'] = true;
      _samples[_activeSampleIndex]['quality'] = quality;
    });
  }

  void _redoSample(int index) {
    setState(() {
      _samples[index]['captured'] = false;
      _samples[index]['quality'] = null;
    });
    _startCountdown(index);
  }

  // ── Stage 4 Logic: Live Testing Sandbox ─────────────────────────────────────
  void _startGestureTesting() {
    _gestureSub?.cancel();
    _gestureSub = GestureChannel.gestureStream.listen((payload) {
      final parts = payload.split(':');
      if (parts.length == 2 && mounted) {
        final rawGesture = parts[0];
        final confidence = double.tryParse(parts[1]) ?? 0.0;

        if (_isGestureMatch(rawGesture, _selectedBaseGesture)) {
          HapticFeedback.mediumImpact();
          _successFlashTimer?.cancel();
          
          setState(() {
            _testSuccess = true;
            _detectedGestureName = _nameController.text.trim();
            _detectedConfidence = confidence;
          });

          // Flash green and clear success state after 1.5s
          _successFlashTimer = Timer(const Duration(milliseconds: 1500), () {
            if (mounted) {
              setState(() {
                _testSuccess = false;
              });
            }
          });
        }
      }
    });
  }

  bool _isGestureMatch(String detected, String selectedBase) {
    final cleanDetected = detected.toUpperCase();
    final cleanBase = selectedBase.toUpperCase();
    
    // Loosely check match against base categories
    if (cleanBase == 'WAVE' && cleanDetected.contains('WAVE')) return true;
    if (cleanBase == 'SWIPE' && cleanDetected.contains('SWIPE')) return true;
    if (cleanBase == 'PINCH' && cleanDetected.contains('PINCH')) return true;
    if (cleanBase == 'CIRCLE' && (cleanDetected.contains('CIRCLE') || cleanDetected.contains('ROTARY'))) return true;
    if (cleanBase == 'SPREAD' && (cleanDetected.contains('SPREAD') || cleanDetected.contains('PALM'))) return true;
    return false;
  }

  // ── Database Persistence ───────────────────────────────────────────────────
  Future<void> _saveGesture() async {
    final prefs = await SharedPreferences.getInstance();
    final gestures = prefs.getStringList('custom_gestures') ?? [];

    final newGesture = {
      'name': _nameController.text.trim().isNotEmpty ? _nameController.text.trim() : 'Untitled Gesture',
      'baseGesture': _selectedBaseGesture,
      'category': _category,
      'description': _descController.text.trim(),
    };

    gestures.add(jsonEncode(newGesture));
    await prefs.setStringList('custom_gestures', gestures);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gesture "${newGesture['name']}" saved successfully!'),
          backgroundColor: AppColorsShared.accent,
        ),
      );
      Navigator.of(context).pop();
    }
  }

  // ── Wizard Page Navigation ─────────────────────────────────────────────────
  void _nextStep() {
    if (_currentStep == 1) {
      setState(() => _currentStep = 2);
    } else if (_currentStep == 2) {
      setState(() => _currentStep = 3);
      // Automatically start countdown for first sample
      _startCountdown(0);
    } else if (_currentStep == 3) {
      setState(() => _currentStep = 4);
      _startGestureTesting();
    }
  }

  void _prevStep() {
    if (_currentStep > 1) {
      setState(() {
        _currentStep--;
        if (_currentStep == 3) {
          _startCameraCheck();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Create Custom Gesture',
          style: TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w700,
            fontSize: 16,
            color: cs.onSurface,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close_rounded, color: cs.onSurface, size: 24),
          onPressed: () => Navigator.of(context).pop(), // Bail without saving
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 8),
              // ── Wizard Progress Line ───────────────────────────────────────
              _buildProgressIndicator(),
              const SizedBox(height: 24),

              // ── Dynamic Step Content ───────────────────────────────────────
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: _buildStepContent(),
                ),
              ),

              // ── Bottom Navigation Controls ──────────────────────────────────
              _buildNavigationButtons(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // ── Step Indicator widget ──────────────────────────────────────────────────
  Widget _buildProgressIndicator() {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'STAGE $_currentStep OF 4',
              style: TextStyle(
                fontFamily: 'Space Mono',
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: AppColorsShared.accent,
                letterSpacing: 1.0,
              ),
            ),
            Text(
              _getStepTitle(),
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: cs.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: List.generate(4, (index) {
            final active = index < _currentStep;
            return Expanded(
              child: Container(
                height: 4,
                margin: EdgeInsets.only(right: index == 3 ? 0 : 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2),
                  color: active ? AppColorsShared.accent : cs.outlineVariant,
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  String _getStepTitle() {
    switch (_currentStep) {
      case 1: return 'Name & Describe';
      case 2: return 'Preview & Learn';
      case 3: return 'Record Samples';
      case 4: return 'Test & Confirm';
      default: return '';
    }
  }

  // ── Core wizard page builder ───────────────────────────────────────────────
  Widget _buildStepContent() {
    switch (_currentStep) {
      case 1: return _buildStage1();
      case 2: return _buildStage2();
      case 3: return _buildStage3();
      case 4: return _buildStage4();
      default: return const SizedBox();
    }
  }

  // ── Stage 1 Widget: Name & Describe ────────────────────────────────────────
  Widget _buildStage1() {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _nameController,
          style: TextStyle(fontFamily: 'Inter', color: cs.onSurface, fontWeight: FontWeight.w600),
          decoration: InputDecoration(
            labelText: 'Gesture Name',
            hintText: 'e.g. Double Wave Up',
            labelStyle: TextStyle(color: cs.onSurfaceVariant),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
            floatingLabelBehavior: FloatingLabelBehavior.always,
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 24),

        Text(
          'CATEGORY',
          style: TextStyle(fontFamily: 'Space Mono', fontSize: 11, fontWeight: FontWeight.w700, color: cs.onSurfaceVariant, letterSpacing: 0.5),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _CategorySelectorCard(
                title: 'Motion-based',
                subtitle: 'Swipes, waves, rotations',
                icon: Icons.gesture_rounded,
                selected: _category == 'Motion-based',
                onTap: () => setState(() => _category = 'Motion-based'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _CategorySelectorCard(
                title: 'Hold-based',
                subtitle: 'Static palm or finger signs',
                icon: Icons.back_hand_rounded,
                selected: _category == 'Hold-based',
                onTap: () => setState(() => _category = 'Hold-based'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        Text(
          'BASE GESTURE MATCH',
          style: TextStyle(fontFamily: 'Space Mono', fontSize: 11, fontWeight: FontWeight.w700, color: cs.onSurfaceVariant, letterSpacing: 0.5),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            border: Border.all(color: cs.outline),
            borderRadius: BorderRadius.circular(14),
            color: cs.surfaceContainerHighest.withValues(alpha: 0.2),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedBaseGesture,
              dropdownColor: cs.surface,
              isExpanded: true,
              items: _baseGestures.map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontFamily: 'Inter')))).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _selectedBaseGesture = val);
              },
            ),
          ),
        ),
        const SizedBox(height: 24),

        TextField(
          controller: _descController,
          maxLines: 3,
          style: TextStyle(fontFamily: 'Inter', color: cs.onSurface),
          decoration: InputDecoration(
            labelText: 'Description (Optional)',
            hintText: 'Describe how to execute the gesture...',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
            floatingLabelBehavior: FloatingLabelBehavior.always,
          ),
        ),
      ],
    );
  }

  // ── Stage 2 Widget: Preview & Learn ────────────────────────────────────────
  Widget _buildStage2() {
    final cs = Theme.of(context).colorScheme;
    return Column(
      children: [
        // Looping preview illustration
        Container(
          width: double.infinity,
          height: 160,
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: cs.outlineVariant),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _selectedBaseGesture == 'Wave'
                      ? Icons.waves_rounded
                      : _selectedBaseGesture == 'Swipe'
                          ? Icons.swipe_rounded
                          : Icons.back_hand_rounded,
                  size: 48,
                  color: AppColorsShared.accent,
                ),
                const SizedBox(height: 12),
                Text(
                  'Perform a steady ${_selectedBaseGesture.toLowerCase()} motion',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Keep your hand upright and open',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 28),

        // Live camera checking thumbnail & ready indicator
        Row(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: _cameraReady ? AppColorsShared.accent : cs.outline, width: 2),
                color: Colors.black,
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
                    return Center(child: Icon(Icons.videocam_off, size: 24, color: cs.onSurfaceVariant));
                  },
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _cameraReady ? const Color(0xFF00E676) : Colors.amber,
                          boxShadow: _cameraReady
                              ? [BoxShadow(color: const Color(0xFF00E676).withValues(alpha: 0.4), blurRadius: 6, spreadRadius: 2)]
                              : [],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _cameraReady ? 'CAMERA READY' : 'STARTING CAMERA...',
                        style: TextStyle(
                          fontFamily: 'Space Mono',
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: _cameraReady ? const Color(0xFF00E676) : Colors.amber,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Position your hand 30–80 cm away from the screen.',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      color: cs.onSurfaceVariant,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 28),

        // Quick tips
        _TipItem(icon: Icons.light_mode_rounded, label: 'Ensure your environment is well lit'),
        _TipItem(icon: Icons.center_focus_strong_rounded, label: 'Hold your hand steady directly in front of the camera'),
        _TipItem(icon: Icons.swipe_left_rounded, label: 'Keep movements moderate (not too fast)'),
      ],
    );
  }

  // ── Stage 3 Widget: Record Samples ─────────────────────────────────────────
  Widget _buildStage3() {
    final cs = Theme.of(context).colorScheme;
    return Column(
      children: [
        // Camera stream box
        Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: _isRecording ? AppColorsShared.accent : cs.outline,
                  width: 3,
                ),
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
                    return Center(child: Icon(Icons.videocam_off, size: 40, color: cs.onSurfaceVariant));
                  },
                ),
              ),
            ),

            // Countdown Overlay
            if (_countdown > 0)
              Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black.withValues(alpha: 0.6),
                ),
                child: Center(
                  child: Text(
                    '$_countdown',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 64,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

            // Recording progress circle overlay
            if (_isRecording)
              SizedBox(
                width: 190,
                height: 190,
                child: CircularProgressIndicator(
                  value: _recordProgress,
                  strokeWidth: 4,
                  color: const Color(0xFF00E676),
                  backgroundColor: Colors.transparent,
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          _countdown > 0
              ? 'Get ready...'
              : _isRecording
                  ? 'Perform gesture!'
                  : 'Capture 3 training samples',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: _isRecording ? const Color(0xFF00E676) : cs.onSurface,
          ),
        ),
        const SizedBox(height: 24),

        // Sample list cards
        Column(
          children: List.generate(3, (index) {
            final sample = _samples[index];
            final isCaptured = sample['captured'] as bool;
            final isCurrent = index == _activeSampleIndex;
            final quality = sample['quality'] as String?;

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isCurrent && !_isRecording && _countdown == 0
                    ? AppColorsShared.accent.withValues(alpha: 0.05)
                    : cs.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isCurrent && !_isRecording && _countdown == 0
                      ? AppColorsShared.accent
                      : cs.outlineVariant,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isCaptured ? Icons.check_circle_rounded : Icons.radio_button_off_rounded,
                    color: isCaptured ? const Color(0xFF00E676) : cs.onSurfaceVariant,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Sample ${index + 1}',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: cs.onSurface,
                    ),
                  ),
                  const Spacer(),
                  if (isCaptured) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: quality == 'Excellent'
                            ? const Color(0xFF00E676).withValues(alpha: 0.15)
                            : Colors.amber.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        quality ?? '',
                        style: TextStyle(
                          fontFamily: 'Space Mono',
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: quality == 'Excellent' ? const Color(0xFF00E676) : Colors.amber,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    IconButton(
                      icon: const Icon(Icons.replay_rounded, size: 18),
                      onPressed: () => _redoSample(index),
                    ),
                  ] else if (isCurrent && !_isRecording && _countdown == 0)
                    TextButton(
                      onPressed: () => _startCountdown(index),
                      child: const Text('Record'),
                    ),
                ],
              ),
            );
          }),
        ),
      ],
    );
  }

  // ── Stage 4 Widget: Test & Confirm ─────────────────────────────────────────
  Widget _buildStage4() {
    final cs = Theme.of(context).colorScheme;
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: _testSuccess ? const Color(0xFF00E676) : cs.outline,
                  width: _testSuccess ? 4 : 2,
                ),
                boxShadow: _testSuccess
                    ? [BoxShadow(color: const Color(0xFF00E676).withValues(alpha: 0.3), blurRadius: 10, spreadRadius: 4)]
                    : [],
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
                    return Center(child: Icon(Icons.videocam_off, size: 40, color: cs.onSurfaceVariant));
                  },
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _testSuccess
              ? Column(
                  key: const ValueKey('success'),
                  children: [
                    Text(
                      '$_detectedGestureName Detected!',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF00E676),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${(_detectedConfidence * 100).toInt()}% CONFIDENCE',
                      style: TextStyle(
                        fontFamily: 'Space Mono',
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColorsShared.accent,
                      ),
                    ),
                  ],
                )
              : Column(
                  key: const ValueKey('testing'),
                  children: [
                    Text(
                      'Test your gesture now',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: cs.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Perform a ${_selectedBaseGesture.toLowerCase()} movement in front of the camera.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        color: cs.onSurfaceVariant,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
        ),
        const SizedBox(height: 32),
        
        // Dynamic advice card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: cs.outlineVariant),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline_rounded, color: AppColorsShared.accent, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tips for recognition',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: cs.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'If detection fails, make sure your hand is fully upright, visible in the camera circle, and you are not moving too fast.',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        color: cs.onSurfaceVariant,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Bottom Nav Buttons Builder ─────────────────────────────────────────────
  Widget _buildNavigationButtons() {
    final cs = Theme.of(context).colorScheme;

    final isStage1Valid = _nameController.text.trim().isNotEmpty;
    final isStage3Valid = _samples.every((s) => s['captured'] == true);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        if (_currentStep > 1)
          Expanded(
            child: SizedBox(
              height: 52,
              child: OutlinedButton(
                onPressed: _prevStep,
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: cs.outline),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: Text(
                  'Back',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                  ),
                ),
              ),
            ),
          )
        else
          const Spacer(),
        
        const SizedBox(width: 12),

        Expanded(
          child: SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: _currentStep == 1
                  ? (isStage1Valid ? _nextStep : null)
                  : _currentStep == 2
                      ? (_cameraReady ? _nextStep : null)
                      : _currentStep == 3
                          ? (isStage3Valid ? _nextStep : null)
                          : _saveGesture,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColorsShared.accent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: Text(
                _currentStep == 4 ? 'Save & Finish' : 'Continue',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Components
// ─────────────────────────────────────────────────────────────────────────────

class _CategorySelectorCard extends StatelessWidget {
  const _CategorySelectorCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? AppColorsShared.accent.withValues(alpha: 0.05) : cs.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? AppColorsShared.accent : cs.outlineVariant,
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              color: selected ? AppColorsShared.accent : cs.onSurfaceVariant,
              size: 24,
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                color: cs.onSurfaceVariant,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TipItem extends StatelessWidget {
  const _TipItem({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: cs.onSurfaceVariant),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                color: cs.onSurfaceVariant,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
