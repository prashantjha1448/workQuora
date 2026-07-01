import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_colors.dart';

class MainShell extends StatelessWidget {
  const MainShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) => navigationShell.goBranch(
          index,
          // Tapping the already-active tab pops it back to its root (e.g.
          // clears Discover's drilled-in profile screen) instead of no-op.
          initialLocation: index == navigationShell.currentIndex,
        ),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home_rounded), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.search_rounded), selectedIcon: Icon(Icons.search_rounded), label: 'Discover'),
          NavigationDestination(icon: Icon(Icons.add_circle_outline_rounded), selectedIcon: Icon(Icons.add_circle_rounded), label: 'Post'),
          NavigationDestination(icon: Icon(Icons.mail_outline_rounded), selectedIcon: Icon(Icons.mail_rounded), label: 'Messages'),
          NavigationDestination(icon: Icon(Icons.person_outline_rounded), selectedIcon: Icon(Icons.person_rounded), label: 'Profile'),
        ],
      ),
    );
  }
}

/// Placeholder for tabs not yet built (Post / Messages / Profile — later phases).
class TabPlaceholderScreen extends StatelessWidget {
  const TabPlaceholderScreen({super.key, required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(label)),
      body: Center(
        child: Text('$label — coming in a later phase', style: const TextStyle(color: AppColors.onSurfaceVariant)),
      ),
    );
  }
}
