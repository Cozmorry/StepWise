import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/bottom_nav_bar.dart';
import 'package:pedometer/pedometer.dart';
import 'dart:async';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({Key? key}) : super(key: key);

  @override
  DashboardPageState createState() => DashboardPageState();
}

class DashboardPageState extends State<DashboardPage> {
  int _currentIndex = 0;
  int _todaySteps = 0;
  StreamSubscription<StepCount>? _stepCountStream;

  // Placeholder values
  final String userName = 'User';
  final int stepGoal = 10000;
  final String time = '30 min';
  final String distance = '0.4 km';
  final String streakMsg = 'Great Consistency! You have a 3-day active streak!';

  @override
  void initState() {
    super.initState();
    _requestActivityRecognitionPermission().then((_) => _initPedometer());
  }

  Future<void> _requestActivityRecognitionPermission() async {
    if (await Permission.activityRecognition.isDenied) {
      await Permission.activityRecognition.request();
    }
  }

  void _initPedometer() {
    _stepCountStream = Pedometer.stepCountStream.listen(
      (StepCount event) async {
        final now = DateTime.now();
        final prefs = await SharedPreferences.getInstance();
        final todayKey = 'baselineSteps_${now.year}_${now.month}_${now.day}';
        // If no baseline for today, set it
        if (!prefs.containsKey(todayKey)) {
          await _saveBaselineSteps(event.steps);
        }
        final baseline = prefs.getInt(todayKey) ?? event.steps;
        setState(() {
          _todaySteps = event.steps - baseline;
        });
      },
      onError: (error) {
        // Handle error
      },
      cancelOnError: true,
    );
  }

  @override
  void dispose() {
    _stepCountStream?.cancel();
    super.dispose();
  }

  void _onTabTapped(int index) {
    if (index == _currentIndex) return;
    setState(() {
      _currentIndex = index;
    });
    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, '/dashboard');
        break;
      case 1:
        Navigator.pushReplacementNamed(context, '/activity-log');
        break;
      case 2:
        Navigator.pushReplacementNamed(context, '/health-tips');
        break;
      case 3:
        Navigator.pushReplacementNamed(context, '/profile');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16.0),
          child: Icon(Icons.directions_walk, color: AppColors.primary, size: 32),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.notifications_none, color: AppColors.text),
            onPressed: () => Navigator.pushNamed(context, '/notifications'),
          ),
          IconButton(
            icon: Icon(Icons.group_outlined, color: AppColors.text),
            onPressed: () => Navigator.pushNamed(context, '/leaderboard'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),
            Text('Hey $userName!', style: AppTextStyles.subheading),
            const SizedBox(height: 8),
            Text("Today's Step Count is", style: AppTextStyles.body),
            const SizedBox(height: 16),
            Center(
              child: Text(
                '$_todaySteps',
                style: AppTextStyles.heading.copyWith(fontSize: 48, color: AppColors.text),
              ),
            ),
            const SizedBox(height: 16),
            // Progress bar
            Row(
              children: [
                Expanded(
                  child: Stack(
                    children: [
                      Container(
                        height: 8,
                        decoration: BoxDecoration(
                          color: AppColors.secondary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      FractionallySizedBox(
                        widthFactor: (_todaySteps / stepGoal).clamp(0.0, 1.0),
                        child: Container(
                          height: 8,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
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
                Text('0', style: AppTextStyles.subtitle),
                Text('$stepGoal', style: AppTextStyles.subtitle),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Time', style: AppTextStyles.subtitle),
                    Text(time, style: AppTextStyles.body),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('Distance', style: AppTextStyles.subtitle),
                    Text(distance, style: AppTextStyles.body),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),
            Center(
              child: Text(
                streakMsg,
                style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
      ),
    );
  }

  Future<void> _saveBaselineSteps(int steps) async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now();
    final todayKey = 'baselineSteps_${today.year}_${today.month}_${today.day}';
    await prefs.setInt(todayKey, steps);
  }
} 