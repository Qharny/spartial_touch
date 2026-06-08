import 'package:flutter/material.dart';
import '../../core/router/router.dart';
import '../../core/theme/theme.dart';

class GestureLibraryScreen extends StatelessWidget {
  const GestureLibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Gestures',
          style: TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w800,
            fontSize: 22,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu_rounded),
          onPressed: () {},
        ),
      ),
      body: GridView.count(
        crossAxisCount: 2,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 0.9,
        children: const [
          _GestureCard(
            title: 'Wave Up',
            icon: Icons.arrow_upward_rounded,
            isActive: true,
          ),
          _GestureCard(
            title: 'Clockwise Circle',
            icon: Icons.rotate_right_rounded,
            isActive: false,
          ),
          _GestureCard(
            title: 'Pinch',
            icon: Icons.pinch_rounded,
            isActive: false,
          ),
          _GestureCard(
            title: 'Swipe Left',
            icon: Icons.arrow_back_rounded,
            isActive: true,
          ),
          _GestureCard(
            title: 'Double Tap',
            icon: Icons.touch_app_rounded,
            isActive: false,
          ),
          _GestureCard(
            title: 'Spread',
            icon: Icons.open_in_full_rounded,
            isActive: false,
          ),
          _GestureCard(
            title: 'Palm In',
            icon: Icons.pan_tool_rounded,
            isActive: true,
          ),
          _GestureCard(
            title: 'Rotate',
            icon: Icons.screen_rotation_rounded,
            isActive: false,
          ),
        ],
      ),
    );
  }
}

class _GestureCard extends StatefulWidget {
  const _GestureCard({
    required this.title,
    required this.icon,
    this.isActive = false,
  });

  final String title;
  final IconData icon;
  final bool isActive;

  @override
  State<_GestureCard> createState() => _GestureCardState();
}

class _GestureCardState extends State<_GestureCard> {
  late bool _enabled;

  @override
  void initState() {
    super.initState();
    _enabled = widget.isActive;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).pushNamed(AppRoutes.gestureDetail),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: _enabled ? AppColors.surface : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _enabled ? AppColors.accent : AppColors.outline,
            width: _enabled ? 1.5 : 1.0,
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Transform.scale(
                  scale: 0.7,
                  child: Switch(
                    value: _enabled,
                    onChanged: (v) => setState(() => _enabled = v),
                    activeThumbColor: Colors.white,
                    activeTrackColor: AppColors.accent,
                    inactiveThumbColor: const Color(0xFF7A7890),
                    inactiveTrackColor: AppColors.surfaceVariant,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ],
            ),
            const Spacer(),
            Icon(
              widget.icon,
              size: 40,
              color: _enabled ? const Color(0xFF03DAC6) : const Color(0xFF7A7890),
            ),
            const SizedBox(height: 16),
            Text(
              widget.title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: _enabled ? Colors.white : const Color(0xFF7A7890),
              ),
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}
