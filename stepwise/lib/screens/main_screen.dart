import 'package:flutter/material.dart';
import 'package:stepwise/screens/activity_log_page.dart';
import 'package:stepwise/screens/dashboard_page.dart';
import 'package:stepwise/screens/health_tips_page.dart';
import 'package:stepwise/screens/profile_page.dart';
import 'package:stepwise/widgets/bottom_nav_bar.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
      ),
    );
  }
} 