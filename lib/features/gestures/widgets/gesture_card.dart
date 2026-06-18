import 'package:flutter/material.dart';
import '../../../core/theme/theme.dart';

class GestureCard extends StatefulWidget {
  const GestureCard({
    super.key,
    required this.title,
    required this.icon,
    this.isActive = false,
    this.onTap,
    this.onToggleChanged,
    this.onDelete,
  });

  final String title;
  final IconData icon;
  final bool isActive;
  final VoidCallback? onTap;
  final ValueChanged<bool>? onToggleChanged;
  final VoidCallback? onDelete;

  @override
  State<GestureCard> createState() => _GestureCardState();
}

class _GestureCardState extends State<GestureCard> {
  late bool _enabled;

  @override
  void initState() {
    super.initState();
    _enabled = widget.isActive;
  }

  @override
  void didUpdateWidget(covariant GestureCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isActive != widget.isActive) {
      _enabled = widget.isActive;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: _enabled ? cs.surface : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _enabled ? AppColorsShared.accent : cs.outline,
            width: _enabled ? 1.5 : 1.0,
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (widget.onDelete != null)
                  GestureDetector(
                    onTap: widget.onDelete,
                    child: Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: Icon(Icons.delete_outline, color: cs.error, size: 20),
                    ),
                  )
                else
                  const SizedBox.shrink(),
                Transform.scale(
                  scale: 0.7,
                  child: Switch(
                    value: _enabled,
                    onChanged: (v) {
                      setState(() => _enabled = v);
                      widget.onToggleChanged?.call(v);
                    },
                    activeThumbColor: cs.surface,
                    activeTrackColor: AppColorsShared.accent,
                    inactiveThumbColor: cs.onSurfaceVariant,
                    inactiveTrackColor: cs.surfaceContainerHighest,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ],
            ),
            const Spacer(),
            Icon(
              widget.icon,
              size: 40,
              color: _enabled ? const Color(0xFF03DAC6) : cs.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              widget.title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: _enabled ? cs.onSurface : cs.onSurfaceVariant,
              ),
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}
