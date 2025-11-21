import 'package:flutter/material.dart';
import 'package:gateway_config/presentation/pages/home/home_screen.dart';
import 'package:gateway_config/presentation/pages/settings/settings_screen.dart';
import 'package:gateway_config/presentation/widgets/common/app_bottom_navigation.dart';
import 'package:go_router/go_router.dart';

class MainScreen extends StatefulWidget {
  final int initialIndex;

  const MainScreen({super.key, this.initialIndex = 0});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  void _onNavItemTapped(int index) {
    if (_currentIndex != index) {
      setState(() {
        _currentIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: const [
          HomeScreen(showBottomNav: true),
          SettingsScreen(showBottomNav: true),
        ],
      ),
      bottomNavigationBar: AppBottomNavigation(
        currentIndex: _currentIndex,
        onIndexChanged: _onNavItemTapped,
      ),
      floatingActionButton: ModernFAB(
        onPressed: () => context.pushNamed('add-device'),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}
