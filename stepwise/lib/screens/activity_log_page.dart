import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:stepwise/models/activity_record.dart';
import 'package:stepwise/models/user_profile.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ActivityLogPage extends StatefulWidget {
  const ActivityLogPage({super.key});

  @override
  ActivityLogPageState createState() => ActivityLogPageState();
}

class ActivityLogPageState extends State<ActivityLogPage> {
  late final Box<ActivityRecord> _activityBox;
  late final Box<UserProfile> _userProfileBox;
  UserProfile? _userProfile;
  late final ValueNotifier<DateTime> _selectedWeek;
  bool _showHint = false;

  @override
  void initState() {
    super.initState();
    _activityBox = Hive.box<ActivityRecord>('activity_log');
    _userProfileBox = Hive.box<UserProfile>('user_profiles');
    _loadUserProfile();
    _selectedWeek = ValueNotifier(DateTime.now());
    _checkFirstTime();
  }

  void _loadUserProfile() {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      _userProfile = _userProfileBox.get(userId);
    }
  }

  void _changeWeek(int weeks) {
    _selectedWeek.value = _selectedWeek.value.add(Duration(days: weeks * 7));
  }

  @override
  void dispose() {
    _selectedWeek.dispose();
    super.dispose();
  }

  Future<void> _checkFirstTime() async {
    final prefs = await SharedPreferences.getInstance();
    final hasSeenHint = prefs.getBool('activity_log_hint_seen') ?? false;
    if (!hasSeenHint) {
      setState(() {
        _showHint = true;
      });
    }
  }

  Future<void> _dismissHint() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('activity_log_hint_seen', true);
    setState(() {
      _showHint = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return Scaffold(
      backgroundColor: AppColors.getBackground(brightness),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Activity Log', style: AppTextStyles.title(brightness)),
        centerTitle: true,
      ),
      body: ValueListenableBuilder<DateTime>(
        valueListenable: _selectedWeek,
        builder: (context, selectedDate, _) {
          return ValueListenableBuilder<Box<ActivityRecord>>(
            valueListenable: _activityBox.listenable(),
            builder: (context, box, _) {
              final records = _getRecordsForWeek(selectedDate, box);
              final stats = _calculateWeeklyStats(records);
              return SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      if (_showHint) _buildHintBanner(brightness),
                      _buildWeekSelector(selectedDate, brightness),
                      const SizedBox(height: 20),
                      records.isEmpty
                          ? _buildEmptyState(brightness)
                          : _buildActivityContent(records, stats, brightness),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
  
  Widget _buildEmptyState(Brightness brightness) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.insights_rounded, size: 80, color: AppColors.getSecondary(brightness)),
          const SizedBox(height: 20),
          Text(
            'No activity recorded for this week.',
            style: AppTextStyles.body(brightness),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Keep moving to see your progress here!',
            style: AppTextStyles.subtitle(brightness),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildActivityContent(List<ActivityRecord> records, Map<String, dynamic> stats, Brightness brightness) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("This Week's Summary", style: AppTextStyles.heading(brightness)),
        const SizedBox(height: 16),
        SizedBox(
          height: 200,
          child: _buildWeeklyChart(records, brightness),
        ),
        const SizedBox(height: 24),
        _buildStatsGrid(stats, brightness),
        const SizedBox(height: 24),
        Text("Daily Breakdown", style: AppTextStyles.heading(brightness)),
        const SizedBox(height: 16),
        _buildDailyList(records, brightness),
      ],
    );
  }

  Widget _buildWeekSelector(DateTime selectedDate, Brightness brightness) {
    final startOfWeek = selectedDate.subtract(Duration(days: selectedDate.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));
    final formatter = DateFormat('MMM d');

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          icon: Icon(Icons.chevron_left, color: AppColors.getText(brightness)),
          onPressed: () => _changeWeek(-1),
        ),
        Text(
          '${formatter.format(startOfWeek)} - ${formatter.format(endOfWeek)}',
          style: AppTextStyles.subheading(brightness),
        ),
        IconButton(
          icon: Icon(Icons.chevron_right, color: AppColors.getText(brightness)),
          onPressed: () => _changeWeek(1),
        ),
      ],
    );
  }

  List<ActivityRecord> _getRecordsForWeek(DateTime date, Box<ActivityRecord> box) {
    final startOfWeek = date.subtract(Duration(days: date.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 7));
    
    return box.values.where((record) {
      final recordDate = record.date;
      return recordDate.isAfter(startOfWeek.subtract(const Duration(days: 1))) && recordDate.isBefore(endOfWeek);
    }).toList();
  }

  Map<String, dynamic> _calculateWeeklyStats(List<ActivityRecord> records) {
    if (records.isEmpty) {
      return {
        'totalSteps': 0,
        'avgSteps': 0,
        'goalMetDays': 0,
        'highestSteps': 0,
      };
    }
    final totalSteps = records.fold<int>(0, (sum, item) => sum + item.steps);
    final goalMetDays = records.where((r) => r.steps >= (_userProfile?.dailyStepGoal ?? 10000)).length;
    return {
      'totalSteps': totalSteps,
      'avgSteps': (totalSteps / records.length).round(),
      'goalMetDays': goalMetDays,
      'highestSteps': records.map((r) => r.steps).reduce((a, b) => a > b ? a : b),
    };
  }

  Widget _buildWeeklyChart(List<ActivityRecord> records, Brightness brightness) {
    final primaryColor = AppColors.getPrimary(brightness);
    final secondaryColor = AppColors.getSecondary(brightness);

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: ((records.map((r) => r.steps).reduce((a, b) => a > b ? a : b) * 1.2).toDouble()),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              return BarTooltipItem(
                '${rod.toY.round()}\n',
                AppTextStyles.bodyBold(brightness).copyWith(color: primaryColor),
                children: [
                  TextSpan(text: 'steps', style: AppTextStyles.body(brightness)),
                ],
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final style = AppTextStyles.body(brightness);
                Widget text;
                switch (value.toInt()) {
                  case 0: text = Text('Mon', style: style); break;
                  case 1: text = Text('Tue', style: style); break;
                  case 2: text = Text('Wed', style: style); break;
                  case 3: text = Text('Thu', style: style); break;
                  case 4: text = Text('Fri', style: style); break;
                  case 5: text = Text('Sat', style: style); break;
                  case 6: text = Text('Sun', style: style); break;
                  default: text = Text('', style: style); break;
                }
                return SideTitleWidget(space: 4.0, meta: meta, child: text);
              },
              reservedSize: 28,
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        gridData: const FlGridData(show: false),
        barGroups: List.generate(7, (index) {
          final day = index + 1;
          final dailySteps = records.where((r) => r.date.weekday == day).fold<int>(0, (sum, item) => sum + item.steps);
          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: dailySteps.toDouble(),
                color: primaryColor,
                width: 16,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildStatsGrid(Map<String, dynamic> stats, Brightness brightness) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildStatCard('Total Steps', NumberFormat.compact().format(stats['totalSteps']), FontAwesomeIcons.shoePrints, brightness)),
            const SizedBox(width: 16),
            Expanded(child: _buildStatCard('Avg Daily Steps', NumberFormat.compact().format(stats['avgSteps']), Icons.timeline, brightness)),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildStatCard('Goals Met', '${stats['goalMetDays']} days', Icons.check_circle_outline, brightness)),
            const SizedBox(width: 16),
            Expanded(child: _buildStatCard('Busiest Day', NumberFormat.compact().format(stats['highestSteps']), Icons.star_border, brightness)),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Brightness brightness) {
    return Card(
      color: AppColors.getSecondary(brightness),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            icon == FontAwesomeIcons.shoePrints
                ? Transform.rotate(
                    angle: -1.5708, // -90 degrees in radians
                    child: FaIcon(FontAwesomeIcons.shoePrints, size: 28, color: AppColors.getPrimary(brightness)),
                  )
                : Icon(icon, size: 28, color: AppColors.getPrimary(brightness)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(title, style: AppTextStyles.subtitle(brightness)),
                  Text(value, style: AppTextStyles.title(brightness)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDailyList(List<ActivityRecord> records, Brightness brightness) {
    final goal = _userProfile?.dailyStepGoal ?? 10000;
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: records.length,
      itemBuilder: (context, index) {
        final record = records[index];
        final progress = (record.steps / goal).clamp(0.0, 1.0);
        return Card(
          color: AppColors.getSecondary(brightness),
          elevation: 0,
          margin: const EdgeInsets.symmetric(vertical: 6),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            leading: Text(
              DateFormat('EEE').format(record.date),
              style: AppTextStyles.bodyBold(brightness),
            ),
            title: Text(
              '${record.steps} steps',
              style: AppTextStyles.body(brightness),
            ),
            subtitle: Text(
              '${record.distance.toStringAsFixed(2)} km · ${record.calories} kcal',
              style: AppTextStyles.subtitle(brightness),
            ),
            trailing: SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(
                value: progress,
                strokeWidth: 4,
                backgroundColor: AppColors.getBackground(brightness),
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.getPrimary(brightness)),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHintBanner(Brightness brightness) {
    return Card(
      color: AppColors.getSecondary(brightness),
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(
              Icons.insights_rounded,
              color: Colors.blue,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '📊 Track your progress!',
                    style: AppTextStyles.subtitle(brightness).copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'View your weekly activity summary and daily breakdown',
                    style: AppTextStyles.body(brightness),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(Icons.close, color: Colors.grey[600]),
              onPressed: _dismissHint,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      ),
    );
  }
} 