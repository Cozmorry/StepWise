import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/bottom_nav_bar.dart';

class HealthTipsPage extends StatefulWidget {
  const HealthTipsPage({Key? key}) : super(key: key);

  @override
  HealthTipsPageState createState() => HealthTipsPageState();
}

class HealthTipsPageState extends State<HealthTipsPage> {
  int _currentIndex = 2;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Health and Tips', style: AppTextStyles.subheading),
        centerTitle: false,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 8.0),
        child: ListView(
          children: [
            const SizedBox(height: 8),
            Text('Tip of the Day', style: AppTextStyles.body),
            const SizedBox(height: 8),
            _tipCard(
              title: 'Why Hydration is Crucial',
              description: 'Water supports every metabolic process. Staying hydrated helps you recover better and feel more energetic... 2 minute read',
            ),
            const SizedBox(height: 24),
            Text('Saved', style: AppTextStyles.body),
            const SizedBox(height: 8),
            _tipCard(
              title: 'Quality Sleep',
              description: 'Quality sleep restores your muscles and boosts your immune system. A consistent sleep routine improves endurance... 1 minute read',
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) {
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
        },
      ),
    );
  }

  Widget _tipCard({required String title, required String description}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.tips_and_updates, color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(title, style: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(description, style: AppTextStyles.subtitle),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: BorderSide(color: AppColors.primary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () {},
              child: const Text('Read more'),
            ),
          ),
        ],
      ),
    );
  }
} 