import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class WelcomePage extends StatelessWidget {
  final VoidCallback? onFinish;
  const WelcomePage({Key? key, this.onFinish}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Decorative shapes at the bottom
          Positioned(
            left: -80,
            bottom: -60,
            child: Container(
              width: 300,
              height: 180,
              decoration: BoxDecoration(
                color: AppColors.secondary,
                borderRadius: BorderRadius.circular(150),
              ),
            ),
          ),
          Positioned(
            right: -60,
            bottom: -40,
            child: Container(
              width: 220,
              height: 120,
              decoration: BoxDecoration(
                color: AppColors.accent,
                borderRadius: BorderRadius.circular(120),
              ),
            ),
          ),
          // Main content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo
                Icon(Icons.directions_walk, size: 64, color: AppColors.primary),
                const SizedBox(height: 24),
                // App Name
                Text('STEPWISE', style: AppTextStyles.heading),
                const SizedBox(height: 48),
                // Get Started Button
                SizedBox(
                  width: 220,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.buttonText,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: onFinish,
                    child: Text('GET STARTED', style: AppTextStyles.button),
                  ),
                ),
                const SizedBox(height: 16),
                // Login Button
                SizedBox(
                  width: 220,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.secondary,
                      foregroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      Navigator.pushNamed(context, '/login');
                    },
                    child: Text('LOGIN', style: AppTextStyles.button.copyWith(color: AppColors.primary)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 