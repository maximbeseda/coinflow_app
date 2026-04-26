import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // Обов'язково для ProviderScope
import 'package:coin_flow/widgets/common/settings_drawer.dart'; // Вкажіть правильний шлях до файлу
import '../../helpers/test_wrapper.dart';

void main() {
  // Створюємо ключ, щоб програмно відкривати Scaffold у тесті
  final scaffoldKey = GlobalKey<ScaffoldState>();

  // Зручна функція для створення середовища з Drawer та Riverpod
  Widget buildDrawerApp() {
    return ProviderScope(
      // 💡 МАГІЯ RIVERPOD: Огортаємо все в ProviderScope
      child: makeTestableWidget(
        child: Scaffold(
          key: scaffoldKey,
          body: const Center(child: Text('Home Screen')),
          drawer: const SettingsDrawer(),
        ),
      ),
    );
  }

  group('SettingsDrawer Tests', () {
    testWidgets('1. Відкриває Drawer та рендерить всі пункти меню', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildDrawerApp());

      // Програмно відкриваємо Drawer
      scaffoldKey.currentState?.openDrawer();
      await tester.pumpAndSettle();

      // Перевіряємо наявність усіх ключових іконок меню
      expect(find.byIcon(Icons.person_outline), findsOneWidget); // Профіль
      expect(
        find.byIcon(Icons.pie_chart_outline),
        findsOneWidget,
      ); // Статистика
      expect(find.byIcon(Icons.currency_exchange), findsOneWidget); // Курси
      expect(
        find.byIcon(Icons.import_export),
        findsOneWidget,
      ); // Імпорт/Експорт
      expect(find.byIcon(Icons.save_alt_rounded), findsOneWidget); // Бекап
      expect(find.byIcon(Icons.autorenew), findsOneWidget); // Підписки
      expect(find.byIcon(Icons.delete_outline), findsOneWidget); // Кошик
    });

    testWidgets('2. Відкриває BottomSheet бекапу та взаємодіє з полем пароля', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildDrawerApp());

      // Відкриваємо Drawer
      scaffoldKey.currentState?.openDrawer();
      await tester.pumpAndSettle();

      // Натискаємо на пункт "Бекап"
      await tester.tap(find.byIcon(Icons.save_alt_rounded));

      // Чекаємо, поки Drawer закриється (Navigator.pop) і виїде BottomSheet
      await tester.pumpAndSettle();

      // Перевіряємо, чи з'явились кнопки "Експорт" та "Імпорт" з BottomSheet
      expect(find.byIcon(Icons.upload_file), findsOneWidget); // Експорт
      expect(find.byIcon(Icons.download), findsOneWidget); // Імпорт

      // Поле пароля (TextField) спочатку має бути сховане (AnimatedSize)
      expect(find.byType(TextField), findsNothing);

      // Натискаємо на "Експорт", щоб розгорнути поле пароля
      await tester.tap(find.byIcon(Icons.upload_file));
      await tester.pumpAndSettle(); // Чекаємо на анімацію AnimatedSize

      // Перевіряємо, чи з'явилося поле TextField
      final textFieldFinder = find.byType(TextField);
      expect(textFieldFinder, findsOneWidget);

      // Перевіряємо, що пароль за замовчуванням прихований (obscureText = true)
      TextField textField = tester.widget(textFieldFinder);
      expect(textField.obscureText, isTrue);

      // Натискаємо на іконку "ока" (visibility_off), щоб показати пароль
      await tester.tap(find.byIcon(Icons.visibility_off));
      await tester.pumpAndSettle();

      // Перевіряємо, що пароль став видимим
      textField = tester.widget(textFieldFinder);
      expect(textField.obscureText, isFalse);
    });
  });
}
