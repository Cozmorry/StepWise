import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../models/user_profile.dart';
import '../models/achievements.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BadgesPage extends StatefulWidget {
  const BadgesPage({super.key});

  @override
  State<BadgesPage> createState() => _BadgesPageState();
}

class _BadgesPageState extends State<BadgesPage> {
  bool _showHint = false;

  @override
  void initState() {
    super.initState();
    _checkFirstTime();
  }

  Future<void> _checkFirstTime() async {
    final prefs = await SharedPreferences.getInstance();
    final hasSeenHint = prefs.getBool('badges_hint_seen') ?? false;
    if (!hasSeenHint) {
      setState(() {
        _showHint = true;
      });
    }
  }

  Future<void> _dismissHint() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('badges_hint_seen', true);
    setState(() {
      _showHint = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final user = FirebaseAuth.instance.currentUser;
    final box = Hive.box<UserProfile>('user_profiles');
    final userProfile = user != null ? box.get(user.uid) : null;
    final earned = userProfile?.achievements ?? {};
    return Scaffold(
      backgroundColor: AppColors.getBackground(brightness),
      appBar: AppBar(
        backgroundColor: AppColors.getPrimary(brightness),
        elevation: 0,
        title: Text('Badges', style: AppTextStyles.title(brightness).copyWith(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            if (_showHint) _buildHintBanner(brightness),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 20,
                mainAxisSpacing: 20,
                children: allAchievements.map((achievement) {
                  final isEarned = earned.containsKey(achievement.id);
                  final date = isEarned ? earned[achievement.id] : null;
                  return Card(
                    color: isEarned ? AppColors.getSecondary(brightness) : AppColors.getBackground(brightness),
                    elevation: isEarned ? 4 : 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          FaIcon(
                            _getIconData(achievement.icon),
                            size: 40,
                            color: isEarned ? AppColors.getPrimary(brightness) : Colors.grey,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            achievement.name,
                            style: AppTextStyles.subtitle(brightness).copyWith(
                              color: isEarned ? AppColors.getText(brightness) : Colors.grey,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            achievement.description,
                            style: AppTextStyles.body(brightness).copyWith(
                              color: isEarned ? AppColors.getText(brightness) : Colors.grey,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          if (isEarned && date != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              'Earned: ${DateFormat.yMMMd().format(date)}',
                              style: AppTextStyles.body(brightness).copyWith(color: AppColors.getPrimary(brightness)),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'fa-shoe-prints':
        return FontAwesomeIcons.shoePrints;
      case 'fa-walking':
      case 'fa-person-walking':
        return FontAwesomeIcons.personWalking;
      case 'fa-trophy':
        return FontAwesomeIcons.trophy;
      case 'fa-calendar-check':
        return FontAwesomeIcons.calendarCheck;
      case 'fa-running':
      case 'fa-person-running':
        return FontAwesomeIcons.personRunning;
      case 'fa-sun':
        return FontAwesomeIcons.solidSun;
      case 'fa-fire':
        return FontAwesomeIcons.fire;
      case 'fa-moon':
        return FontAwesomeIcons.moon;
      case 'fa-person-hiking':
        return FontAwesomeIcons.hiking;
      case 'fa-medal':
        return FontAwesomeIcons.medal;
      case 'fa-crown':
        return FontAwesomeIcons.crown;
      case 'fa-fire-flame-curved':
        return FontAwesomeIcons.fireFlameCurved;
      case 'fa-route':
        return FontAwesomeIcons.route;
      case 'fa-burn':
        return FontAwesomeIcons.fire;
      case 'fa-shield-halved':
        return FontAwesomeIcons.shieldHalved;
      case 'fa-champagne-glasses':
        return FontAwesomeIcons.champagneGlasses;
      default:
        return FontAwesomeIcons.award;
    }
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
            Icon(
              Icons.emoji_events,
              color: Colors.amber,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '🏆 Earn achievements!',
                    style: AppTextStyles.subtitle(brightness).copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Complete goals and milestones to unlock badges',
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