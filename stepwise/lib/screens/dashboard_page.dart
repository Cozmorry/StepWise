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
  double _distanceInKm = 0.0;
  int _caloriesBurned = 0;
  int _activeStreak = 0;

  @override
  void initState() {
    super.initState();
    _initDependencies();
  }

  Future<void> _initDependencies() async {
    _activityBox = Hive.box<ActivityRecord>('activity_log');
    await _loadUserProfile();
    await _loadBaseline();
    await _initPedometer();
    await _loadTodayStepCount();
    _calculateActiveStreak();
  }

  Future<void> _loadUserProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final box = Hive.box<UserProfile>('user_profiles');
      final userProfile = box.get(user.uid);
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
  }

  Future<void> _saveBaseline(int steps) async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    await prefs.setInt('baseline_steps', steps);
    await prefs.setString('baseline_date', now.toIso8601String());
    _baselineSteps = steps;
    _baselineDate = now;
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
    if (await Permission.activityRecognition.request().isGranted) {
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
    } else {
      if (mounted) {
        setState(() {
          _pedometerError = "Permission Denied. Please enable activity tracking in settings.";
        });
      }
    }
  }

  Future<void> _loadTodayStepCount() async {
    final todayKey = _getTodayKey();
    final todayRecord = _activityBox.get(todayKey);
    if (todayRecord != null) {
      if (mounted) {
        setState(() {
          _steps = todayRecord.steps;
          _todaySteps = (_steps - _baselineSteps).clamp(0, 1000000);
          _updateCalculations();
        });
      }
    }
  }

  void _onStepCount(StepCount event) {
    if (!mounted) return;
    _checkAndUpdateBaseline(event.steps);
    setState(() {
      _steps = event.steps;
      _todaySteps = (_steps - _baselineSteps).clamp(0, 1000000);
      _updateCalculations();
    });
    _saveStepCount(_todaySteps);
    // Auto-update daily summary notification with real values
    NotificationHelper.scheduleDailySummary(hour: 21, minute: 0, steps: _todaySteps, distanceKm: _distanceInKm);
  }

  void _onStepCountError(error) {
    if (!mounted) return;
    setState(() {
      _pedometerError = 'Pedometer error: $error';
      _isPedometerActive = false;
    });
  }

  void _updateCalculations() {
    if (_userProfile == null) return;
    final strideLength = _userProfile!.height * 0.415 / 100; // in meters
    _distanceInKm = (_todaySteps * strideLength) / 1000;
    const met = 3.5; // MET for walking
    _caloriesBurned = ((met * 3.5 * _userProfile!.weight) / 200 * (_todaySteps / 2000 * 60) / 100).round();
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
  }

  @override
  void dispose() {
    _stepCountStreamSubscription?.cancel();
    super.dispose();
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
          child: Icon(Icons.directions_walk, color: AppColors.getPrimary(brightness), size: 32),
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
              await NotificationHelper.scheduleDailySummary(hour: DateTime.now().hour, minute: DateTime.now().minute, steps: _todaySteps, distanceKm: _distanceInKm);
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
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Welcome back, ${_userProfile!.name}!', style: AppTextStyles.heading(brightness)),
                    const SizedBox(height: 24),
                    Center(
                      child: SizedBox(
                        width: 200,
                        height: 200,
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
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Stack(
                            children: [
                              Container(
                                height: 8,
                                decoration: BoxDecoration(
                                  color: AppColors.getSecondary(brightness),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              FractionallySizedBox(
                                widthFactor: progress,
                                child: Container(
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: AppColors.getPrimary(brightness),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('0', style: AppTextStyles.subtitle(brightness)),
                        Text('$goal', style: AppTextStyles.subtitle(brightness)),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildStatCard('Calories', '${_caloriesBurned.toStringAsFixed(0)} kcal', Icons.local_fire_department, brightness),
                        _buildStatCard('Distance', '${_distanceInKm.toStringAsFixed(2)} km', Icons.map_outlined, brightness),
                      ],
                    ),
                    const SizedBox(height: 24),
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
                    if (_activeStreak > 1)
                      Center(
                        child: Text(
                          'Great Consistency! You have a $_activeStreak-day active streak!',
                          style: AppTextStyles.body(brightness).copyWith(fontWeight: FontWeight.w600),
                          textAlign: TextAlign.center,
                        ),
                      ),
                  ],
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
              Icon(icon, color: AppColors.getPrimary(brightness), size: 28),
              const SizedBox(height: 8),
              Text(title, style: AppTextStyles.subtitle(brightness)),
              Text(value, style: AppTextStyles.title(brightness)),
            ],
          ),
        ),
      ),
    );
  }
} 