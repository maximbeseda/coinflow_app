import 'package:flutter/material.dart';

class AppColorsExtension extends ThemeExtension<AppColorsExtension> {
  final Color bgGradientStart;
  final Color bgGradientEnd;
  final Color cardBg;
  final Color textMain;
  final Color textSecondary;
  final Color income;
  final Color expense;
  final Color iconBg;
  final Color accent;

  const AppColorsExtension({
    required this.bgGradientStart,
    required this.bgGradientEnd,
    required this.cardBg,
    required this.textMain,
    required this.textSecondary,
    required this.income,
    required this.expense,
    required this.iconBg,
    required this.accent,
  });

  @override
  ThemeExtension<AppColorsExtension> copyWith({
    Color? bgGradientStart,
    Color? bgGradientEnd,
    Color? cardBg,
    Color? textMain,
    Color? textSecondary,
    Color? income,
    Color? expense,
    Color? iconBg,
    Color? accent,
  }) {
    return AppColorsExtension(
      bgGradientStart: bgGradientStart ?? this.bgGradientStart,
      bgGradientEnd: bgGradientEnd ?? this.bgGradientEnd,
      cardBg: cardBg ?? this.cardBg,
      textMain: textMain ?? this.textMain,
      textSecondary: textSecondary ?? this.textSecondary,
      income: income ?? this.income,
      expense: expense ?? this.expense,
      iconBg: iconBg ?? this.iconBg,
      accent: accent ?? this.accent,
    );
  }

  @override
  ThemeExtension<AppColorsExtension> lerp(
    covariant ThemeExtension<AppColorsExtension>? other,
    double t,
  ) {
    if (other is! AppColorsExtension) return this;
    return AppColorsExtension(
      bgGradientStart: Color.lerp(bgGradientStart, other.bgGradientStart, t)!,
      bgGradientEnd: Color.lerp(bgGradientEnd, other.bgGradientEnd, t)!,
      cardBg: Color.lerp(cardBg, other.cardBg, t)!,
      textMain: Color.lerp(textMain, other.textMain, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      income: Color.lerp(income, other.income, t)!,
      expense: Color.lerp(expense, other.expense, t)!,
      iconBg: Color.lerp(iconBg, other.iconBg, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
    );
  }
}
