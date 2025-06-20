import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/welcome_page.dart';
import 'screens/login_page.dart';
import 'screens/register_page.dart';
import 'screens/dashboard_page.dart';
import 'screens/activity_log_page.dart';
import 'screens/health_tips_page.dart';
import 'screens/profile_page.dart';
import 'screens/notifications_page.dart';
import 'screens/leaderboard_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const StepWiseApp());
}

class StepWiseApp extends StatelessWidget {
  const StepWiseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'StepWise',
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (context) => WelcomePage(),
        '/login': (context) => LoginPage(),
        '/register': (context) => RegisterPage(),
        '/dashboard': (context) => DashboardPage(),
        '/activity-log': (context) => ActivityLogPage(),
        '/health-tips': (context) => HealthTipsPage(),
        '/profile': (context) => ProfilePage(),
        '/notifications': (context) => NotificationsPage(),
        '/leaderboard': (context) => LeaderboardPage(),
      },
    );
  }
}
