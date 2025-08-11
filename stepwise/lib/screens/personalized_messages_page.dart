import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_profile.dart';
import '../services/personalized_messaging_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class PersonalizedMessagesPage extends StatefulWidget {
  const PersonalizedMessagesPage({super.key});

  @override
  State<PersonalizedMessagesPage> createState() => _PersonalizedMessagesPageState();
}

class _PersonalizedMessagesPageState extends State<PersonalizedMessagesPage> {
  late Box<UserProfile> _profileBox;
  int _currentSteps = 0;
  UserProfile? _userProfile;

  @override
  void initState() {
    super.initState();
    _profileBox = Hive.box<UserProfile>('user_profiles');
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // Load user profile
      _userProfile = _profileBox.get(user.uid);
      if (_userProfile == null) {
        final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (doc.exists) {
          _userProfile = UserProfile.fromMap(doc.data()!);
          await _profileBox.put(user.uid, _userProfile!);
        }
      }

      // Load current steps from today's activity
      final todayKey = _getTodayKey();
      final activityBox = Hive.box('activities');
      final todayRecord = activityBox.get(todayKey);
      if (todayRecord != null) {
        _currentSteps = (todayRecord.manualSteps ?? 0) + (todayRecord.pedometerSteps ?? 0);
      }

      if (mounted) setState(() {});
    }
  }

  String _getTodayKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;

    return Scaffold(
      backgroundColor: AppColors.getBackground(brightness),
      appBar: AppBar(
        backgroundColor: AppColors.getPrimary(brightness),
        elevation: 0,
        title: Text(
          'Personalized Insights',
          style: AppTextStyles.title(brightness).copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _userProfile == null
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadUserData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildProfileSummary(brightness),
                    const SizedBox(height: 24),
                    _buildPersonalizedMessage(brightness),
                    const SizedBox(height: 24),
                    _buildQuickTip(brightness),
                    const SizedBox(height: 24),
                    _buildGoalSuggestion(brightness),
                    const SizedBox(height: 24),
                    _buildBMIBreakdown(brightness),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildProfileSummary(Brightness brightness) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.person, color: AppColors.getPrimary(brightness), size: 24),
                const SizedBox(width: 12),
                Text(
                  'Your Profile Summary',
                  style: AppTextStyles.subtitle(brightness).copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildSummaryRow('BMI', _userProfile!.bmi.toStringAsFixed(1), brightness),
            _buildSummaryRow('Category', _userProfile!.bmiCategory, brightness),
            _buildSummaryRow('Age', '${_userProfile!.age} years', brightness),
            _buildSummaryRow('Gender', _userProfile!.gender, brightness),
            _buildSummaryRow('Current Steps', '$_currentSteps', brightness),
            _buildSummaryRow('Daily Goal', '${_userProfile!.dailyStepGoal}', brightness),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, Brightness brightness) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.body(brightness)),
          Text(
            value,
            style: AppTextStyles.body(brightness).copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.getPrimary(brightness),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalizedMessage(Brightness brightness) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.psychology, color: AppColors.getPrimary(brightness), size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Personalized Message',
                    style: AppTextStyles.subtitle(brightness).copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green.withOpacity(0.3)),
                  ),
                  child: const Text(
                    'Daily',
                    style: TextStyle(
                      color: Colors.green,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            FutureBuilder<String>(
              future: PersonalizedMessagingService.getPersonalizedMessage(
                _userProfile!,
                _currentSteps,
                _userProfile!.dailyStepGoal,
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                if (snapshot.hasError) {
                  return Text(
                    'Unable to load personalized message',
                    style: AppTextStyles.body(brightness).copyWith(
                      height: 1.5,
                      fontSize: 16,
                      color: Colors.red,
                    ),
                  );
                }
                
                return Text(
                  snapshot.data ?? 'No message available',
                  style: AppTextStyles.body(brightness).copyWith(
                    height: 1.5,
                    fontSize: 16,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickTip(Brightness brightness) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.lightbulb, color: Colors.amber, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Quick Tip',
                    style: AppTextStyles.subtitle(brightness).copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.amber.withOpacity(0.3)),
                  ),
                  child: Text(
                    'Daily',
                    style: TextStyle(
                      color: Colors.amber.shade700,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            FutureBuilder<String>(
              future: PersonalizedMessagingService.getQuickTip(_userProfile!),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                if (snapshot.hasError) {
                  return Text(
                    'Unable to load quick tip',
                    style: AppTextStyles.body(brightness).copyWith(
                      height: 1.5,
                      fontSize: 16,
                      color: Colors.red,
                    ),
                  );
                }
                
                return Text(
                  snapshot.data ?? 'No tip available',
                  style: AppTextStyles.body(brightness).copyWith(
                    height: 1.5,
                    fontSize: 16,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGoalSuggestion(Brightness brightness) {
    final suggestion = PersonalizedMessagingService.getGoalSuggestion(_userProfile!);

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.track_changes, color: AppColors.getPrimary(brightness), size: 24),
                const SizedBox(width: 12),
                Text(
                  'Goal Suggestion',
                  style: AppTextStyles.subtitle(brightness).copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              suggestion,
              style: AppTextStyles.body(brightness).copyWith(
                height: 1.5,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBMIBreakdown(Brightness brightness) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.analytics, color: AppColors.getPrimary(brightness), size: 24),
                const SizedBox(width: 12),
                Text(
                  'BMI Breakdown',
                  style: AppTextStyles.subtitle(brightness).copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildBMIRange('Underweight', '< 18.5', Colors.blue, brightness),
            _buildBMIRange('Normal weight', '18.5 - 24.9', Colors.green, brightness),
            _buildBMIRange('Overweight', '25.0 - 29.9', Colors.orange, brightness),
            _buildBMIRange('Obese', '≥ 30.0', Colors.red, brightness),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.getPrimary(brightness).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.getPrimary(brightness).withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: AppColors.getPrimary(brightness),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Your BMI: ${_userProfile!.bmi.toStringAsFixed(1)} (${_userProfile!.bmiCategory})',
                      style: AppTextStyles.body(brightness).copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.getPrimary(brightness),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBMIRange(String category, String range, Color color, Brightness brightness) {
    final isCurrentCategory = category == _userProfile!.bmiCategory;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: isCurrentCategory ? color : Colors.grey.shade300,
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '$category ($range)',
              style: AppTextStyles.body(brightness).copyWith(
                fontWeight: isCurrentCategory ? FontWeight.bold : FontWeight.normal,
                color: isCurrentCategory ? color : null,
              ),
            ),
          ),
          if (isCurrentCategory)
            Icon(Icons.check_circle, color: color, size: 20),
        ],
      ),
    );
  }
}
