// Achievements definitions and logic for StepWise
import 'user_profile.dart';
import 'activity_record.dart';

class Achievement {
  final String id;
  final String name;
  final String description;
  final String icon; // FontAwesome icon name or similar
  final bool Function(UserProfile, List<ActivityRecord>) criteria;

  const Achievement({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.criteria,
  });
}

final List<Achievement> allAchievements = [
  Achievement(
    id: 'first_steps',
    name: 'First Steps',
    description: 'Log your first activity.',
    icon: 'fa-shoe-prints',
    criteria: (profile, records) => records.any((r) => r.steps > 0),
  ),
  Achievement(
    id: '10k_day',
    name: '10k Day',
    description: 'Walk 10,000 steps in a single day.',
    icon: 'fa-walking',
    criteria: (profile, records) => records.any((r) => r.steps >= 10000),
  ),
  Achievement(
    id: '100k_total',
    name: '100k Total',
    description: 'Reach 100,000 total steps.',
    icon: 'fa-trophy',
    criteria: (profile, records) => records.fold(0, (sum, r) => sum + r.steps) >= 100000,
  ),
  Achievement(
    id: 'consistency',
    name: 'Consistency',
    description: 'Log activity 7 days in a row.',
    icon: 'fa-calendar-check',
    criteria: (profile, records) {
      final now = DateTime.now();
      for (int i = 0; i < 7; i++) {
        final day = DateTime(now.year, now.month, now.day).subtract(Duration(days: i));
        if (!records.any((r) => r.date.year == day.year && r.date.month == day.month && r.date.day == day.day && r.steps > 0)) {
          return false;
        }
      }
      return true;
    },
  ),
  Achievement(
    id: 'marathoner',
    name: 'Marathoner',
    description: 'Walk a total of 42,195 steps (marathon distance).',
    icon: 'fa-running',
    criteria: (profile, records) => records.fold(0, (sum, r) => sum + r.steps) >= 42195,
  ),
  Achievement(
    id: 'early_bird',
    name: 'Early Bird',
    description: 'Log activity before 8am.',
    icon: 'fa-sun',
    criteria: (profile, records) => records.any((r) => r.date.hour < 8 && r.steps > 0),
  ),
  Achievement(
    id: 'calorie_burner',
    name: 'Calorie Burner',
    description: 'Burn 500 calories in a day.',
    icon: 'fa-fire',
    criteria: (profile, records) => records.any((r) => r.calories >= 500),
  ),
  Achievement(
    id: 'night_owl',
    name: 'Night Owl',
    description: 'Log activity after 10pm.',
    icon: 'fa-moon',
    criteria: (profile, records) => records.any((r) => r.date.hour >= 22 && r.steps > 0),
  ),
  Achievement(
    id: '5k_day',
    name: '5k Day',
    description: 'Walk 5,000 steps in a single day.',
    icon: 'fa-person-walking',
    criteria: (profile, records) => records.any((r) => r.steps >= 5000),
  ),
  Achievement(
    id: '25k_day',
    name: '25k Day',
    description: 'Walk 25,000 steps in a single day.',
    icon: 'fa-person-hiking',
    criteria: (profile, records) => records.any((r) => r.steps >= 25000),
  ),
  Achievement(
    id: '250k_total',
    name: 'Quarter Million',
    description: 'Reach 250,000 total steps.',
    icon: 'fa-medal',
    criteria: (profile, records) => records.fold(0, (sum, r) => sum + r.steps) >= 250000,
  ),
  Achievement(
    id: '1m_total',
    name: 'Millionaire Walker',
    description: 'Reach 1,000,000 total steps.',
    icon: 'fa-crown',
    criteria: (profile, records) => records.fold(0, (sum, r) => sum + r.steps) >= 1000000,
  ),
  Achievement(
    id: 'streak_30',
    name: '30-Day Streak',
    description: 'Log activity 30 days in a row.',
    icon: 'fa-fire-flame-curved',
    criteria: (profile, records) {
      final now = DateTime.now();
      for (int i = 0; i < 30; i++) {
        final day = DateTime(now.year, now.month, now.day).subtract(Duration(days: i));
        if (!records.any((r) => r.date.year == day.year && r.date.month == day.month && r.date.day == day.day && r.steps > 0)) {
          return false;
        }
      }
      return true;
    },
  ),
  Achievement(
    id: 'distance_100',
    name: 'Century Mover',
    description: 'Walk 100 km total.',
    icon: 'fa-route',
    criteria: (profile, records) => records.fold(0.0, (sum, r) => sum + r.distance) >= 100.0,
  ),
  Achievement(
    id: 'calorie_10k',
    name: '10,000 Calories',
    description: 'Burn 10,000 total calories.',
    icon: 'fa-burn',
    criteria: (profile, records) => records.fold(0, (sum, r) => sum + r.calories) >= 10000,
  ),
  Achievement(
    id: 'weekend_warrior',
    name: 'Weekend Warrior',
    description: 'Log activity on both Saturday and Sunday in the same week.',
    icon: 'fa-shield-halved',
    criteria: (profile, records) {
      final now = DateTime.now();
      final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
      final saturday = startOfWeek.add(const Duration(days: 5));
      final sunday = startOfWeek.add(const Duration(days: 6));
      final hasSat = records.any((r) => r.date.year == saturday.year && r.date.month == saturday.month && r.date.day == saturday.day && r.steps > 0);
      final hasSun = records.any((r) => r.date.year == sunday.year && r.date.month == sunday.month && r.date.day == sunday.day && r.steps > 0);
      return hasSat && hasSun;
    },
  ),
  Achievement(
    id: 'new_year',
    name: 'New Year, New You',
    description: 'Log activity on January 1st.',
    icon: 'fa-champagne-glasses',
    criteria: (profile, records) => records.any((r) => r.date.month == 1 && r.date.day == 1 && r.steps > 0),
  ),
];

/// Checks and returns a list of newly earned achievement IDs
List<String> checkForNewAchievements(UserProfile profile, List<ActivityRecord> records) {
  final earned = profile.achievements.keys.toSet();
  final newlyEarned = <String>[];
  for (final achievement in allAchievements) {
    if (!earned.contains(achievement.id) && achievement.criteria(profile, records)) {
      newlyEarned.add(achievement.id);
    }
  }
  return newlyEarned;
} 