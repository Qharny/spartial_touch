import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/router/router.dart';
import '../../core/services/gesture_channel.dart';
import '../../core/services/gesture_recognition_service.dart';
import '../../core/theme/theme.dart';

/// The "Live" tab: what the engine is recognising right now, without opening
/// the camera preview. Gestures only arrive while the service is running.
class LiveMonitorScreen extends StatefulWidget {
  const LiveMonitorScreen({super.key});

  @override
  State<LiveMonitorScreen> createState() => _LiveMonitorScreenState();
}

class _RecentGesture {
  _RecentGesture(this.event, this.at);
  final GestureEvent event;
  final DateTime at;
}

class _LiveMonitorScreenState extends State<LiveMonitorScreen> {
  static const _maxRecent = 12;

  StreamSubscription<String>? _sub;
  Timer? _statusTimer;
  final List<_RecentGesture> _recent = [];
  bool _running = false;
  bool _pausedBySchedule = false;
  int _today = 0;

  @override
  void initState() {
    super.initState();
    _sub = GestureChannel.gestureStream.listen((payload) {
      if (!mounted) return;
      setState(() {
        _recent.insert(0, _RecentGesture(GestureEvent.fromPayload(payload), DateTime.now()));
        if (_recent.length > _maxRecent) _recent.removeLast();
        _today++;
      });
    });
    _refreshStatus();
    _statusTimer = Timer.periodic(const Duration(seconds: 3), (_) => _refreshStatus());
  }

  Future<void> _refreshStatus() async {
    final running = await GestureChannel.isServiceRunning();
    final stats = await GestureChannel.getServiceStats();
    if (!mounted) return;
    setState(() {
      _running = running;
      _pausedBySchedule = stats['pausedBySchedule'] == true;
      _today = (stats['todayGestures'] as num?)?.toInt() ?? _today;
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    _statusTimer?.cancel();
    super.dispose();
  }

  String _ago(DateTime t) {
    final s = DateTime.now().difference(t).inSeconds;
    if (s < 5) return 'just now';
    if (s < 60) return '${s}s ago';
    return '${s ~/ 60}m ago';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final last = _recent.isEmpty ? null : _recent.first;
    final statusText = !_running
        ? 'Service is off — turn it on from Home'
        : _pausedBySchedule
            ? 'Paused outside your active hours'
            : 'Listening for gestures';
    final statusColor = _running && !_pausedBySchedule ? AppColorsShared.accent : cs.onSurfaceVariant;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Live',
          style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w800, fontSize: 22),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Open camera tester',
            icon: const Icon(Icons.videocam_outlined),
            onPressed: () => Navigator.of(context).pushNamed(AppRoutes.gestureTester),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 100),
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  statusText,
                  style: TextStyle(fontFamily: 'Inter', fontSize: 14, color: statusColor, fontWeight: FontWeight.w600),
                ),
              ),
              Text(
                '$_today today',
                style: TextStyle(fontFamily: 'Space Mono', fontSize: 13, color: cs.onSurfaceVariant),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: last == null ? cs.outline : AppColorsShared.accent),
            ),
            child: Column(
              children: [
                Icon(Icons.back_hand_rounded, size: 56, color: last == null ? cs.onSurfaceVariant : AppColorsShared.accent),
                const SizedBox(height: 20),
                Text(
                  last?.event.name ?? 'No gestures yet',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontFamily: 'Syne', fontWeight: FontWeight.w700, fontSize: 28, color: cs.onSurface),
                ),
                const SizedBox(height: 8),
                Text(
                  last == null
                      ? 'Perform a gesture in front of the camera.'
                      : '${(last.event.confidence * 100).round()}% confidence · ${_ago(last.at)}',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontFamily: 'Inter', fontSize: 14, color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ),
          if (_recent.length > 1) ...[
            const SizedBox(height: 32),
            Text(
              'RECENT',
              style: TextStyle(
                fontFamily: 'Space Mono',
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
                color: cs.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            for (final r in _recent.skip(1))
              ListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                title: Text(r.event.name, style: TextStyle(fontFamily: 'Inter', color: cs.onSurface)),
                trailing: Text(
                  '${(r.event.confidence * 100).round()}% · ${_ago(r.at)}',
                  style: TextStyle(fontFamily: 'Space Mono', fontSize: 12, color: cs.onSurfaceVariant),
                ),
              ),
          ],
        ],
      ),
    );
  }
}
