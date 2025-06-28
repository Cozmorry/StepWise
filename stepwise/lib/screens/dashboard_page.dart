import 'dart:async';
import 'package:flutter/material.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:hive/hive.dart';
import '../models/activity_record.dart';
import '../models/user_profile.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'notifications_page.dart';
import 'package:confetti/confetti.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/achievements.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  DashboardPageState createState() => DashboardPageState();
}

class DashboardPageState extends State<DashboardPage> {
  StreamSubscription<StepCount>? _stepCountStreamSubscription;
  int _steps = 0;
  int _todaySteps = 0;
  int _baselineSteps = 0;
  DateTime? _baselineDate;
  UserProfile? _userProfile;
  late Box<ActivityRecord> _activityBox;
  String? _pedometerError;
  bool _isPedometerActive = false;
  String? _notificationError;
  double _distanceInKm = 0.0;
  int _caloriesBurned = 0;
  int _activeStreak = 0;
  final List<String> _quotes = [
    'Every step counts! Keep moving.',
    'Small steps every day lead to big results.',
    'Stay active, stay healthy.',
    'You are stronger than you think.',
    'Consistency is the key to success.',
    'Your only limit is you.',
    'Push yourself, because no one else is going to do it for you.',
  ];
  int _quoteIndex = 0;
  late ConfettiController _confettiController;
  int? _pedometerBaseline;
  int? _suggestedGoal;
  final bool _hideSuggestedGoal = false;
  DateTime? _lastConfettiDate;
  DateTime? _lastGoalBannerActionDate;
  bool _showGoalHint = false;
  final bool _isInitialized = false;
  bool _isInitializing = false; // Add flag to prevent concurrent initialization

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 2));
    _loadBannerAndConfettiPrefs();
    _initDependencies();
    _startQuoteRotation();
    _checkGoalHint();
    _scheduleDailySummary(); // Add daily summary scheduling
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Request permissions immediately when dashboard loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _requestPermissions();
      if (!_isPedometerActive && !_isInitializing) {
        _checkAndInitPedometer();
      }
    });
  }

  Future<void> _requestPermissions() async {
    // Request activity recognition permission immediately when dashboard loads
    print('Requesting activity recognition permission...');
    final activityStatus = await Permission.activityRecognition.request();
    
    if (activityStatus.isGranted) {
      print('Activity recognition permission granted');
      if (mounted) {
        setState(() {
          _pedometerError = null;
        });
      }
    } else if (activityStatus.isDenied) {
      print('Activity recognition permission denied');
      if (mounted) {
        setState(() {
          _pedometerError = "Permission Denied. Please enable activity tracking in settings.";
        });
      }
    } else if (activityStatus.isPermanentlyDenied) {
      print('Activity recognition permission permanently denied');
      if (mounted) {
        setState(() {
          _pedometerError = "Permission permanently denied. Please enable activity tracking in app settings.";
        });
      }
    }

    // Request notification permission
    print('Requesting notification permission...');
    final notificationStatus = await Permission.notification.request();
    
    if (notificationStatus.isGranted) {
      print('Notification permission granted');
      if (mounted) {
        setState(() {
          _notificationError = null;
        });
      }
    } else if (notificationStatus.isDenied) {
      print('Notification permission denied');
      if (mounted) {
        setState(() {
          _notificationError = "Notification permission denied. Please enable notifications in settings.";
        });
      }
    } else if (notificationStatus.isPermanentlyDenied) {
      print('Notification permission permanently denied');
      if (mounted) {
        setState(() {
          _notificationError = "Notification permission permanently denied. Please enable notifications in app settings.";
        });
      }
    }
  }

  Future<void> _checkAndInitPedometer() async {
    if (await _hasCompletedOnboarding() && !_isPedometerActive) {
      print('User completed onboarding, initializing pedometer...');
      await _initPedometer();
    }
  }

  @override
  void dispose() {
    _stepCountStreamSubscription?.cancel();
    _confettiController.dispose();
    super.dispose();
  }

  Future<void> _loadBannerAndConfettiPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final confettiStr = prefs.getString('lastConfettiDate');
    if (confettiStr != null) {
      _lastConfettiDate = DateTime.tryParse(confettiStr);
    }
    final bannerStr = prefs.getString('lastGoalBannerActionDate');
    if (bannerStr != null) {
      _lastGoalBannerActionDate = DateTime.tryParse(bannerStr);
    }
    setState(() {});
  }

  Future<void> _initDependencies() async {
    if (_isInitializing) {
      print('Initialization already in progress, skipping...');
      return;
    }
    
    _isInitializing = true;
    try {
      _activityBox = Hive.box<ActivityRecord>('activity_log');
      await _loadUserProfile();
      await _loadBaseline();
      await _restoreDataFromFirestore();
      await _syncMissedPedometerSteps();
      await _loadTodayStepCount();
      await _initPedometer();
      _calculateActiveStreak();
      _calculateSuggestedGoal();
    } finally {
      _isInitializing = false;
    }
  }

  Future<void> _loadUserProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final box = Hive.box<UserProfile>('user_profiles');
      var userProfile = box.get(user.uid);
      if (userProfile == null) {
        // Try to fetch from Firestore
        final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (doc.exists) {
          userProfile = UserProfile.fromMap(doc.data()!);
          await box.put(user.uid, userProfile);
        }
      }
      if (mounted) {
        setState(() {
          _userProfile = userProfile;
        });
      }
    }
  }

  Future<void> _loadBaseline() async {
    final prefs = await SharedPreferences.getInstance();
    final baseline = prefs.getInt('baseline_steps') ?? 0;
    final baselineDateStr = prefs.getString('baseline_date');
    DateTime? baselineDate;
    if (baselineDateStr != null) {
      baselineDate = DateTime.tryParse(baselineDateStr);
    }
    _baselineSteps = baseline;
    _baselineDate = baselineDate;
    
    // Load pedometer baseline
    _pedometerBaseline = prefs.getInt('pedometer_baseline');
    print('Loaded pedometer baseline: $_pedometerBaseline');
    print('Loaded baseline steps: $_baselineSteps');
    print('Loaded baseline date: $_baselineDate');
  }

  Future<void> _saveBaseline(int steps) async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    await prefs.setInt('baseline_steps', steps);
    await prefs.setString('baseline_date', now.toIso8601String());
    _baselineSteps = steps;
    _baselineDate = now;
  }

  Future<void> _savePedometerBaseline(int baseline) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('pedometer_baseline', baseline);
    _pedometerBaseline = baseline;
  }

  void _checkAndUpdateBaseline(int currentSteps) async {
    final now = DateTime.now();
    if (_baselineDate == null ||
        _baselineDate!.year != now.year ||
        _baselineDate!.month != now.month ||
        _baselineDate!.day != now.day) {
      await _saveBaseline(currentSteps);
    }
  }

  Future<void> _initPedometer() async {
    if (_isPedometerActive) {
      print('Pedometer already active, skipping initialization');
      return;
    }
    
    // Check if user has completed onboarding first
    if (!await _hasCompletedOnboarding()) {
      print('User has not completed onboarding, skipping pedometer initialization');
      return;
    }
    
    // Cancel any existing stream first
    await _stepCountStreamSubscription?.cancel();
    _stepCountStreamSubscription = null;
    
    print('Initializing pedometer...');
    if (await Permission.activityRecognition.isGranted) {
      print('Activity recognition permission already granted');
      
      try {
        // Start the stream first to get real-time updates
        _stepCountStreamSubscription = Pedometer.stepCountStream.listen(
          _onStepCount,
          onError: _onStepCountError,
          cancelOnError: true,
        );
        
        if (mounted) {
          setState(() {
            _isPedometerActive = true;
            _pedometerError = null;
          });
        }
        print('Pedometer stream started');
      } catch (e) {
        print('Error starting pedometer stream: $e');
        if (mounted) {
          setState(() {
            _pedometerError = 'Failed to start pedometer: $e';
            _isPedometerActive = false;
          });
        }
      }
    } else {
      print('Activity recognition permission not granted');
      if (mounted) {
        setState(() {
          _pedometerError = "Permission required. Please enable activity tracking in settings.";
        });
      }
    }
  }

  Future<bool> _hasCompletedOnboarding() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;
    
    final box = Hive.box<UserProfile>('user_profiles');
    final profile = box.get(user.uid);
    
    // User has completed onboarding if they have a profile with required fields
    return profile != null && 
           profile.name.isNotEmpty && 
           profile.height > 0 && 
           profile.weight > 0;
  }

  Future<void> _loadTodayStepCount() async {
    final todayKey = _getTodayKey();
    final todayRecord = _activityBox.get(todayKey);
    if (todayRecord != null) {
      if (mounted) {
        setState(() {
          _steps = (todayRecord.manualSteps ?? 0) + (todayRecord.pedometerSteps ?? 0);
          _todaySteps = _steps;
          // Calculate distance and calories from latest steps
          if (_userProfile != null) {
            final strideLength = _userProfile!.height * 0.415 / 100; // in meters
            _distanceInKm = (_steps * strideLength) / 1000;
            _caloriesBurned = (_steps * _userProfile!.weight * 0.0005).round();
          }
          _updateCalculations();
        });
      }
    }
  }

  void _onStepCount(StepCount event) async {
    if (!mounted) return;
    
    // Initialize pedometer baseline if not set
    if (_pedometerBaseline == null) {
      _pedometerBaseline = event.steps;
      _savePedometerBaseline(event.steps);
      return; // Don't process this first event to avoid double counting
    }
    
    // Calculate steps since baseline
    int pedometerSteps = event.steps - _pedometerBaseline!;
    
    // Check if this is a new day and reset baseline if needed
    final now = DateTime.now();
    final baselineDate = _baselineDate;
    if (baselineDate == null || 
        baselineDate.year != now.year || 
        baselineDate.month != now.month || 
        baselineDate.day != now.day) {
      _pedometerBaseline = event.steps;
      _savePedometerBaseline(event.steps);
      _saveBaseline(event.steps);
      pedometerSteps = 0;
    }
    
    if (pedometerSteps < 0) {
      // If pedometer was reset or device restarted, update baseline
      _pedometerBaseline = event.steps;
      _savePedometerBaseline(event.steps);
      pedometerSteps = 0;
    }
    
    // Get existing data
    final todayKey = _getTodayKey();
    final todayRecord = _activityBox.get(todayKey);
    int existingPedometerSteps = todayRecord?.pedometerSteps ?? 0;
    int manualSteps = todayRecord?.manualSteps ?? 0;
    
    // Only add new steps, not the total
    int newPedometerSteps = pedometerSteps;
    int totalSteps = manualSteps + newPedometerSteps;
    
    // Only update if steps actually changed
    if (newPedometerSteps == existingPedometerSteps) {
      return;
    }
    
    final activity = todayRecord ?? ActivityRecord(
      date: DateTime.now(),
      steps: 0,
      distance: 0,
      calories: 0,
    );
    activity.steps = totalSteps;
    activity.manualSteps = manualSteps;
    activity.pedometerSteps = newPedometerSteps;
    
    // Calculate distance and calories from latest steps
    double distance = 0.0;
    int calories = 0;
    if (_userProfile != null) {
      final strideLength = _userProfile!.height * 0.415 / 100; // in meters
      distance = (totalSteps * strideLength) / 1000;
      calories = (totalSteps * _userProfile!.weight * 0.0005).round();
    }
    activity.distance = distance;
    activity.calories = calories;
    
    // Sync to both Hive and Firebase for maximum reliability
    await _syncToBothStorages(todayKey, activity);
    
    setState(() {
      _steps = totalSteps;
      _todaySteps = totalSteps;
      _distanceInKm = distance;
      _caloriesBurned = calories;
    });
    
    // Update Firestore steps for leaderboard (async, don't wait)
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'steps': totalSteps,
      }, SetOptions(merge: true)).catchError((e) {
        print('Error updating Firestore: $e');
      });
    }
    
    // Achievement check
    _checkAndAwardAchievements();
    
    // Confetti when goal is reached, only once per day
    final goal = _userProfile?.dailyStepGoal ?? 10000;
    final today = DateTime.now();
    final isToday = _lastConfettiDate != null &&
        _lastConfettiDate!.year == today.year &&
        _lastConfettiDate!.month == today.month &&
        _lastConfettiDate!.day == today.day;
    if (_todaySteps >= goal && !isToday) {
      _confettiController.play();
      _lastConfettiDate = today;
      SharedPreferences.getInstance().then((prefs) {
        prefs.setString('lastConfettiDate', today.toIso8601String());
      });
      
      // Add goal achievement notification
      await NotificationHelper.showReminder(
        title: '🎯 Goal Achieved!',
        body: 'Congratulations! You reached your daily goal of $goal steps!',
        id: 888, // Special ID for goal achievement
      );
      
      // Add to notification history
      final notificationBox = Hive.box<NotificationItem>('notifications');
      final notification = NotificationItem(
        id: 'goal_${today.millisecondsSinceEpoch}',
        text: '🎯 You reached your daily goal of $goal steps!',
        timestamp: today,
        type: NotificationType.achievement,
      );
      await notificationBox.add(notification);
    }
  }

  // Sync activity data to both Hive and Firebase for maximum reliability
  Future<void> _syncActivityToFirestore(String dateKey, ActivityRecord activity) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // First ensure Hive is updated (local storage)
        _activityBox.put(dateKey, activity);
        print('✅ Saved to Hive: $dateKey - ${activity.steps} steps');
        
        // Then sync to Firebase (cloud storage)
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('activities')
            .doc(dateKey)
            .set({
          'date': activity.date.toIso8601String(),
          'steps': activity.steps,
          'manualSteps': activity.manualSteps ?? 0,
          'pedometerSteps': activity.pedometerSteps ?? 0,
          'distance': activity.distance,
          'calories': activity.calories,
          'updatedAt': DateTime.now().toIso8601String(),
        }, SetOptions(merge: true));
        
        print('✅ Synced to Firebase: $dateKey - ${activity.steps} steps');
      }
    } catch (e) {
      print('❌ Error syncing to Firebase: $e');
      // Even if Firebase fails, Hive data is still saved locally
      print('✅ Data still saved locally in Hive');
    }
  }

  // Enhanced sync method that ensures both storages are updated
  Future<void> _syncToBothStorages(String dateKey, ActivityRecord activity) async {
    // Always save to Hive first (local, fast, reliable)
    _activityBox.put(dateKey, activity);
    
    // Then sync to Firebase (cloud, for persistence across devices/reinstalls)
    await _syncActivityToFirestore(dateKey, activity);
  }

  void _onStepCountError(error) {
    if (!mounted) return;
    
    print('Pedometer error: $error');
    
    // Don't cancel the stream on error, just log it
    setState(() {
      _pedometerError = 'Pedometer error: $error';
      // Don't set _isPedometerActive to false here to avoid re-initialization
    });
    
    // Try to recover by re-initializing after a delay
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted && _isPedometerActive) {
        print('Attempting to recover from pedometer error...');
        _initPedometer();
      }
    });
  }

  void _updateCalculations() {
    if (_userProfile == null) return;
    final strideLength = _userProfile!.height * 0.415 / 100; // in meters
    _distanceInKm = (_todaySteps * strideLength) / 1000;
    _caloriesBurned = (_todaySteps * _userProfile!.weight * 0.0005).round();
  }
  
  void _calculateActiveStreak() {
    final activityKeys = _activityBox.keys.cast<String>().toList();
    activityKeys.sort((a, b) => b.compareTo(a)); 

    int streak = 0;
    if (activityKeys.isEmpty) {
      _activeStreak = 0;
      return;
    }
    
    DateTime today = DateTime.now();
    DateTime lastDate = DateTime.parse(activityKeys.first);

    // Check if the latest record is today or yesterday
    if (today.difference(lastDate).inDays > 1) {
      _activeStreak = 0;
      return;
    }

    streak = 1;
    for (int i = 0; i < activityKeys.length - 1; i++) {
        DateTime currentDate = DateTime.parse(activityKeys[i]);
        DateTime previousDate = DateTime.parse(activityKeys[i+1]);
        if (currentDate.difference(previousDate).inDays == 1) {
            streak++;
        } else {
            break; 
        }
    }
    _activeStreak = streak;
  }

  String _getTodayKey() {
    final now = DateTime.now();
    return "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
  }

  void _saveStepCount(int steps) {
    final todayKey = _getTodayKey();
    _updateCalculations();

    final activity = _activityBox.get(todayKey) ??
        ActivityRecord(
          date: DateTime.now(),
          steps: 0,
          distance: 0,
          calories: 0,
        );

    activity.steps = steps;
    activity.distance = _distanceInKm;
    activity.calories = _caloriesBurned;
    _activityBox.put(todayKey, activity);

    // Update Firestore steps for leaderboard
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'steps': steps,
      }, SetOptions(merge: true));
    }
  }

  void _startQuoteRotation() {
    void rotate() {
      Future.delayed(const Duration(seconds: 8), () {
        if (!mounted) return;
        setState(() {
          _quoteIndex = (_quoteIndex + 1) % _quotes.length;
        });
        rotate();
      });
    }
    rotate();
  }

  void _calculateSuggestedGoal() {
    final now = DateTime.now();
    // Banner should only show if 7 days have passed since last action
    if (_lastGoalBannerActionDate != null && now.difference(_lastGoalBannerActionDate!).inDays < 7) {
      _suggestedGoal = null;
      return;
    }
    final last7Days = List.generate(7, (i) {
      final date = now.subtract(Duration(days: i));
      final key = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
      return _activityBox.get(key)?.steps ?? 0;
    });
    final avg = last7Days.reduce((a, b) => a + b) ~/ 7;
    int suggestion = ((avg * 1.1) ~/ 100) * 100; // +10%, rounded to nearest 100
    suggestion = suggestion.clamp(8000, 15000); // healthy range
    if (_userProfile != null && suggestion != _userProfile!.dailyStepGoal) {
      _suggestedGoal = suggestion;
    } else {
      _suggestedGoal = null;
    }
  }

  Future<void> _acceptSuggestedGoal() async {
    if (_userProfile == null || _suggestedGoal == null) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final box = Hive.box<UserProfile>('user_profiles');
      final profile = box.get(user.uid);
      if (profile != null) {
        profile.dailyStepGoal = _suggestedGoal!;
        await box.put(user.uid, profile);
        setState(() {
          _userProfile = profile;
        });
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'dailyStepGoal': _suggestedGoal!,
        }, SetOptions(merge: true));
        // Store banner action date
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('lastGoalBannerActionDate', DateTime.now().toIso8601String());
        setState(() {
          _suggestedGoal = null;
        });
      }
    }
  }

  Future<void> _refreshData() async {
    if (_isInitializing) {
      print('Refresh skipped - initialization in progress');
      return;
    }
    
    print('Refreshing dashboard data...');
    await _loadUserProfile();
    await _loadBaseline();
    await _restoreDataFromFirestore();
    await _syncMissedPedometerSteps();
    await _loadTodayStepCount();
    _calculateActiveStreak();
    _calculateSuggestedGoal();
    
    // Check if we should initialize pedometer (e.g., after onboarding completion)
    if (!_isPedometerActive && await _hasCompletedOnboarding()) {
      print('User completed onboarding, initializing pedometer...');
      await _initPedometer();
    }
    
    if (mounted) {
      setState(() {});
    }
  }

  // Method to retry pedometer initialization (can be called from other screens)
  Future<void> retryPedometerInitialization() async {
    if (await _hasCompletedOnboarding()) {
      print('Retrying pedometer initialization...');
      await _initPedometer();
    }
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final goal = _userProfile?.dailyStepGoal ?? 10000;
    final progress = (goal > 0) ? (_todaySteps / goal).clamp(0.0, 1.0) : 0.0;

    return Scaffold(
      backgroundColor: AppColors.getBackground(brightness),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16.0),
          child: Transform.rotate(
            angle: -1.5708, // -90 degrees in radians
            child: FaIcon(FontAwesomeIcons.shoePrints, color: AppColors.getPrimary(brightness), size: 32),
          ),
        ),
        title: Text('Dashboard', style: AppTextStyles.title(brightness)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.notifications_none, color: AppColors.getPrimary(brightness)),
            onPressed: () {
              Navigator.pushNamed(context, '/notifications');
            },
            tooltip: 'Notifications',
          ),
          IconButton(
            icon: Icon(Icons.send, color: AppColors.getPrimary(brightness)),
            onPressed: () async {
              // Manual trigger for daily summary notification
              await NotificationHelper.showSummary(steps: _todaySteps, distanceKm: _distanceInKm);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Daily summary notification sent!')),
                );
              }
            },
            tooltip: 'Send Daily Summary Now',
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(18.0),
          child: _userProfile == null
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: _refreshData,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Personalized greeting
                        Text(
                          '${_getGreeting()}, ${_userProfile!.name}!',
                          style: AppTextStyles.heading(brightness),
                        ),
                        const SizedBox(height: 8),
                        // Permission status indicator
                        _buildPermissionStatus(brightness),
                        const SizedBox(height: 8),
                        // Scroll hint (only show for first few uses)
                        _buildScrollHint(brightness),
                        // Goal setting hint
                        if (_showGoalHint)
                          Card(
                            color: AppColors.getSecondary(brightness),
                            elevation: 2,
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.flag,
                                    color: Colors.green,
                                    size: 24,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '🎯 Set your daily goal!',
                                          style: AppTextStyles.subtitle(brightness).copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Tap "Set Goal" below to customize your step target',
                                          style: AppTextStyles.body(brightness),
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.close, color: Colors.grey[600]),
                                    onPressed: _dismissGoalHint,
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        // Goal suggestion banner
                        if (_suggestedGoal != null)
                          Card(
                            color: Colors.amber[100],
                            elevation: 0,
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                              child: Row(
                                children: [
                                  const Icon(Icons.flag, color: Colors.orange, size: 32),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Suggested Goal', style: AppTextStyles.subtitle(brightness).copyWith(color: Colors.brown[900])),
                                        Text('Try $_suggestedGoal steps/day for a healthy challenge!', style: AppTextStyles.body(brightness).copyWith(color: Colors.brown[900])),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    children: [
                                      ElevatedButton(
                                        onPressed: _acceptSuggestedGoal,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.orange,
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                        ),
                                        child: const Text('Accept'),
                                      ),
                                      const SizedBox(height: 8),
                                      TextButton(
                                        onPressed: () async {
                                          final prefs = await SharedPreferences.getInstance();
                                          await prefs.setString('lastGoalBannerActionDate', DateTime.now().toIso8601String());
                                          setState(() {
                                            _suggestedGoal = null;
                                          });
                                        },
                                        child: const Text('Cancel'),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        // Rotating motivational quote
                        Center(
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 600),
                            child: Text(
                              _quotes[_quoteIndex],
                              key: ValueKey(_quoteIndex),
                              style: AppTextStyles.subtitle(brightness).copyWith(fontStyle: FontStyle.italic),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Animated step progress ring with confetti
                        Center(
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              SizedBox(
                                width: 200,
                                height: 200,
                                child: CircularProgressIndicator(
                                  value: progress,
                                  strokeWidth: 12,
                                  backgroundColor: AppColors.getSecondary(brightness),
                                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.getPrimary(brightness)),
                                ),
                              ),
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    '$_todaySteps',
                                    style: AppTextStyles.heading(brightness).copyWith(fontSize: 48),
                                  ),
                                  Text(
                                    '/$goal Steps',
                                    style: AppTextStyles.body(brightness),
                                  ),
                                ],
                              ),
                              // Confetti
                              Positioned.fill(
                                child: IgnorePointer(
                                  child: ConfettiWidget(
                                    confettiController: _confettiController,
                                    blastDirectionality: BlastDirectionality.explosive,
                                    shouldLoop: false,
                                    emissionFrequency: 0.12,
                                    numberOfParticles: 20,
                                    maxBlastForce: 20,
                                    minBlastForce: 8,
                                    gravity: 0.2,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Streak badge
                        if (_activeStreak > 1)
                          Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.orange.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.local_fire_department, color: Colors.orange, size: 28),
                                  const SizedBox(width: 8),
                                  Text(
                                    '$_activeStreak-day streak!',
                                    style: AppTextStyles.body(brightness).copyWith(fontWeight: FontWeight.w600, color: Colors.orange),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        const SizedBox(height: 18),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildStatCard('Calories', '${_caloriesBurned.toStringAsFixed(0)} kcal', Icons.local_fire_department, brightness),
                            _buildStatCard('Distance', '${_distanceInKm.toStringAsFixed(2)} km', Icons.map_outlined, brightness),
                          ],
                        ),
                        const SizedBox(height: 18),
                        // Leaderboard card
                        GestureDetector(
                          onTap: () {
                            Navigator.pushNamed(context, '/leaderboard');
                          },
                          child: Card(
                            color: AppColors.getSecondary(brightness),
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                              child: Row(
                                children: [
                                  Icon(Icons.leaderboard, color: AppColors.getPrimary(brightness), size: 36),
                                  const SizedBox(width: 18),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Leaderboard', style: AppTextStyles.subtitle(brightness)),
                                        Text('See top steppers!', style: AppTextStyles.body(brightness)),
                                      ],
                                    ),
                                  ),
                                  Icon(Icons.arrow_forward_ios, color: AppColors.getPrimary(brightness), size: 20),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Reminders card
                        GestureDetector(
                          onTap: () {
                            Navigator.pushNamed(context, '/reminders');
                          },
                          child: Card(
                            color: AppColors.getSecondary(brightness),
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                              child: Row(
                                children: [
                                  Icon(Icons.alarm, color: AppColors.getPrimary(brightness), size: 36),
                                  const SizedBox(width: 18),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Reminders', style: AppTextStyles.subtitle(brightness)),
                                        Text('Set activity reminders!', style: AppTextStyles.body(brightness)),
                                      ],
                                    ),
                                  ),
                                  Icon(Icons.arrow_forward_ios, color: AppColors.getPrimary(brightness), size: 20),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Trends card
                        GestureDetector(
                          onTap: () {
                            Navigator.pushNamed(context, '/trends');
                          },
                          child: Card(
                            color: AppColors.getSecondary(brightness),
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                              child: Row(
                                children: [
                                  Icon(Icons.show_chart, color: AppColors.getPrimary(brightness), size: 36),
                                  const SizedBox(width: 18),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Trends', style: AppTextStyles.subtitle(brightness)),
                                        Text('View your progress graphs!', style: AppTextStyles.body(brightness)),
                                      ],
                                    ),
                                  ),
                                  Icon(Icons.arrow_forward_ios, color: AppColors.getPrimary(brightness), size: 20),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _logActivity,
                                icon: const Icon(Icons.add),
                                label: const Text('Log Activity'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.getPrimary(brightness),
                                  foregroundColor: AppColors.buttonText,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.pushNamed(context, '/activity-log');
                                },
                                icon: const Icon(Icons.history),
                                label: const Text('View History'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.getSecondary(brightness),
                                  foregroundColor: AppColors.getPrimary(brightness),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _showSetGoalDialog,
                                icon: const Icon(Icons.flag, size: 28),
                                label: const Text('Set Goal', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.getPrimary(brightness),
                                  foregroundColor: AppColors.buttonText,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    side: BorderSide(color: AppColors.getPrimary(brightness), width: 2),
                                  ),
                                  elevation: 4,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        if (_pedometerError != null)
                          Center(
                            child: Column(
                              children: [
                                Text(
                                  _pedometerError!,
                                  style: AppTextStyles.body(brightness).copyWith(color: Colors.red),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 8),
                                ElevatedButton(
                                  onPressed: () => openAppSettings(),
                                  child: const Text('Open Settings'),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Brightness brightness) {
    return Expanded(
      child: Card(
        color: AppColors.getSecondary(brightness),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              (icon == Icons.directions_walk || icon == Icons.directions_run)
                  ? Transform.rotate(
                      angle: -1.5708, // -90 degrees in radians
                      child: FaIcon(FontAwesomeIcons.shoePrints, color: AppColors.getPrimary(brightness), size: 28),
                    )
                  : Icon(icon, color: AppColors.getPrimary(brightness), size: 28),
              const SizedBox(height: 8),
              Text(title, style: AppTextStyles.subtitle(brightness)),
              Text(value, style: AppTextStyles.title(brightness)),
            ],
          ),
        ),
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 18) return 'Good afternoon';
    return 'Good evening';
  }

  void _logActivity() {
    final dateController = TextEditingController(text: DateTime.now().toIso8601String().substring(0, 10));
    final stepsController = TextEditingController();
    DateTime selectedDate = DateTime.now();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Log Activity'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: dateController,
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: 'Date',
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.calendar_today),
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) {
                          selectedDate = picked;
                          dateController.text = picked.toIso8601String().substring(0, 10);
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: stepsController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Steps'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final steps = int.tryParse(stepsController.text) ?? 0;
                if (steps > 0) {
                  final key = '${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}';
                  final existing = _activityBox.get(key);
                  int manualSteps = steps + (existing?.manualSteps ?? 0);
                  int pedometerSteps = existing?.pedometerSteps ?? 0;
                  int totalSteps = manualSteps + pedometerSteps;
                  // Calculate distance and calories from latest steps
                  double distance = 0.0;
                  int calories = 0;
                  if (_userProfile != null) {
                    final strideLength = _userProfile!.height * 0.415 / 100; // in meters
                    distance = (totalSteps * strideLength) / 1000;
                    calories = (totalSteps * _userProfile!.weight * 0.0005).round();
                  }
                  final activity = existing ?? ActivityRecord(
                    date: selectedDate,
                    steps: 0,
                    distance: 0,
                    calories: 0,
                  );
                  activity.manualSteps = manualSteps;
                  activity.pedometerSteps = pedometerSteps;
                  activity.steps = totalSteps;
                  activity.distance = distance;
                  activity.calories = calories;
                  
                  // Sync to both Hive and Firebase for maximum reliability
                  await _syncToBothStorages(key, activity);
                  
                  if (key == _getTodayKey()) {
                    setState(() {
                      _steps = totalSteps;
                      _todaySteps = totalSteps;
                      _distanceInKm = distance;
                      _caloriesBurned = calories;
                      _updateCalculations();
                    });
                    // Update Firestore steps for leaderboard if logging for today
                    final user = FirebaseAuth.instance.currentUser;
                    if (user != null) {
                      FirebaseFirestore.instance.collection('users').doc(user.uid).set({
                        'steps': totalSteps,
                      }, SetOptions(merge: true));
                    }
                  }
                  // Achievement check
                  _checkAndAwardAchievements();
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Activity logged!')),
                  );
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _showSetGoalDialog() {
    final controller = TextEditingController(text: (_userProfile?.dailyStepGoal ?? 10000).toString());
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Set Daily Step Goal'),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Steps'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final newGoal = int.tryParse(controller.text);
                if (newGoal != null && newGoal > 0) {
                  final user = FirebaseAuth.instance.currentUser;
                  if (user != null) {
                    final box = Hive.box<UserProfile>('user_profiles');
                    final profile = box.get(user.uid);
                    if (profile != null) {
                      profile.dailyStepGoal = newGoal;
                      await box.put(user.uid, profile);
                      setState(() {
                        _userProfile = profile;
                      });
                    }
                  }
                  Navigator.pop(context);
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  // Achievement check and award logic
  Future<void> _checkAndAwardAchievements() async {
    if (_userProfile == null) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    // Gather all activity records
    final records = _activityBox.values.toList();
    final newlyEarned = checkForNewAchievements(_userProfile!, records);
    if (newlyEarned.isEmpty) return;
    final now = DateTime.now();
    final box = Hive.box<UserProfile>('user_profiles');
    final notificationBox = Hive.box<NotificationItem>('notifications');
    for (final id in newlyEarned) {
      _userProfile!.achievements[id] = now;
      // Add notification
      final achievement = allAchievements.firstWhere((a) => a.id == id);
      final notification = NotificationItem(
        id: 'achv_${id}_$now',
        text: 'You earned the badge: ${achievement.name}! 🎉',
        timestamp: now,
        type: NotificationType.achievement,
      );
      await notificationBox.add(notification);
      // Show local notification using NotificationHelper
      await NotificationHelper.showAchievement(achievement.name);
    }
    // Save profile locally and to Firestore
    await box.put(_userProfile!.userId, _userProfile!);
    await FirebaseFirestore.instance.collection('users').doc(_userProfile!.userId).set({
      'achievements': _userProfile!.achievements.map((k, v) => MapEntry(k, v.toIso8601String())),
    }, SetOptions(merge: true));
    if (mounted) setState(() {});
  }

  Future<void> _checkGoalHint() async {
    final prefs = await SharedPreferences.getInstance();
    final hasSeenHint = prefs.getBool('dashboard_goal_hint_seen') ?? false;
    if (!hasSeenHint) {
      setState(() {
        _showGoalHint = true;
      });
    }
  }

  Future<void> _dismissGoalHint() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('dashboard_goal_hint_seen', true);
    setState(() {
      _showGoalHint = false;
    });
  }

  // Restore activity data from Firestore
  Future<void> _restoreDataFromFirestore() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        print('🔄 Restoring data from Firebase...');
        final snapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('activities')
            .get();
        
        int restoredCount = 0;
        for (final doc in snapshot.docs) {
          final data = doc.data();
          final dateKey = doc.id;
          
          // Check if we already have this data locally
          final existingRecord = _activityBox.get(dateKey);
          if (existingRecord == null) {
            // Create new activity record from Firestore data
            final activity = ActivityRecord(
              date: DateTime.parse(data['date']),
              steps: data['steps'] ?? 0,
              manualSteps: data['manualSteps'] ?? 0,
              pedometerSteps: data['pedometerSteps'] ?? 0,
              distance: (data['distance'] ?? 0).toDouble(),
              calories: data['calories'] ?? 0,
            );
            
            // Save to local Hive database
            _activityBox.put(dateKey, activity);
            restoredCount++;
            print('✅ Restored: $dateKey - ${activity.steps} steps');
          }
        }
        
        print('📊 Restored $restoredCount activities from Firebase');
        
        // Sync all existing local data to Firestore (for existing users)
        await _syncAllLocalDataToFirestore();
      }
    } catch (e) {
      print('❌ Error restoring data from Firebase: $e');
    }
  }

  // Sync all existing local data to Firebase
  Future<void> _syncAllLocalDataToFirestore() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final allActivities = _activityBox.values.toList();
        print('🔄 Syncing ${allActivities.length} local activities to Firebase...');
        
        for (final activity in allActivities) {
          final dateKey = _getDateKey(activity.date);
          await _syncActivityToFirestore(dateKey, activity);
        }
        
        print('✅ Successfully synced all local data to Firebase');
      }
    } catch (e) {
      print('❌ Error syncing all local data to Firebase: $e');
    }
  }

  String _getDateKey(DateTime date) {
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }

  // Sync missed pedometer steps when app opens (Google Fit-like functionality)
  Future<void> _syncMissedPedometerSteps() async {
    try {
      print('🔄 Syncing missed pedometer steps...');
      
      // Get current device step count
      final currentSteps = await Pedometer.stepCountStream.first;
      print('📱 Current device step count: ${currentSteps.steps}');
      
      // Check if we need to reset baseline for a new day
      final now = DateTime.now();
      final baselineDate = _baselineDate;
      if (baselineDate == null || 
          baselineDate.year != now.year || 
          baselineDate.month != now.month || 
          baselineDate.day != now.day) {
        print('📅 New day detected, resetting baseline');
        _pedometerBaseline = currentSteps.steps;
        _savePedometerBaseline(currentSteps.steps);
        _saveBaseline(currentSteps.steps);
        print('🎯 Set new day baseline to: ${currentSteps.steps}');
        
        // Check if user was away for multiple days
        if (baselineDate != null) {
          final daysDiff = now.difference(baselineDate).inDays;
          if (daysDiff > 1) {
            print('📅 User was away for $daysDiff days');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('👋 Welcome back! You were away for $daysDiff days'),
                duration: const Duration(seconds: 3),
                backgroundColor: Colors.blue,
              ),
            );
          }
        }
        return; // No need to sync since it's a new day
      }
      
      if (_pedometerBaseline != null) {
        final deviceStepsSinceBaseline = currentSteps.steps - _pedometerBaseline!;
        print('📊 Device shows $deviceStepsSinceBaseline steps since baseline');
        
        if (deviceStepsSinceBaseline > 0) {
          final todayKey = _getTodayKey();
          final todayRecord = _activityBox.get(todayKey);
          final currentPedometerSteps = todayRecord?.pedometerSteps ?? 0;
          
          // Check if device has more steps than we recorded
          if (deviceStepsSinceBaseline > currentPedometerSteps) {
            final missedSteps = deviceStepsSinceBaseline - currentPedometerSteps;
            print('🎯 Found $missedSteps missed steps while app was closed');
            
            // Update the activity record with missed steps
            final activity = todayRecord ?? ActivityRecord(
              date: DateTime.now(),
              steps: 0,
              distance: 0,
              calories: 0,
            );
            
            activity.pedometerSteps = deviceStepsSinceBaseline;
            activity.steps = (activity.manualSteps ?? 0) + deviceStepsSinceBaseline;
            
            // Recalculate distance and calories
            if (_userProfile != null) {
              final strideLength = _userProfile!.height * 0.415 / 100;
              activity.distance = (activity.steps * strideLength) / 1000;
              activity.calories = (activity.steps * _userProfile!.weight * 0.0005).round();
            }
            
            // Sync to both storages
            await _syncToBothStorages(todayKey, activity);
            
            // Update UI
            if (mounted) {
              setState(() {
                _steps = activity.steps;
                _todaySteps = activity.steps;
                _distanceInKm = activity.distance;
                _caloriesBurned = activity.calories;
              });
            }
            
            print('✅ Synced $missedSteps missed steps! New total: ${activity.steps}');
            
            // Show notification to user
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('🎯 Synced $missedSteps steps from while you were away!'),
                duration: const Duration(seconds: 3),
                backgroundColor: Colors.green,
              ),
            );
            
            // Add push notification for step sync
            if (missedSteps > 0) {
              await NotificationHelper.showReminder(
                title: '🔄 Steps Synced!',
                body: 'Synced $missedSteps steps from your device while you were away!',
                id: 777, // Special ID for step sync
              );
              
              // Add to notification history
              final notificationBox = Hive.box<NotificationItem>('notifications');
              final notification = NotificationItem(
                id: 'sync_${DateTime.now().millisecondsSinceEpoch}',
                text: '🔄 Synced $missedSteps steps from your device!',
                timestamp: DateTime.now(),
                type: NotificationType.general,
              );
              await notificationBox.add(notification);
            }
          } else {
            print('✅ No missed steps to sync');
            
            // Check if user was away for multiple days and show welcome back
            final daysAway = DateTime.now().difference(baselineDate).inDays;
            if (daysAway > 1) {
              await NotificationHelper.showReminder(
                title: '👋 Welcome Back!',
                body: 'Great to see you again! You were away for $daysAway days.',
                id: 666, // Special ID for welcome back
              );
              
              // Add to notification history
              final notificationBox = Hive.box<NotificationItem>('notifications');
              final notification = NotificationItem(
                id: 'welcome_${DateTime.now().millisecondsSinceEpoch}',
                text: '👋 Welcome back! You were away for $daysAway days.',
                timestamp: DateTime.now(),
                type: NotificationType.general,
              );
              await notificationBox.add(notification);
            }
                    }
        } else if (deviceStepsSinceBaseline < 0) {
          // Device was reset or restarted, update baseline
          print('🔄 Device step count reset detected, updating baseline');
          _pedometerBaseline = currentSteps.steps;
          _savePedometerBaseline(currentSteps.steps);
          print('🎯 Updated baseline to: ${currentSteps.steps}');
        } else {
          print('📱 No new steps detected since last sync');
          
          // Check if user was away for multiple days and show welcome back
          final daysAway = DateTime.now().difference(baselineDate).inDays;
          if (daysAway > 1) {
            await NotificationHelper.showReminder(
              title: '👋 Welcome Back!',
              body: 'Great to see you again! You were away for $daysAway days.',
              id: 666, // Special ID for welcome back
            );
            
            // Add to notification history
            final notificationBox = Hive.box<NotificationItem>('notifications');
            final notification = NotificationItem(
              id: 'welcome_${DateTime.now().millisecondsSinceEpoch}',
              text: '👋 Welcome back! You were away for $daysAway days.',
              timestamp: DateTime.now(),
              type: NotificationType.general,
            );
            await notificationBox.add(notification);
          }
                }
      } else {
        // No baseline set yet, set it now
        _pedometerBaseline = currentSteps.steps;
        _savePedometerBaseline(currentSteps.steps);
        print('🎯 Set initial baseline to: ${currentSteps.steps}');
      }
    } catch (e) {
      print('❌ Error syncing missed pedometer steps: $e');
    }
  }

  // Schedule daily summary notification
  Future<void> _scheduleDailySummary() async {
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1, 21, 0); // 9 PM tomorrow
    
    await NotificationHelper.scheduleReminder(
      id: 999, // Special ID for daily summary
      title: 'StepWise Daily Summary',
      body: 'Check your daily step progress!',
      dateTime: tomorrow,
      repeat: 'daily',
    );
    print('📅 Scheduled daily summary notification for 9 PM daily');
  }

  Widget _buildScrollHint(Brightness brightness) {
    // Show scroll hint only for first few uses
    return FutureBuilder<SharedPreferences>(
      future: SharedPreferences.getInstance(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        
        final prefs = snapshot.data!;
        final scrollHintShown = prefs.getBool('scroll_hint_shown') ?? false;
        
        if (scrollHintShown) return const SizedBox.shrink();
        
        return Card(
          color: AppColors.getPrimary(brightness).withOpacity(0.1),
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Icon(
                  Icons.swipe,
                  color: AppColors.getPrimary(brightness),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '💡 Swipe left/right to navigate between pages',
                    style: AppTextStyles.body(brightness).copyWith(
                      color: AppColors.getPrimary(brightness),
                      fontSize: 12,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.close,
                    color: AppColors.getPrimary(brightness),
                    size: 16,
                  ),
                  onPressed: () async {
                    await prefs.setBool('scroll_hint_shown', true);
                    if (mounted) setState(() {});
                  },
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPermissionStatus(Brightness brightness) {
    // Check if both permissions are granted
    final activityGranted = _pedometerError == null;
    final notificationGranted = _notificationError == null;
    
    // If both permissions are granted, don't show anything
    if (activityGranted && notificationGranted) {
      return const SizedBox.shrink();
    }
    
    // Show permission issues
    return Column(
      children: [
        // Activity recognition permission status
        if (!activityGranted)
          Card(
            color: Colors.orange.withOpacity(0.1),
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  const Icon(Icons.directions_walk, color: Colors.orange, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _pedometerError ?? 'Activity tracking permission needed',
                      style: AppTextStyles.body(brightness).copyWith(
                        color: Colors.orange,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () async {
                      await _requestPermissions();
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
        
        // Notification permission status
        if (!notificationGranted)
          Card(
            color: Colors.orange.withOpacity(0.1),
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  const Icon(Icons.notifications, color: Colors.orange, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _notificationError ?? 'Notification permission needed',
                      style: AppTextStyles.body(brightness).copyWith(
                        color: Colors.orange,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () async {
                      await _requestPermissions();
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
} 