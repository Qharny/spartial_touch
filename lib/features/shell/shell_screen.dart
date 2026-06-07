import 'package:flutter/material.dart';
import '../../core/router/router.dart';
import '../../core/theme/theme.dart';
import '../home/home_screen.dart';
import '../search/search_screen.dart';
import '../profile/profile_screen.dart';

/// Persistent shell with animated bottom NavigationBar.
///
/// The [NavigationBar] handles tab switching via [IndexedStack] so that each
/// tab preserves its own navigator state and scroll position.
class ShellScreen extends StatefulWidget {
  const ShellScreen({super.key});

  @override
  State<ShellScreen> createState() => _ShellScreenState();
}

class _ShellScreenState extends State<ShellScreen> {
  int _selectedIndex = 0;

  static const _tabs = [
    HomeScreen(),
    SearchScreen(),
    ProfileScreen(),
  ];

  static const _navItems = [
    NavigationDestination(
      icon: Icon(Icons.home_outlined),
      selectedIcon: Icon(Icons.home_rounded),
      label: 'Home',
    ),
    NavigationDestination(
      icon: Icon(Icons.search_outlined),
      selectedIcon: Icon(Icons.search_rounded),
      label: 'Search',
    ),
    NavigationDestination(
      icon: Icon(Icons.person_outline_rounded),
      selectedIcon: Icon(Icons.person_rounded),
      label: 'Profile',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(
        index: _selectedIndex,
        children: _tabs,
      ),
      bottomNavigationBar: _AnimatedNavBar(
        selectedIndex: _selectedIndex,
        destinations: _navItems,
        onDestinationSelected: (i) => setState(() => _selectedIndex = i),
        onSettingsTap: () =>
            Navigator.of(context).pushNamed(AppRoutes.settings),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Animated Navigation Bar
// ─────────────────────────────────────────────────────────────────────────────

class _AnimatedNavBar extends StatelessWidget {
  const _AnimatedNavBar({
    required this.selectedIndex,
    required this.destinations,
    required this.onDestinationSelected,
    required this.onSettingsTap,
  });

  final int selectedIndex;
  final List<NavigationDestination> destinations;
  final ValueChanged<int> onDestinationSelected;
  final VoidCallback onSettingsTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: const Border(
          top: BorderSide(color: AppColors.outline, width: 1),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: [
              // Tabs
              Expanded(
                child: Row(
                  children: List.generate(destinations.length, (i) {
                    final selected = i == selectedIndex;
                    return Expanded(
                      child: _NavItem(
                        destination: destinations[i],
                        selected: selected,
                        onTap: () => onDestinationSelected(i),
                      ),
                    );
                  }),
                ),
              ),
              // Settings button (right side)
              _NavIconButton(
                icon: Icons.settings_outlined,
                onTap: onSettingsTap,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatefulWidget {
  const _NavItem({
    required this.destination,
    required this.selected,
    required this.onTap,
  });

  final NavigationDestination destination;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
      value: widget.selected ? 1 : 0,
    );
    _scale = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack),
    );
  }

  @override
  void didUpdateWidget(_NavItem old) {
    super.didUpdateWidget(old);
    if (widget.selected != old.selected) {
      if (widget.selected) {
        _ctrl.forward();
      } else {
        _ctrl.reverse();
      }
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selected = widget.selected;
    return GestureDetector(
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: ScaleTransition(
        scale: _scale,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              transitionBuilder: (child, anim) => ScaleTransition(
                scale: anim,
                child: FadeTransition(opacity: anim, child: child),
              ),
              child: KeyedSubtree(
                key: ValueKey(selected),
                child: selected
                    ? widget.destination.selectedIcon!
                    : widget.destination.icon,
              ),
            ),
            const SizedBox(height: 4),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: AppTextTheme.textTheme.labelSmall!.copyWith(
                color: selected ? AppColors.accent : AppColors.textDisabled,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              ),
              child: Text(widget.destination.label),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavIconButton extends StatelessWidget {
  const _NavIconButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: IconButton(
        icon: Icon(icon, size: 22),
        color: AppColors.textDisabled,
        onPressed: onTap,
        tooltip: 'Settings',
      ),
    );
  }
}
