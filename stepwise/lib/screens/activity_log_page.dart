import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/bottom_nav_bar.dart';

class ActivityLogPage extends StatefulWidget {
  @override
  _ActivityLogPageState createState() => _ActivityLogPageState();
}

class _ActivityLogPageState extends State<ActivityLogPage> {
  int _currentIndex = 1;

  // Placeholder data
  final List<Map<String, String>> dailySteps = [
    {'date': '20/5/2025', 'steps': '6200'},
    {'date': '21/5/2025', 'steps': '7580'},
    {'date': '22/5/2025', 'steps': '1921'},
    {'date': '23/5/2025', 'steps': '10053'},
    {'date': '24/5/2025', 'steps': '4829'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Activity Log', style: AppTextStyles.subheading),
        centerTitle: false,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 8.0),
        child: ListView(
          children: [
            // Date/Steps Table
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text('Date', style: TextStyle(fontWeight: FontWeight.bold)),
                      Text('Steps', style: TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const Divider(),
                  ...dailySteps.map((entry) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(entry['date']!),
                            Text(entry['steps']!),
                          ],
                        ),
                      )),
                ],
              ),
            ),
            const SizedBox(height: 18),
            // Weekly Progress Chart (Placeholder)
            Text('Weekly Progress', style: AppTextStyles.body),
            const SizedBox(height: 8),
            Container(
              height: 140,
              decoration: BoxDecoration(
                color: AppColors.secondary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(child: Text('Weekly Bar Chart Placeholder')),
            ),
            const SizedBox(height: 18),
            // Total Steps, Goal Status, Avg Steps/Day
            Text('Total Steps: 50072', style: AppTextStyles.body),
            Text('Goal Status: Met goal 2 out of 7 days', style: AppTextStyles.body),
            Text('Avg Steps/Day: 6000', style: AppTextStyles.body),
            const SizedBox(height: 18),
            // Monthly Progress Chart (Placeholder)
            Text('Monthly Progress', style: AppTextStyles.body),
            const SizedBox(height: 8),
            Container(
              height: 140,
              decoration: BoxDecoration(
                color: AppColors.secondary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(child: Text('Monthly Bar Chart Placeholder')),
            ),
            const SizedBox(height: 18),
            Text('Total Steps: 109210', style: AppTextStyles.body),
            Text('Avg Steps/Month: 42091', style: AppTextStyles.body),
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
} 