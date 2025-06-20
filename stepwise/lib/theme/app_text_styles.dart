import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTextStyles {
  static const TextStyle heading = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: AppColors.primary,
    letterSpacing: 1.2,
  );

  static const TextStyle subheading = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.text,
  );

  static const TextStyle body = TextStyle(
    fontSize: 16,
    color: AppColors.text,
  );

  static const TextStyle button = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: AppColors.buttonText,
    letterSpacing: 1.1,
  );

  static const TextStyle link = TextStyle(
    fontSize: 16,
    color: AppColors.primary,
    decoration: TextDecoration.underline,
  );

  static const TextStyle subtitle = TextStyle(
    fontSize: 14,
    color: AppColors.subtitle,
  );
} 