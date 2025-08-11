import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/welcome_page.dart';
import 'screens/login_page.dart';
import 'screens/register_page.dart';
import 'screens/notifications_page.dart';
import 'screens/main_screen.dart';
import 'screens/profile_onboarding_page.dart';
import 'screens/edit_profile_page.dart';
import 'theme/app_theme.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'models/activity_record.dart';
import 'models/user_profile.dart';
import 'screens/activity_log_page.dart';
// Import NotificationItemAdapter
import 'screens/leaderboard_page.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'screens/badges_page.dart';
import 'screens/reminders_page.dart';
import 'models/reminder.dart';
import 'screens/trends_page.dart';
import 'screens/personalized_messages_page.dart';
import 'services/leaderboard_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  Hive.registerAdapter(ActivityRecordAdapter());
  Hive.registerAdapter(UserProfileAdapter());
  Hive.registerAdapter(NotificationItemAdapter()); // Register NotificationItem adapter
  Hive.registerAdapter(ReminderAdapter());
  await Hive.openBox<ActivityRecord>('activity_log');
  await Hive.openBox<UserProfile>('user_profiles');
  await Hive.openBox<NotificationItem>('notifications'); // Open notifications box
  await Hive.openBox<Reminder>('reminders');
  await Firebase.initializeApp();
  
  // Check current user at startup for debugging
  final currentUser = FirebaseAuth.instance.currentUser;
  print('App startup - Current user: ${currentUser?.uid}');
  
  // Store user ID in SharedPreferences for persistence fallback
  if (currentUser != null) {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('persisted_user_id', currentUser.uid);
    print('Stored user ID in SharedPreferences: ${currentUser.uid}');
  }
  
  final prefs = await SharedPreferences.getInstance();
  await NotificationHelper.initialize();
  
  // Perform daily leaderboard reset check on app startup
  await LeaderboardService.performDailyResetIfNeeded();

  // Local notifications setup (without permission request)
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
  const InitializationSettings initializationSettings = InitializationSettings(android: initializationSettingsAndroid);
  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  runApp(ChangeNotifierProvider(
    create: (_) => ThemeModeNotifier(prefs),
    child: const StepWiseApp(),
  ));
}

class ThemeModeNotifier extends ChangeNotifier {
  final SharedPreferences _prefs;
  late ThemeMode _themeMode;

  ThemeModeNotifier(this._prefs) {
    _loadTheme();
  }

  ThemeMode get themeMode => _themeMode;

  void _loadTheme() {
    final themeString = _prefs.getString('themeMode') ?? 'system';
    _themeMode = ThemeMode.values.firstWhere(
        (e) => e.name == themeString,
        orElse: () => ThemeMode.system);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;
    _themeMode = mode;
    notifyListeners();
    await _prefs.setString('themeMode', mode.name);
  }
}

class StepWiseApp extends StatelessWidget {
  const StepWiseApp({super.key});

  Future<bool> _shouldShowWelcome() async {
    final prefs = await SharedPreferences.getInstance();
    final seen = prefs.getBool('hasSeenWelcome') ?? false;
    return !seen;
  }

  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeModeNotifier>(context);
    
    return MaterialApp(
      title: 'StepWise',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeNotifier.themeMode,
      home: FutureBuilder<bool>(
        future: _shouldShowWelcome(),
        builder: (context, welcomeSnapshot) {
          if (welcomeSnapshot.connectionState != ConnectionState.done) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }
          if (welcomeSnapshot.data == true) {
            return WelcomePage(onFinish: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool('hasSeenWelcome', true);
              Navigator.pushReplacementNamed(context, '/register');
            });
          }
          // Not first launch: check auth state
          return StreamBuilder<User?>(
            stream: FirebaseAuth.instance.authStateChanges(),
            builder: (context, snapshot) {
              print('Auth state changed - connection state: ${snapshot.connectionState}');
              print('Auth state changed - has data: ${snapshot.hasData}');
              print('Auth state changed - user: ${snapshot.data?.uid}');
              print('Auth state changed - error: ${snapshot.error}');
              
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(body: Center(child: CircularProgressIndicator()));
              }
              
              // Check for errors
              if (snapshot.hasError) {
                print('Auth state error: ${snapshot.error}');
                // On error, try to get current user directly
                final currentUser = FirebaseAuth.instance.currentUser;
                if (currentUser != null) {
                  print('Current user found directly: ${currentUser.uid}');
                  return const MainScreen();
                }
              }
              
              // Check if user is authenticated
              if (snapshot.hasData && snapshot.data != null) {
                print('User authenticated, showing MainScreen');
                return const MainScreen();
              }
              
              // Double-check current user before showing login
              final currentUser = FirebaseAuth.instance.currentUser;
              if (currentUser != null) {
                print('Current user found on double-check: ${currentUser.uid}');
                return const MainScreen();
              }
              
              // Additional fallback: check if we have a recent authentication
              // This helps with cases where the auth state stream might be temporarily unavailable
              return FutureBuilder<User?>(
                future: Future.delayed(const Duration(milliseconds: 200), () async {
                  try {
                    return FirebaseAuth.instance.currentUser;
                  } catch (e) {
                    print('Error getting current user: $e');
                    return null;
                  }
                }),
                builder: (context, futureSnapshot) {
                  if (futureSnapshot.hasData && futureSnapshot.data != null) {
                    print('User found in fallback check: ${futureSnapshot.data!.uid}');
                    return const MainScreen();
                  }
                  
                  // Final fallback: check SharedPreferences for persisted user ID
                  return FutureBuilder<String?>(
                    future: SharedPreferences.getInstance().then((prefs) => prefs.getString('persisted_user_id')),
                    builder: (context, prefsSnapshot) {
                      if (prefsSnapshot.hasData && prefsSnapshot.data != null) {
                        print('Found persisted user ID: ${prefsSnapshot.data}');
                        // If we have a persisted user ID but no current user, 
                        // try to restore the session or show login
                        return const LoginPage();
                      }
                      
                      print('No user authenticated, showing LoginPage');
                      return const LoginPage();
                    },
                  );
                },
              );
            },
          );
        },
      ),
      routes: {
        '/login': (context) => const LoginPage(),
        '/register': (context) => const RegisterPage(),
        '/dashboard': (context) => const MainScreen(),
        '/notifications': (context) => const NotificationsPage(),
        '/profile-onboarding': (context) => const ProfileOnboardingPage(),
        '/activity-log': (context) => const ActivityLogPage(),
        '/leaderboard': (context) => const LeaderboardPage(),
        '/badges': (context) => const BadgesPage(),
        '/personalized-messages': (context) => const PersonalizedMessagesPage(),
        '/reminders': (context) => const RemindersPage(),
        '/trends': (context) => const TrendsPage(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/edit-profile') {
          final userProfile = settings.arguments as UserProfile;
          return MaterialPageRoute(
            builder: (context) {
              return EditProfilePage(userProfile: userProfile);
            },
          );
        }
        return null;
      },
    );
  }
}
