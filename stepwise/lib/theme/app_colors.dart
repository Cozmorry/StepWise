import 'package:flutter/material.dart';

class AppColors {
  // Light theme colors
  static const Color _primaryLight = Color(0xFF9B5C8F);
  static const Color _secondaryLight = Color(0xFFE5D6DF);
  static const Color _accentLight = Color(0xFFB388B4);
  static const Color _backgroundLight = Color(0xFFF8F6F8);
  static const Color _buttonLight = Color(0xFF9B5C8F);
  static const Color _buttonTextLight = Colors.white;
  static const Color _textLight = Color(0xFF222222);
  static const Color _subtitleLight = Color(0xFF6D6D6D);
  static const Color _borderLight = Color(0xFFD1BFD6);
  static const Color _navBarLight = Color(0xFFE5D6DF);

  // Dark theme colors
  static const Color _primaryDark = Color(0xFFB388B4);
  static const Color _secondaryDark = Color(0xFF2D1B2D);
  static const Color _accentDark = Color(0xFF9B5C8F);
  static const Color _backgroundDark = Color(0xFF1A1A1A);
  static const Color _buttonDark = Color(0xFFB388B4);
  static const Color _buttonTextDark = Colors.white;
  static const Color _textDark = Colors.white;
  static const Color _subtitleDark = Color(0xFFB0B0B0);
  static const Color _borderDark = Color(0xFF4A4A4A);
  static const Color _navBarDark = Color(0xFF2D1B2D);

  static Color get primary => _primaryLight;
  static Color get secondary => _secondaryLight;
  static Color get accent => _accentLight;
  static Color get background => _backgroundLight;
  static Color get button => _buttonLight;
  static Color get buttonText => _buttonTextLight;
  static Color get text => _textLight;
  static Color get subtitle => _subtitleLight;
  static Color get border => _borderLight;
  static Color get navBar => _navBarLight;

  // Method to get colors based on brightness
  static Color getPrimary(Brightness brightness) => 
      brightness == Brightness.dark ? _primaryDark : _primaryLight;
  
  static Color getSecondary(Brightness brightness) => 
      brightness == Brightness.dark ? _secondaryDark : _secondaryLight;

  static Color getAccent(Brightness brightness) => 
      brightness == Brightness.dark ? _accentDark : _accentLight;
  
  static Color getBackground(Brightness brightness) => 
      brightness == Brightness.dark ? _backgroundDark : _backgroundLight;

  static Color getButton(Brightness brightness) => 
      brightness == Brightness.dark ? _buttonDark : _buttonLight;

  static Color getButtonText(Brightness brightness) => 
      brightness == Brightness.dark ? _buttonTextDark : _buttonTextLight;
  
  static Color getText(Brightness brightness) => 
      brightness == Brightness.dark ? _textDark : _textLight;
  
  static Color getSubtitle(Brightness brightness) => 
      brightness == Brightness.dark ? _subtitleDark : _subtitleLight;
  
  static Color getBorder(Brightness brightness) => 
      brightness == Brightness.dark ? _borderDark : _borderLight;
  
  static Color getNavBar(Brightness brightness) => 
      brightness == Brightness.dark ? _navBarDark : _navBarLight;
} 