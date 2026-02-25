// lib/utils/currency_formatter.dart
class CurrencyFormatter {
  // ДОДАНО: параметр isHeader зі значенням за замовчуванням false
  static String format(double amount, {bool isHeader = false}) {
    if (amount.abs() < 0.005) amount = 0;

    double absAmount = amount.abs();
    String sign = amount < 0 ? "-" : "";

    if (absAmount >= 100000000000) return "${sign}99 999М+";

    // ПЕРЕВІРКА НА МІЛЬЙОНИ
    // ЗМІНЕНО: Якщо це шапка, то поріг 100 млн. Інакше — 1 млн (як і було).
    double millionThreshold = isHeader ? 100000000 : 1000000;

    if (absAmount >= millionThreshold) {
      double millions = absAmount / 1000000;
      double truncated = (millions * 10).floorToDouble() / 10;

      String baseString = truncated.toStringAsFixed(1);
      List<String> mParts = baseString.split('.');

      // Додаємо пробіли, якщо мільйонів >= 1000
      RegExp reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
      String formattedInteger = mParts[0].replaceAllMapped(
        reg,
        (m) => '${m[1]} ',
      );

      return "$sign$formattedInteger,${mParts[1]}М";
    }

    // ФОРМАТУВАННЯ ЗВИЧАЙНИХ ЧИСЕЛ (решта без змін)
    String price = absAmount.toStringAsFixed(2);
    List<String> parts = price.split('.');
    RegExp reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    String formattedInt = parts[0].replaceAllMapped(reg, (m) => '${m[1]} ');

    // Суми понад 100 тис. показуються без копійок
    if (absAmount >= 100000) return "$sign$formattedInt";
    return "$sign$formattedInt,${parts[1]}";
  }

  // Форматування бюджету
  static String formatBudget(double amount) {
    String formatted = format(amount);

    if (formatted.contains(',') && !formatted.contains('М')) {
      return formatted.split(',')[0];
    }

    return formatted;
  }
}
