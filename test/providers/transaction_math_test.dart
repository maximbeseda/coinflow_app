import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Transaction Math Logic Tests', () {
    // Ізольована логіка перерахунку targetAmount з editTransaction
    int calculateFinalTargetAmount({
      required int oldAmount,
      required int newAmount,
      required int? oldTargetAmount,
      required int? explicitNewTargetAmount,
    }) {
      if (explicitNewTargetAmount != null) {
        return explicitNewTargetAmount;
      } else if (oldTargetAmount != null && oldAmount > 0) {
        return (oldTargetAmount * (newAmount / oldAmount)).round();
      } else {
        return newAmount;
      }
    }

    test(
      'Повинен використовувати новий targetAmount, якщо він заданий явно',
      () {
        final result = calculateFinalTargetAmount(
          oldAmount: 1000,
          newAmount: 2000,
          oldTargetAmount: 1200,
          explicitNewTargetAmount: 2500, // Явно задаємо нове значення
        );
        expect(result, 2500);
      },
    );

    test(
      'Повинен пропорційно перерахувати targetAmount, якщо змінено тільки amount',
      () {
        // Уявімо, що ми переказували 1000 UAH і отримали 40 USD (курс 25)
        // Тепер ми вирішили змінити суму списання на 2000 UAH.
        // Додаток має сам здогадатися, що сума зарахування тепер 80 USD.
        final result = calculateFinalTargetAmount(
          oldAmount: 1000,
          newAmount: 2000,
          oldTargetAmount: 40,
          explicitNewTargetAmount: null, // Не задаємо явно
        );
        expect(result, 80);
      },
    );

    test('Повинен правильно округляти дробові пропорції', () {
      // 100 UAH = 3 EUR. Змінюємо на 150 UAH.
      // 3 * (150 / 100) = 4.5. Очікуємо заокруглення до 5.
      final result = calculateFinalTargetAmount(
        oldAmount: 100,
        newAmount: 150,
        oldTargetAmount: 3,
        explicitNewTargetAmount: null,
      );
      expect(result, 5);
    });

    test(
      'Якщо targetAmount ніколи не було, повинен просто повернути newAmount',
      () {
        // Звичайна витрата (UAH -> UAH), де targetAmount не використовується
        final result = calculateFinalTargetAmount(
          oldAmount: 1000,
          newAmount: 1500,
          oldTargetAmount: null,
          explicitNewTargetAmount: null,
        );
        expect(result, 1500); // Повертає ту саму суму
      },
    );

    test('Захист від ділення на нуль: якщо старий amount був 0', () {
      final result = calculateFinalTargetAmount(
        oldAmount: 0,
        newAmount: 500,
        oldTargetAmount: 100,
        explicitNewTargetAmount: null,
      );
      // Згідно з вашою логікою, якщо oldAmount == 0, він просто повертає newAmount
      expect(result, 500);
    });
  });
}
