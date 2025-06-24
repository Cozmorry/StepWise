import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';

class AppTheme {
  static ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    primaryColor: AppColors.getPrimary(Brightness.light),
    scaffoldBackgroundColor: AppColors.getBackground(Brightness.light),
    colorScheme: ColorScheme.light(
      primary: AppColors.getPrimary(Brightness.light),
      secondary: AppColors.getSecondary(Brightness.light),
      surface: AppColors.getBackground(Brightness.light),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.getPrimary(Brightness.light),
      elevation: 0,
      iconTheme: const IconThemeData(color: Colors.white),
      titleTextStyle: AppTextStyles.title(Brightness.light).copyWith(color: Colors.white),
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: AppColors.getNavBar(Brightness.light),
      selectedItemColor: AppColors.getPrimary(Brightness.light),
      unselectedItemColor: AppColors.getSubtitle(Brightness.light),
      selectedLabelStyle: AppTextStyles.navLabel(Brightness.light),
      unselectedLabelStyle: AppTextStyles.navLabel(Brightness.light),
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: AppColors.getBorder(Brightness.light),
          width: 1,
        ),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.getPrimary(Brightness.light),
        foregroundColor: Colors.white,
        textStyle: AppTextStyles.button(Brightness.light),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.getPrimary(Brightness.light),
        textStyle: AppTextStyles.button(Brightness.light),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      fillColor: Colors.white,
      filled: true,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(
          color: AppColors.getBorder(Brightness.light),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(
          color: AppColors.getBorder(Brightness.light),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(
          color: AppColors.getPrimary(Brightness.light),
          width: 2,
        ),
      ),
    ),
  );

  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: AppColors.getPrimary(Brightness.dark),
    scaffoldBackgroundColor: AppColors.getBackground(Brightness.dark),
    colorScheme: ColorScheme.dark(
      primary: AppColors.getPrimary(Brightness.dark),
      secondary: AppColors.getSecondary(Brightness.dark),
      surface: AppColors.getBackground(Brightness.dark),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.getPrimary(Brightness.dark),
      elevation: 0,
      iconTheme: const IconThemeData(color: Colors.white),
      titleTextStyle: AppTextStyles.title(Brightness.dark).copyWith(color: Colors.white),
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: AppColors.getNavBar(Brightness.dark),
      selectedItemColor: AppColors.getPrimary(Brightness.dark),
      unselectedItemColor: AppColors.getSubtitle(Brightness.dark),
      selectedLabelStyle: AppTextStyles.navLabel(Brightness.dark),
      unselectedLabelStyle: AppTextStyles.navLabel(Brightness.dark),
    ),
    cardTheme: CardThemeData(
      color: AppColors.getSecondary(Brightness.dark),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: AppColors.getBorder(Brightness.dark),
          width: 1,
        ),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.getPrimary(Brightness.dark),
        foregroundColor: Colors.white,
        textStyle: AppTextStyles.button(Brightness.dark),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.getPrimary(Brightness.dark),
        textStyle: AppTextStyles.button(Brightness.dark),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      fillColor: AppColors.getSecondary(Brightness.dark),
      filled: true,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(
          color: AppColors.getBorder(Brightness.dark),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(
          color: AppColors.getBorder(Brightness.dark),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(
          color: AppColors.getPrimary(Brightness.dark),
          width: 2,
        ),
      ),
    ),
  );
} 