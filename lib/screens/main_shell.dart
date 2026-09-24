import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/notification_service.dart';
import 'home_screen.dart';
import 'my_assets_screen.dart';
import 'lost_assets_screen.dart';
import 'profile_screen.dart';

// Tab index constants — used by child screens to request navigation
class MainShellTabs {
  static const int home = 0;
  static const int myAssets = 1;
  static const int lost = 2;
  static const int profile = 3;
}

class MainShell extends StatefulWidget {
  final int initialIndex;

  const MainShell({super.key, this.initialIndex = 0});

  /// Switch the bottom nav tab from anywhere inside the widget tree.
  /// Usage: MainShell.of(context)?.switchTab(MainShellTabs.myAssets);
  static MainShellState? of(BuildContext context) =>
      context.findAncestorStateOfType<MainShellState>();

  @override
  State<MainShell> createState() => MainShellState();
}

class MainShellState extends State<MainShell> {
  late int _currentIndex;

  final List<Widget> _pages = const [
    HomeScreen(),
    MyAssetsScreen(),
    LostAssetsScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    
    // Start polling for notifications
    NotificationService.instance.startPolling();
  }

  /// Public method — child screens call this to switch tabs.
  void switchTab(int index) {
    if (index < 0 || index >= _pages.length) return;
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppTheme.cardColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(15),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: BottomNavigationBar(
              currentIndex: _currentIndex,
              onTap: (i) => setState(() => _currentIndex = i),
              elevation: 0,
              backgroundColor: Colors.transparent,
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.home_outlined),
                  activeIcon: Icon(Icons.home),
                  label: 'Home',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.inventory_2_outlined),
                  activeIcon: Icon(Icons.inventory_2),
                  label: 'My Assets',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.gps_off_outlined),
                  activeIcon: Icon(Icons.gps_off),
                  label: 'Lost',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.person_outline),
                  activeIcon: Icon(Icons.person),
                  label: 'Profile',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
