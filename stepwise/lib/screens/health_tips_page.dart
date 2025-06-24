import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class HealthTip {
  final String title;
  final String summary;
  final String category;
  final IconData icon;

  HealthTip({
    required this.title,
    required this.summary,
    required this.category,
    required this.icon,
  });
}

class HealthTipsPage extends StatefulWidget {
  const HealthTipsPage({super.key});

  @override
  HealthTipsPageState createState() => HealthTipsPageState();
}

class HealthTipsPageState extends State<HealthTipsPage> {
  final List<HealthTip> _healthTips = [
    HealthTip(
        title: 'Stay Hydrated',
        summary: 'Drinking enough water daily is crucial for many reasons: to regulate body temperature, keep joints lubricated, prevent infections, deliver nutrients to cells, and keep organs functioning properly.',
        category: 'Nutrition',
        icon: Icons.water_drop),
    HealthTip(
        title: 'The 20-20-20 Rule',
        summary: 'To prevent eye strain, look away from your screen every 20 minutes and focus on an object 20 feet away for at least 20 seconds.',
        category: 'Wellness',
        icon: Icons.visibility),
    HealthTip(
        title: 'Incorporate Strength Training',
        summary: 'Aim for at least two strength training sessions per week. This can help build muscle mass, improve bone density, and boost your metabolism.',
        category: 'Exercise',
        icon: Icons.fitness_center),
    HealthTip(
        title: 'Eat a Balanced Diet',
        summary: 'Include a variety of fruits, vegetables, lean proteins, and whole grains in your diet. A balanced diet provides the essential nutrients your body needs to function effectively.',
        category: 'Nutrition',
        icon: Icons.restaurant),
    HealthTip(
        title: 'Prioritize Quality Sleep',
        summary: 'Aim for 7-9 hours of quality sleep per night. Good sleep improves brain function, mood, and overall health. Establish a regular sleep schedule and create a restful environment.',
        category: 'Wellness',
        icon: Icons.nights_stay),
    HealthTip(
        title: 'Practice Mindful Stretching',
        summary: 'Incorporate regular stretching into your routine to improve flexibility, reduce muscle tension, and increase blood flow. Even a few minutes a day can make a difference.',
        category: 'Exercise',
        icon: Icons.self_improvement),
  ];

  Map<String, List<HealthTip>> get _categorizedTips {
    final map = <String, List<HealthTip>>{};
    for (var tip in _healthTips) {
      (map[tip.category] ??= []).add(tip);
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final categories = _categorizedTips;
    final categoryKeys = categories.keys.toList();

    return Scaffold(
      backgroundColor: AppColors.getBackground(brightness),
      appBar: AppBar(
        backgroundColor: AppColors.getBackground(brightness),
        elevation: 0,
        title: Text('Health & Wellness Tips', style: AppTextStyles.title(brightness)),
        centerTitle: true,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: categoryKeys.length,
        itemBuilder: (context, index) {
          final category = categoryKeys[index];
          final tips = categories[category]!;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 16.0),
                child: Text(
                  category,
                  style: AppTextStyles.heading(brightness).copyWith(fontSize: 22),
                ),
              ),
              ...tips.map((tip) => _buildTipCard(tip, brightness)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTipCard(HealthTip tip, Brightness brightness) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      color: AppColors.getSecondary(brightness),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColors.getBorder(brightness), width: 0.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(tip.icon, color: AppColors.getPrimary(brightness), size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(tip.title, style: AppTextStyles.bodyBold(brightness)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(tip.summary, style: AppTextStyles.body(brightness)),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.bottomRight,
              child: TextButton(
                onPressed: () {
                  // Navigate to a detail page or show a dialog
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      backgroundColor: AppColors.getBackground(brightness),
                      title: Text(tip.title, style: AppTextStyles.title(brightness)),
                      content: Text(
                        '${tip.summary}\n\n(Full article content would appear here.)',
                        style: AppTextStyles.body(brightness),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: Text('Close', style: TextStyle(color: AppColors.getPrimary(brightness))),
                        ),
                      ],
                    ),
                  );
                },
                child: Text(
                  'Read More',
                  style: AppTextStyles.button(brightness).copyWith(color: AppColors.getPrimary(brightness)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 