// lib/utils/currency_formatter.dart
class CurrencyFormatter {
  // Швидкий метод для розділення тисяч
  static String _addSpaces(String integerPart) {
    if (integerPart.length <= 3) return integerPart;

    final buffer = StringBuffer();
    int count = 0;

    for (int i = integerPart.length - 1; i >= 0; i--) {
      if (count == 3) {
        buffer.write(' ');
        count = 0;
      }
      buffer.write(integerPart[i]);
      count++;
    }

    return buffer.toString().split('').reversed.join();
  }

  static String format(int amount, {bool isHeader = false}) {
    if (amount == 0) return '0';

    // 👇 ТЕПЕР МАТЕМАТИКА ПРАВИЛЬНА (Беремо копійки з бази)
    int absCents = amount.abs();
    String sign = amount < 0 ? '-' : '';

    // Понад 100 мільярдів
    if (absCents >= 10000000000000) return '${sign}99 999М+';

    // Поріг для мільйонів (у копійках)
    int millionThresholdCents = isHeader ? 10000000000 : 100000000;

    if (absCents >= millionThresholdCents) {
      double millions = (absCents / 100.0) / 1000000.0;
      int integerPart = millions.truncate();
      int fractionalPart = ((millions - integerPart) * 10).truncate();

      String formattedInteger = _addSpaces(integerPart.toString());
      return '$sign$formattedInteger,$fractionalPartМ';
    }

    // ЗВИЧАЙНІ СУМИ: Беремо цілу та дробову частину математично!
    int iPart = absCents ~/ 100; // Це цілі гривні/долари
    int fPart = absCents % 100; // Це залишок (копійки/центи)

    String formattedInt = _addSpaces(iPart.toString());

    // Якщо сума >= 100 000 (тобто 10 000 000 копійок), показуємо без копійок
    if (absCents >= 10000000) return '$sign$formattedInt';

    String fString = fPart.toString().padLeft(2, '0');
    return '$sign$formattedInt,$fString';
  }

  static String formatBudget(int amount) {
    String formatted = format(amount);
    if (formatted.contains(',') && !formatted.contains('М')) {
      return formatted.split(',')[0];
    }
    return formatted;
  }
}
