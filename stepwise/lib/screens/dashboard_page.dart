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
import 'dart:math';
import 'package:confetti/confetti.dart';

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

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 2));
    _initDependencies();
    _startQuoteRotation();
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
    // Confetti when goal is reached
    final goal = _userProfile?.dailyStepGoal ?? 10000;
    if (_todaySteps >= goal) {
      _confettiController.play();
    }
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

  @override
  void dispose() {
    _stepCountStreamSubscription?.cancel();
    _confettiController.dispose();
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
                  onRefresh: () async {
                    await _initDependencies();
                    setState(() {});
                  },
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Personalized greeting
                        Text(
                          _getGreeting() + ', ${_userProfile!.name}!',
                          style: AppTextStyles.heading(brightness),
                        ),
                        const SizedBox(height: 8),
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
                                  Icon(Icons.local_fire_department, color: Colors.orange, size: 28),
                                  const SizedBox(width: 8),
                                  Text(
                                    '$_activeStreak-day streak!',
                                    style: AppTextStyles.body(brightness).copyWith(fontWeight: FontWeight.w600, color: Colors.orange),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        const SizedBox(height: 16),
                        // Quick actions
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

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 18) return 'Good afternoon';
    return 'Good evening';
  }

  void _logActivity() {
    final dateController = TextEditingController(text: DateTime.now().toIso8601String().substring(0, 10));
    final stepsController = TextEditingController();
    final distanceController = TextEditingController();
    final caloriesController = TextEditingController();
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
                const SizedBox(height: 8),
                TextField(
                  controller: distanceController,
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Distance (km)'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: caloriesController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Calories'),
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
                final distance = double.tryParse(distanceController.text) ?? 0.0;
                final calories = int.tryParse(caloriesController.text) ?? 0;
                if (steps > 0) {
                  final key = '${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}';
                  final activity = ActivityRecord(
                    date: selectedDate,
                    steps: steps,
                    distance: distance,
                    calories: calories,
                  );
                  await _activityBox.put(key, activity);
                  if (key == _getTodayKey()) {
                    setState(() {
                      _steps = steps;
                      _todaySteps = steps - _baselineSteps;
                      _updateCalculations();
                    });
                  }
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
} 