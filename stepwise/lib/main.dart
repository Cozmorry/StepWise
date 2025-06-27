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
import 'package:firebase_messaging/firebase_messaging.dart';
import 'screens/leaderboard_page.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'screens/badges_page.dart';
import 'screens/reminders_page.dart';
import 'models/reminder.dart';

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
  final prefs = await SharedPreferences.getInstance();
  await NotificationHelper.initialize();

  // Firebase Messaging setup
  FirebaseMessaging messaging = FirebaseMessaging.instance;
  await messaging.requestPermission();

  // Local notifications setup
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
  const InitializationSettings initializationSettings = InitializationSettings(android: initializationSettingsAndroid);
  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    print('Received a message: ${message.notification?.title}');
    if (message.notification != null) {
      flutterLocalNotificationsPlugin.show(
        message.notification.hashCode,
        message.notification?.title,
        message.notification?.body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'default_channel',
            'Default',
            importance: Importance.max,
            priority: Priority.high,
          ),
        ),
      );
    }
  });

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
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(body: Center(child: CircularProgressIndicator()));
              }
              if (snapshot.hasData) {
                return const MainScreen();
              }
              return const LoginPage();
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
        '/reminders': (context) => const RemindersPage(),
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
