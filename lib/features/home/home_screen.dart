import 'package:flutter/material.dart';
import '../../core/theme/theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  bool _isActive = false;
  late AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  void _toggleService() {
    setState(() {
      _isActive = !_isActive;
      if (_isActive) {
        _pulseCtrl.forward(from: 0);
        _pulseCtrl.repeat(reverse: true);
      } else {
        _pulseCtrl.stop();
        _pulseCtrl.value = 0;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'SpatialTouch',
          style: TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w800,
            fontSize: 22,
            letterSpacing: -0.5,
            color: cs.onSurface,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.menu_rounded, color: cs.onSurface),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 100),
        child: Column(
          children: [
            // ── Large ON/OFF Toggle ────────────────────────────────────────
            GestureDetector(
              onTap: _toggleService,
              behavior: HitTestBehavior.opaque,
              child: AnimatedBuilder(
                animation: _pulseCtrl,
                builder: (context, child) {
                  // Breathe effect when active
                  final glow = _isActive ? (10 + 20 * _pulseCtrl.value) : 0.0;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 400),
                    width: 240,
                    height: 240,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _isActive
                          ? AppColorsShared.accent.withValues(alpha: 0.1)
                          : Colors.transparent,
                      border: Border.all(
                        color: _isActive
                            ? AppColorsShared.accent
                            : cs.outline,
                        width: _isActive ? 2 : 1,
                      ),
                      boxShadow: _isActive
                          ? [
                              BoxShadow(
                                color: AppColorsShared.accent.withValues(alpha: 0.15),
                                blurRadius: glow,
                                spreadRadius: glow / 2,
                              )
                            ]
                          : [],
                    ),
                    child: Center(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 400),
                        child: Icon(
                          Icons.gesture_rounded,
                          key: ValueKey(_isActive),
                          size: 72,
                          color: _isActive ? AppColorsShared.accent : cs.onSurface,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 32),

            // ── Service Status Badge ───────────────────────────────────────
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 400),
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                letterSpacing: 1.5,
                fontWeight: FontWeight.w700,
                color: _isActive ? AppColorsShared.accent : cs.onSurfaceVariant,
              ),
              child: Text(_isActive ? 'SERVICE RUNNING' : 'SERVICE STANDBY'),
            ),

            const SizedBox(height: 48),

            // ── 3 Stat Tiles ───────────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: _StatTile(
                    label: 'PROFILE',
                    value: 'Default',
                    isActive: _isActive,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatTile(
                    label: 'GESTURES',
                    value: _isActive ? '142' : '0',
                    isActive: false,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatTile(
                    label: 'IMPACT',
                    value: _isActive ? '1.2%' : '0.0%',
                    isActive: false,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 40),

            // ── Quick Test Area ────────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: cs.outline),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Quick Test',
                    style: TextStyle(
                      color: cs.onSurface,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Syne',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Open the mini gesture tester to check your camera view and lighting.',
                    style: TextStyle(
                      color: cs.onSurfaceVariant,
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: cs.surfaceContainerHighest,
                        foregroundColor: cs.onSurface,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: BorderSide(color: cs.outline),
                        ),
                      ),
                      icon: const Icon(Icons.videocam_outlined, size: 20),
                      label: const Text(
                        'Test a gesture now',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Inter',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── Quick-access Cards ─────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: _QuickAccessCard(
                    icon: Icons.app_settings_alt_rounded,
                    title: 'Profiles',
                    onTap: () {},
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _QuickAccessCard(
                    icon: Icons.auto_awesome_motion_rounded,
                    title: 'Gestures',
                    onTap: () {},
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _QuickAccessCard(
                    icon: Icons.settings_rounded,
                    title: 'Settings',
                    onTap: () {},
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Components
// ─────────────────────────────────────────────────────────────────────────────

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    this.isActive = false,
  });

  final String label;
  final String value;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
              color: cs.onSurfaceVariant,
              fontFamily: 'Space Mono',
            ),
          ),
          const SizedBox(height: 8),
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 300),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: isActive ? const Color(0xFF03DAC6) : cs.onSurface,
              fontFamily: 'Inter',
            ),
            child: Text(value),
          ),
        ],
      ),
    );
  }
}

class _QuickAccessCard extends StatelessWidget {
  const _QuickAccessCard({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: cs.outline, width: 1),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColorsShared.accent, size: 24),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                color: cs.onSurface,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                fontFamily: 'Inter',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
