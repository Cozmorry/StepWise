import 'package:flutter/material.dart';
import 'package:stepwise/screens/activity_log_page.dart';
import 'package:stepwise/screens/dashboard_page.dart';
import 'package:stepwise/screens/health_tips_page.dart';
import 'package:stepwise/screens/profile_page.dart';
import 'package:stepwise/widgets/bottom_nav_bar.dart';
import 'package:flutter/services.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  DateTime? _lastBackPress;

  final List<Widget> _pages = [
    const DashboardPage(),
    const ActivityLogPage(),
    const HealthTipsPage(),
    const ProfilePage(),
  ];

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  Future<bool> _onWillPop() async {
    if (_currentIndex != 0) {
      // If not on dashboard, go to dashboard
      setState(() {
        _currentIndex = 0;
      });
      return false;
    } else {
      // If on dashboard, check for double tap to exit
      final now = DateTime.now();
      if (_lastBackPress == null || now.difference(_lastBackPress!) > const Duration(seconds: 2)) {
        _lastBackPress = now;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Press back again to exit'),
            duration: Duration(seconds: 2),
          ),
        );
        return false;
      }
      // Exit the app
      SystemNavigator.pop();
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        body: _pages[_currentIndex],
        bottomNavigationBar: BottomNavBar(
          currentIndex: _currentIndex,
          onTap: _onTabTapped,
        ),
      ),
    );
  }
} 