import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class LeaderboardPage extends StatelessWidget {
  LeaderboardPage({Key? key}) : super(key: key);

  // Placeholder leaderboard data
  final List<Map<String, dynamic>> leaderboard = [
    {'name': 'Michael', 'steps': 22050},
    {'name': 'Victoria', 'steps': 21150},
    {'name': 'Christopher', 'steps': 13991},
    {'name': 'Ivy', 'steps': 10001, 'highlight': true},
    {'name': 'Gracie', 'steps': 6895},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Leaderboard', style: AppTextStyles.subheading),
        centerTitle: false,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 8.0),
        child: ListView.separated(
          itemCount: leaderboard.length,
          separatorBuilder: (_, __) => const SizedBox(height: 4),
          itemBuilder: (context, i) {
            final entry = leaderboard[i];
            final highlight = entry['highlight'] == true;
            return Container(
              decoration: BoxDecoration(
                color: highlight ? AppColors.secondary : Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('${i + 1}. ${entry['name']}',
                      style: AppTextStyles.body.copyWith(
                        fontWeight: FontWeight.w600,
                        color: highlight ? AppColors.primary : AppColors.text,
                      )),
                  Text('${entry['steps']}',
                      style: AppTextStyles.body.copyWith(
                        color: highlight ? AppColors.primary : AppColors.text,
                        fontWeight: FontWeight.bold,
                      )),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
} 