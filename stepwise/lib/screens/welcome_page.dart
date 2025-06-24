import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class WelcomePage extends StatelessWidget {
  final VoidCallback? onFinish;
  const WelcomePage({super.key, this.onFinish});

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.getPrimary(brightness).withOpacity(0.1), AppColors.getSecondary(brightness).withOpacity(0.2)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            // Decorative shapes at the bottom
            Positioned(
              left: -80,
              bottom: -60,
              child: Container(
                width: 300,
                height: 180,
                decoration: BoxDecoration(
                  color: AppColors.getSecondary(brightness),
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
                  color: AppColors.getPrimary(brightness),
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
                  // TODO: Replace with a custom footsteps icon if available
                  Icon(Icons.directions_walk, size: 72, color: AppColors.getPrimary(brightness)),
                  const SizedBox(height: 32),
                  // App Name
                  Text('STEPWISE', style: AppTextStyles.heading(brightness).copyWith(fontSize: 38, letterSpacing: 2)),
                  const SizedBox(height: 16),
                  Text('Track your steps. Improve your health.', style: AppTextStyles.subtitle(brightness).copyWith(fontSize: 18)),
                  const SizedBox(height: 56),
                  // Get Started Button
                  SizedBox(
                    width: 220,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.getPrimary(brightness),
                        foregroundColor: AppColors.buttonText,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 4,
                        shadowColor: AppColors.getPrimary(brightness).withOpacity(0.2),
                      ),
                      onPressed: onFinish,
                      child: Text('GET STARTED', style: AppTextStyles.button(brightness).copyWith(fontSize: 18)),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Login Button
                  SizedBox(
                    width: 220,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.getPrimary(brightness),
                        side: BorderSide(color: AppColors.getPrimary(brightness), width: 2),
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: () {
                        Navigator.pushNamed(context, '/login');
                      },
                      child: Text('LOGIN', style: AppTextStyles.button(brightness).copyWith(fontSize: 18, color: AppColors.getPrimary(brightness))),
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
} 