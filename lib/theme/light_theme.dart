import 'package:flutter/material.dart';
import 'app_colors_extension.dart';

final lightTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.light,
  scaffoldBackgroundColor: const Color(0xFFE9EEF5),

  colorScheme: ColorScheme.fromSeed(
    seedColor: Colors.black,
    primary: Colors.black,
    brightness: Brightness.light,
  ),

  // НАШ КОНТРАКТ КОЛЬОРІВ
  extensions: [
    AppColorsExtension(
      bgGradientStart: const Color(0xFFD1D9E6),
      bgGradientEnd: const Color(0xFFE9EEF5),
      cardBg: Colors.white,
      textMain: const Color(0xFF1C1C1E),
      textSecondary: const Color(0xFF636366),
      // ЗМІНЕНО: Яскравий, соковитий зелений
      income: const Color(0xFF1E8E3E),
      // ЗМІНЕНО: Яскравий, чистий червоний
      expense: const Color(0xFFE53935),
      iconBg: Colors.black.withValues(alpha: 0.05),
    ),
  ],

  // Покращуємо діалоги для ефекту "виринання"
  dialogTheme: DialogThemeData(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
    backgroundColor: Colors.white,
    surfaceTintColor: Colors.transparent,
    elevation: 6,
    shadowColor: Colors.black.withValues(alpha: 0.2),
  ),

  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: const Color(0xFFF2F2F7),
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
      borderSide: const BorderSide(color: Colors.blue, width: 2),
    ),
  ),

  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      padding: const EdgeInsets.symmetric(vertical: 14),
      backgroundColor: Colors.black,
      foregroundColor: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
  ),

  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      padding: const EdgeInsets.symmetric(vertical: 14),
      backgroundColor: const Color(0xFFF2F2F7),
      foregroundColor: Colors.black87,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
  ),
);
