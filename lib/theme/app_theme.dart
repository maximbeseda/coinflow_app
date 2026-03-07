import 'package:flutter/material.dart';
import 'light_theme.dart';
import 'dark_theme.dart';

class AppTheme {
  // МАПА ВСІХ ДОСТУПНИХ ТЕМ
  // Ключ — це ID теми (для бази), значення — це ключ перекладу (для UI)
  static Map<String, String> get allThemes => {
    'light': 'theme_light',
    'dark': 'theme_dark',
    // 'gold': 'theme_gold', // Для нової теми просто додай рядок тут
  };

  static ThemeData getTheme(String themeId) {
    switch (themeId) {
      case 'dark':
        return darkTheme;
      case 'light':
      default:
        return lightTheme;
    }
  }
}
