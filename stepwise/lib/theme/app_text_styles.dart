import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTextStyles {
  static TextStyle heading(Brightness brightness) => TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: AppColors.getPrimary(brightness),
    letterSpacing: 1.2,
  );

  static TextStyle subheading(Brightness brightness) => TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.getText(brightness),
  );

  static TextStyle body(Brightness brightness) => TextStyle(
    fontSize: 16,
    color: AppColors.getText(brightness),
  );

  static TextStyle bodyBold(Brightness brightness) => TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: AppColors.getText(brightness),
  );

  static TextStyle button(Brightness brightness) => TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: AppColors.buttonText,
    letterSpacing: 1.1,
  );

  static TextStyle link(Brightness brightness) => TextStyle(
    fontSize: 16,
    color: AppColors.getPrimary(brightness),
    decoration: TextDecoration.underline,
  );

  static TextStyle subtitle(Brightness brightness) => TextStyle(
    fontSize: 14,
    color: AppColors.getSubtitle(brightness),
  );

  static TextStyle caption(Brightness brightness) => TextStyle(
    fontSize: 12,
    color: AppColors.getSubtitle(brightness),
  );

  static TextStyle title(Brightness brightness) => TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: AppColors.getText(brightness),
    letterSpacing: 0.5,
  );

  static TextStyle cardTitle(Brightness brightness) => TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.getText(brightness),
  );

  static TextStyle navLabel(Brightness brightness) => TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.getPrimary(brightness),
  );
} 