import 'package:flutter/material.dart';
import '../home/home_screen.dart';
import '../profile/profile_screen.dart';
import '../gestures/gesture_library_screen.dart';
import '../settings/settings_screen.dart';

class ShellScreen extends StatefulWidget {
  const ShellScreen({super.key});

  @override
  State<ShellScreen> createState() => _ShellScreenState();
}

class _ShellScreenState extends State<ShellScreen> {
  int _selectedIndex = 0;

  static const _tabs = [
    HomeScreen(),
    ProfileScreen(),
    GestureLibraryScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _tabs,
      ),
      bottomNavigationBar: _CustomNavBar(
        selectedIndex: _selectedIndex,
        onItemSelected: (i) => setState(() => _selectedIndex = i),
      ),
    );
  }
}

class _CustomNavBar extends StatelessWidget {
  const _CustomNavBar({
    required this.selectedIndex,
    required this.onItemSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onItemSelected;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(
          top: BorderSide(color: cs.outline, width: 1),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _NavBarIcon(
                icon: Icons.home_outlined,
                isSelected: selectedIndex == 0,
                onTap: () => onItemSelected(0),
              ),
              _NavBarIcon(
                icon: Icons.manage_accounts_outlined,
                isSelected: selectedIndex == 1,
                onTap: () => onItemSelected(1),
              ),
              _NavBarIcon(
                icon: Icons.gesture_rounded, // squiggle
                isSelected: selectedIndex == 2,
                onTap: () => onItemSelected(2),
              ),
              _NavBarIcon(
                icon: Icons.settings_outlined,
                isSelected: selectedIndex == 3,
                onTap: () => onItemSelected(3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavBarIcon extends StatelessWidget {
  const _NavBarIcon({
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 64,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? cs.onSurface : cs.onSurfaceVariant,
              size: 26,
            ),
            const SizedBox(height: 6),
            AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: isSelected ? 1.0 : 0.0,
              child: Container(
                width: 4,
                height: 4,
                decoration: BoxDecoration(
                  color: cs.onSurface,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
