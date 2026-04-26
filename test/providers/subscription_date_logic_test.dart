import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Subscription Date Logic Tests', () {
    // Ізольована логіка з processAutoPayments для тестування
    DateTime calculateNextPaymentDate(
      DateTime currentDate,
      String periodicity,
    ) {
      if (periodicity == 'monthly') {
        final int nextMonth = currentDate.month == 12 ? 1 : currentDate.month + 1;
        final int nextYear = currentDate.month == 12
            ? currentDate.year + 1
            : currentDate.year;
        int nextDay = currentDate.day;
        final lastDayOfNextMonth = DateTime(nextYear, nextMonth + 1, 0).day;
        if (nextDay > lastDayOfNextMonth) nextDay = lastDayOfNextMonth;
        return DateTime(nextYear, nextMonth, nextDay);
      } else if (periodicity == 'yearly') {
        return DateTime(
          currentDate.year + 1,
          currentDate.month,
          currentDate.day,
        );
      } else if (periodicity == 'weekly') {
        return currentDate.add(const Duration(days: 7));
      }
      return currentDate;
    }

    test('Щомісячна підписка (перехід на наступний місяць)', () {
      final current = DateTime(2026, 4, 15);
      final next = calculateNextPaymentDate(current, 'monthly');
      expect(next, DateTime(2026, 5, 15));
    });

    test('Щомісячна підписка (перехід з грудня на січень)', () {
      final current = DateTime(2025, 12, 10);
      final next = calculateNextPaymentDate(current, 'monthly');
      expect(next, DateTime(2026, 1, 10));
    });

    test('Щомісячна підписка (коригування останнього дня місяця)', () {
      // 31 січня -> наступний місяць лютий, у якому немає 31-го числа
      final current = DateTime(2026, 1, 31);
      final next = calculateNextPaymentDate(current, 'monthly');
      // Очікуємо 28 лютого (2026 не високосний рік)
      expect(next, DateTime(2026, 2, 28));
    });

    test('Щорічна підписка (збільшення року)', () {
      final current = DateTime(2026, 4, 25);
      final next = calculateNextPaymentDate(current, 'yearly');
      expect(next, DateTime(2027, 4, 25));
    });

    test('Щотижнева підписка (додавання 7 днів)', () {
      final current = DateTime(2026, 4, 25);
      final next = calculateNextPaymentDate(current, 'weekly');
      expect(next, DateTime(2026, 5, 2));
    });
  });
}
