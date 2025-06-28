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
  late PageController _pageController;

  final List<Widget> _pages = [
    const DashboardPage(),
    const ActivityLogPage(),
    const HealthTipsPage(),
    const ProfilePage(),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(
      initialPage: _currentIndex,
      viewportFraction: 1.0, // Ensure full viewport
      keepPage: true, // Keep page state for better performance
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 250), // Reduced duration for faster response
      curve: Curves.easeOut, // Changed to easeOut for more responsive feel
    );
    // Haptic feedback after animation starts
    if (index != _currentIndex) {
      Future.delayed(const Duration(milliseconds: 50), () {
        HapticFeedback.lightImpact();
      });
    }
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
    // Haptic feedback with minimal delay
    if (index != _currentIndex) {
      HapticFeedback.lightImpact();
    }
  }

  Future<bool> _onWillPop() async {
    if (_currentIndex != 0) {
      // If not on dashboard, go to dashboard
      setState(() {
        _currentIndex = 0;
      });
      _pageController.animateToPage(
        0,
        duration: const Duration(milliseconds: 250), // Reduced duration
        curve: Curves.easeOut, // Changed to easeOut
      );
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
        body: Stack(
          children: [
            PageView(
              controller: _pageController,
              onPageChanged: _onPageChanged,
              physics: const PageScrollPhysics(), // Use PageScrollPhysics for better page scrolling
              children: _pages,
            ),
            // Page indicator dots
            Positioned(
              top: MediaQuery.of(context).padding.top + 10,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_pages.length, (index) {
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _currentIndex == index 
                          ? Theme.of(context).primaryColor.withOpacity(0.8)
                          : Colors.grey.withOpacity(0.3),
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
        bottomNavigationBar: BottomNavBar(
          currentIndex: _currentIndex,
          onTap: _onTabTapped,
        ),
      ),
    );
  }
} 