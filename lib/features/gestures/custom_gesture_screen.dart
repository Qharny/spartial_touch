import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../main.dart';
import '../../core/models/custom_pose.dart';
import '../../core/theme/theme.dart';
import '../../core/services/gesture_channel.dart';

/// One recorded training sample of the pose being created.
class _Sample {
  bool captured = false;
  String? quality; // 'Excellent' | 'Good' | 'Unsteady'
  List<double>? landmarks; // averaged raw landmarks, 42 values
}

/// Records a custom hand pose from real MediaPipe landmarks: three held samples,
/// each graded by how steady the hand was, then a live test against them.
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

  // ── Stage 2 Fields ─────────────────────────────────────────────────────────
  bool _cameraReady = false;
  bool _cameraDenied = false;
  StreamSubscription? _cameraFrameSub;

  // ── Stage 3 Fields ─────────────────────────────────────────────────────────
  static const _minFrames = 8;
  int _countdown = 0;
  bool _isRecording = false;
  int _activeSampleIndex = 0;
  Timer? _countdownTimer;
  Timer? _recordProgressTimer;
  double _recordProgress = 0.0;
  String? _sampleError;
  final List<List<double>> _recordFrames = [];
  StreamSubscription<List<double>>? _landmarkSub;

  final List<_Sample> _samples = [_Sample(), _Sample(), _Sample()];

  // ── Stage 4 Fields ─────────────────────────────────────────────────────────
  bool _testSuccess = false;
  double _detectedConfidence = 0.0;
  int _testMatchFrames = 0;
  Timer? _successFlashTimer;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _startCamera();
    // Every frame with a visible hand: recorded while a sample is capturing,
    // matched against the samples on the test step.
    _landmarkSub = GestureChannel.landmarkStream.listen(_onLandmarks);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _cameraFrameSub?.cancel();
    _landmarkSub?.cancel();
    _countdownTimer?.cancel();
    _recordProgressTimer?.cancel();
    _successFlashTimer?.cancel();
    // Restore SmartWake and stop the service if only this screen started it.
    GestureChannel.setSmartWakeEnabled(true);
    gestureRecognitionService.stopListening();
    super.dispose();
  }

  // ── Camera Flow ────────────────────────────────────────────────────────────
  Future<void> _startCamera() async {
    final status = await Permission.camera.request();
    if (!status.isGranted) {
      if (mounted) setState(() => _cameraDenied = true);
      return;
    }
    // The wizard needs the engine running and the camera forced on. It used to
    // only bypass SmartWake, so with the service off no frame ever arrived.
    await gestureRecognitionService.startListening();
    await GestureChannel.setSmartWakeEnabled(false);
    _cameraFrameSub?.cancel();
    _cameraFrameSub = GestureChannel.cameraFrameStream.listen((_) {
      if (!_cameraReady && mounted) setState(() => _cameraReady = true);
    });
  }

  void _onLandmarks(List<double> frame) {
    if (frame.length < PoseMath.points * 2) return;
    final points = frame.sublist(0, PoseMath.points * 2);
    if (_isRecording) {
      _recordFrames.add(points);
    } else if (_currentStep == 4) {
      _testFrame(points);
    }
  }

  // ── Stage 3 Logic: Recording ────────────────────────────────────────────────
  void _startCountdown(int sampleIndex) {
    setState(() {
      _activeSampleIndex = sampleIndex;
      _countdown = 3;
      _isRecording = false;
      _recordProgress = 0.0;
      _sampleError = null;
    });

    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        if (_countdown > 1) {
          _countdown--;
        } else {
          _countdown = 0;
          timer.cancel();
          _startRecording();
        }
      });
    });
  }

  void _startRecording() {
    _recordFrames.clear();
    setState(() {
      _isRecording = true;
      _recordProgress = 0.0;
    });

    const totalTicks = 30; // 1.5 seconds at 50ms
    int currentTick = 0;

    _recordProgressTimer?.cancel();
    _recordProgressTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (!mounted) return;
      setState(() {
        currentTick++;
        _recordProgress = currentTick / totalTicks;
        if (currentTick >= totalTicks) {
          timer.cancel();
          _isRecording = false;
          _finalizeSample();
        }
      });
    });
  }

  void _finalizeSample() {
    final sample = _samples[_activeSampleIndex];
    final frames = List<List<double>>.of(_recordFrames);
    _recordFrames.clear();

    if (frames.length < _minFrames) {
      sample
        ..captured = false
        ..quality = null
        ..landmarks = null;
      _sampleError = frames.isEmpty
          ? "Couldn't see your hand. Keep it fully in view and try again."
          : 'Your hand was only visible briefly. Hold it in view and try again.';
      return;
    }

    // Steadiness grades the sample: mean drift of each frame from the average pose.
    final jitter = PoseMath.jitter(frames);
    sample
      ..captured = true
      ..landmarks = PoseMath.average(frames)
      ..quality = jitter < 0.08
          ? 'Excellent'
          : jitter < 0.16
              ? 'Good'
              : 'Unsteady';
    _sampleError = null;

    // Move on to the next sample that still needs recording.
    final next = _samples.indexWhere((s) => !s.captured);
    if (next != -1) _activeSampleIndex = next;
  }

  void _redoSample(int index) {
    setState(() {
      _samples[index]
        ..captured = false
        ..quality = null
        ..landmarks = null;
    });
    _startCountdown(index);
  }

  // ── Stage 4 Logic: Live Testing Sandbox ─────────────────────────────────────
  /// Same rule the engine uses: within the match radius of any sample for
  /// HOLD_FRAMES consecutive frames.
  void _testFrame(List<double> raw) {
    final frame = PoseMath.normalize(raw);
    if (frame == null) return;
    var best = double.infinity;
    for (final s in _samples) {
      final n = s.landmarks == null ? null : PoseMath.normalize(s.landmarks!);
      if (n == null) continue;
      final d = PoseMath.distance(frame, n);
      if (d < best) best = d;
    }
    if (best > PoseMath.baseMatchThreshold) {
      _testMatchFrames = 0;
      return;
    }
    _testMatchFrames++;
    if (_testMatchFrames < 6) return;
    _testMatchFrames = 0;

    HapticFeedback.mediumImpact();
    _successFlashTimer?.cancel();
    if (!mounted) return;
    setState(() {
      _testSuccess = true;
      _detectedConfidence = 1 - 0.5 * (best / PoseMath.baseMatchThreshold);
    });
    _successFlashTimer = Timer(const Duration(milliseconds: 1500), () {
      if (mounted) setState(() => _testSuccess = false);
    });
  }

  // ── Persistence ────────────────────────────────────────────────────────────
  Future<void> _saveGesture() async {
    if (_saving) return;
    setState(() => _saving = true);
    final name = _nameController.text.trim().isNotEmpty ? _nameController.text.trim() : 'Untitled Gesture';
    final pose = CustomPose(
      key: '$kCustomGesturePrefix${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      description: _descController.text.trim(),
      samples: [for (final s in _samples) if (s.landmarks != null) s.landmarks!],
    );
    try {
      await CustomPoseStore.instance.add(pose);
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not save gesture: $e')));
      }
      return;
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('"$name" saved. Open it in Gestures to assign an action.'),
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
      _startCountdown(_samples.indexWhere((s) => !s.captured).clamp(0, 2));
    } else if (_currentStep == 3) {
      setState(() {
        _currentStep = 4;
        _testMatchFrames = 0;
      });
    }
  }

  void _prevStep() {
    if (_currentStep > 1) {
      setState(() {
        _currentStep--;
        _isRecording = false;
        _countdown = 0;
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
            hintText: 'e.g. Peace Sign',
            labelStyle: TextStyle(color: cs.onSurfaceVariant),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
            floatingLabelBehavior: FloatingLabelBehavior.always,
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 24),

        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColorsShared.accent.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColorsShared.accent.withValues(alpha: 0.4)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.back_hand_rounded, color: AppColorsShared.accent),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Custom gestures are hand poses: the shape of your hand, held still for about '
                  'half a second. Pick something distinct from the built-in gestures, like a '
                  'peace sign or an OK sign.',
                  style: TextStyle(fontFamily: 'Inter', fontSize: 13, height: 1.45, color: cs.onSurface),
                ),
              ),
            ],
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
                const Icon(Icons.back_hand_rounded, size: 48, color: AppColorsShared.accent),
                const SizedBox(height: 12),
                Text(
                  'Make your pose and hold it still',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'The whole hand must stay inside the camera view',
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
                        _cameraDenied
                            ? 'CAMERA PERMISSION NEEDED'
                            : _cameraReady
                                ? 'CAMERA READY'
                                : 'STARTING CAMERA...',
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
        _TipItem(icon: Icons.pan_tool_alt_rounded, label: 'Record all three samples with the same pose, slightly varying the angle'),
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
                  ? 'Hold your pose!'
                  : 'Capture 3 training samples',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: _isRecording ? const Color(0xFF00E676) : cs.onSurface,
          ),
        ),
        if (_sampleError != null) ...[
          const SizedBox(height: 8),
          Text(
            _sampleError!,
            textAlign: TextAlign.center,
            style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: cs.error),
          ),
        ],
        const SizedBox(height: 24),

        // Sample list cards
        Column(
          children: List.generate(3, (index) {
            final sample = _samples[index];
            final isCaptured = sample.captured;
            final isCurrent = index == _activeSampleIndex;
            final quality = sample.quality;

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
                      onPressed: _cameraReady ? () => _startCountdown(index) : null,
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
                      '${_nameController.text.trim()} detected!',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF00E676),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${(_detectedConfidence * 100).toInt()}% MATCH',
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
                      'Make your pose in front of the camera and hold it still. '
                      'Then try a different hand shape: it should not match.',
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
                      'If it never matches, go back and re-record any "Unsteady" samples. If other hand shapes match too, pick a more distinctive pose.',
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
    final isStage3Valid = _samples.every((s) => s.captured);

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
                          : (_saving ? null : _saveGesture),
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
