import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:coin_flow/widgets/dialogs/due_subscription_dialog.dart';
import 'package:coin_flow/providers/all_providers.dart';
// Додаємо прямий імпорт вашого файлу налаштувань, щоб взяти звідти SettingsState
import 'package:coin_flow/theme/app_colors_extension.dart';
import 'package:coin_flow/database/app_database.dart';

// 👇 МАГІЯ: Створюємо "фейковий" провайдер, який блокує інтернет-запити
class TestSettingsNotifier extends SettingsNotifier {
  @override
  SettingsState build() {
    // Повертаємо стан, де курси "щойно оновлені" (DateTime.now)
    // Це зупинить _checkRatesUpdate від створення 5-секундного таймера!
    return SettingsState(
      baseCurrency: 'USD',
      selectedCurrencies: ['USD', 'UAH'],
      exchangeRates: {'USD': 1.0, 'UAH': 40.0},
      historicalCache: {},
      lastRatesUpdate: DateTime.now(),
    );
  }
}

void main() {
  setUpAll(() async {
    HttpOverrides.global = null;
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
    await initializeDateFormatting('uk', null);
    await initializeDateFormatting('en', null);
    EasyLocalization.logger.enableBuildModes = [];
  });

  testWidgets(
    'DueSubscriptionDialog правильно відмальовує елементи без таймерів',
    (WidgetTester tester) async {
      final prefs = await SharedPreferences.getInstance();

      final testSubscription = Subscription(
        id: 'test_sub_1',
        name: 'Netflix Premium',
        amount: 1500,
        currency: 'USD',
        accountId: 'acc_1',
        categoryId: 'cat_1',
        nextPaymentDate: DateTime(2026, 5, 10),
        periodicity: 'monthly',
        isAutoPay: false,
      );

      final testTheme = ThemeData().copyWith(
        extensions: [
          AppColorsExtension(
            cardBg: Colors.white,
            textMain: Colors.black,
            textSecondary: Colors.grey,
            income: Colors.green,
            expense: Colors.red,
            iconBg: Colors.grey.shade200,
            bgGradientStart: Colors.blue.shade900,
            bgGradientEnd: Colors.blue.shade700,
            accent: Colors.blueAccent,
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            // 👇 Підміняємо реальний провайдер на наш безпечний тестовий
            settingsProvider.overrideWith(() => TestSettingsNotifier()),
          ],
          child: EasyLocalization(
            supportedLocales: const [Locale('uk')],
            path: 'assets/translations',
            fallbackLocale: const Locale('uk'),
            startLocale: const Locale('uk'),
            child: Builder(
              builder: (context) {
                return MaterialApp(
                  localizationsDelegates: context.localizationDelegates,
                  supportedLocales: context.supportedLocales,
                  locale: context.locale,
                  theme: testTheme,
                  home: Scaffold(
                    body: DueSubscriptionDialog(subscription: testSubscription),
                  ),
                );
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // ПЕРЕВІРКИ
      expect(find.byIcon(Icons.money_off_rounded), findsOneWidget);
      expect(find.byIcon(Icons.payments_outlined), findsOneWidget);
      expect(find.byIcon(Icons.close), findsOneWidget);

      expect(find.byType(TextButton), findsOneWidget);
      expect(find.byType(ElevatedButton), findsOneWidget);
    },
  );
}
