import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:coin_flow/widgets/common/custom_numpad.dart';
import '../../helpers/test_wrapper.dart';

void main() {
  // Налаштування до запуску всіх тестів у цьому файлі
  setUpAll(() {
    // Підміняємо платформений канал для плагіна вібрації,
    // щоб уникнути MissingPluginException під час тестів
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('vibration'), (
          MethodCall methodCall,
        ) async {
          if (methodCall.method == 'hasVibrator') {
            return false; // Кажемо віджету, що вібрації немає
          }
          return null;
        });
  });

  group('CustomNumpad Tests', () {
    testWidgets('Повинен рендерити всі цифри та оператори', (
      WidgetTester tester,
    ) async {
      // Будуємо віджет
      await tester.pumpWidget(
        makeTestableWidget(
          child: CustomNumpad(onKeyPressed: (_) {}), // Порожній колбек
        ),
      );

      // 1. Перевіряємо наявність всіх цифр (від 0 до 9)
      for (int i = 0; i <= 9; i++) {
        expect(find.text(i.toString()), findsOneWidget);
      }
      expect(find.text('00'), findsOneWidget);

      // 2. Перевіряємо наявність математичних операторів
      expect(find.text('C'), findsOneWidget);
      expect(find.text('%'), findsOneWidget);
      expect(find.text('÷'), findsOneWidget);
      expect(find.text('×'), findsOneWidget);
      expect(find.text('-'), findsOneWidget);
      expect(find.text('+'), findsOneWidget);
      expect(find.text('='), findsOneWidget);

      // 3. Перевіряємо наявність іконки Backspace
      expect(find.byIcon(Icons.backspace_outlined), findsOneWidget);
    });

    testWidgets('Повинен передавати правильне значення при натисканні', (
      WidgetTester tester,
    ) async {
      String? pressedKey;

      // Будуємо віджет і зберігаємо значення, яке передається в onKeyPressed
      await tester.pumpWidget(
        makeTestableWidget(
          child: CustomNumpad(
            onKeyPressed: (key) {
              pressedKey = key;
            },
          ),
        ),
      );

      // Натискаємо кнопку '5'
      await tester.tap(find.text('5'));
      await tester.pump(); // Оновлюємо фрейм
      expect(pressedKey, '5');

      // Натискаємо оператор '+'
      await tester.tap(find.text('+'));
      await tester.pump();
      expect(pressedKey, '+');

      // Натискаємо іконку Backspace
      await tester.tap(find.byIcon(Icons.backspace_outlined));
      await tester.pump();
      expect(pressedKey, '⌫');
    });
  });
}
