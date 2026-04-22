import 'package:intl/intl.dart';

class DateFormatter {
  /// Основний формат: 22.03.2026
  static String formatFull(DateTime date) {
    return DateFormat('dd.MM.yyyy').format(date);
  }

  /// Формат з часом: 22.03.2026 21:05 (для оновлення курсів)
  static String formatWithTime(DateTime date) {
    return DateFormat('dd.MM.yyyy HH:mm').format(date);
  }

  /// Назва місяця та рік: Березень 2026
  static String formatMonthYear(DateTime date, String locale) {
    String month = DateFormat.MMMM(locale).format(date);
    return '${month[0].toUpperCase()}${month.substring(1)} ${date.year}';
  }

  /// Тільки день: 22
  static String formatDay(DateTime date) {
    return DateFormat('dd').format(date);
  }
}
