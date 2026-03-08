import 'package:flutter/material.dart';
import 'app_colors_extension.dart';

final darkTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  scaffoldBackgroundColor: const Color(0xFF1C1C1E),

  colorScheme: ColorScheme.fromSeed(
    seedColor: Colors.white,
    primary: Colors.white,
    brightness: Brightness.dark,
  ),

  // НАШ КОНТРАКТ КОЛЬОРІВ
  extensions: [
    AppColorsExtension(
      bgGradientStart: const Color(0xFF2C2C2E),
      bgGradientEnd: const Color(0xFF1C1C1E),
      cardBg: const Color(0xFF3A3A3C),
      textMain: Colors.white,
      textSecondary: Colors.white70,
      // ЗМІНЕНО: Ідентичний яскравий зелений зі світлої теми
      income: const Color(0xFF1E8E3E),
      // ЗМІНЕНО: Ідентичний яскравий червоний зі світлої теми
      expense: const Color(0xFFE53935),
      iconBg: Colors.white.withValues(alpha: 0.1),
    ),
  ],

  // Адаптуємо діалоги через контраст кольорів та тіні
  dialogTheme: DialogThemeData(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
    backgroundColor: const Color(0xFF2C2C2E),
    surfaceTintColor: Colors.transparent,
    elevation: 12, // Збільшуємо висоту для кращої тіні
    shadowColor:
        Colors.black, // Чорна тінь додасть глибини на темно-сірому фоні
  ),

  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: const Color(0xFF3A3A3C), // Поля вводу ще світліші
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide.none,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: Colors.blueAccent, width: 2),
    ),
  ),

  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      padding: const EdgeInsets.symmetric(vertical: 14),
      backgroundColor: Colors.white,
      foregroundColor: Colors.black,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
  ),

  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      padding: const EdgeInsets.symmetric(vertical: 14),
      backgroundColor: const Color(0xFF3A3A3C),
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
  ),
);
