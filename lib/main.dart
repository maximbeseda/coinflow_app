import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:device_preview/device_preview.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:easy_localization/easy_localization.dart';
import 'dart:ui';

import 'package:provider/provider.dart';
import 'screens/home_screen.dart';
import 'screens/onboarding_screen.dart'; // <-- ДОДАНО: Імпорт екрану онбордінгу
import 'screens/lock_screen.dart';
import 'providers/category_provider.dart';
import 'providers/transaction_provider.dart';
import 'providers/subscription_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/stats_provider.dart';
import 'theme/app_theme.dart';
import 'services/storage_service.dart';
import 'services/security_service.dart';
import 'database/app_database.dart';
import 'database/migration_service.dart';

// ГЛОБАЛЬНА ЗМІННА БАЗИ ДАНИХ (Тимчасово, поки не додамо Riverpod)
late AppDatabase appDb;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // 1. Ініціалізуємо Hive ТІЛЬКИ для налаштувань (Settings)
  await Hive.initFlutter();
  await Hive.openBox('settings'); // Відкриваємо тільки бокс налаштувань

  // 2. ІНІЦІАЛІЗУЄМО DRIFT БАЗУ ДАНИХ
  appDb = AppDatabase();

  // 3. МАГІЯ: Переливаємо дані з Hive у Drift (якщо ще не робили цього)
  await MigrationService.runMigrationIfNeeded(appDb);

  // 4. Твоя стара логіка (тимчасово залишаємо, щоб апка не зламалася прямо зараз)
  // У НАСТУПНОМУ КРОЦІ ми перепишемо StorageService!
  // StorageService.registerAdapters(); // <-- ЦЕ МОЖНА ВИДАЛИТИ, старі адаптери вже не потрібні

  // ВАЖЛИВО: Оскільки StorageService все ще очікує Hive, додаток зараз може підкреслювати помилки в StorageService.
  // Але ти можеш видалити стару папку models/ (окрім app_currency, вона потрібна).

  await initializeDateFormatting('uk_UA', null);
  const bool showPreview = false;

  final bool hasCompletedOnboarding = StorageService.hasCompletedOnboarding();
  final bool isPinSet = await SecurityService.isPinSet();

  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('uk'), Locale('en'), Locale('de')],
      path: 'assets/translations',
      fallbackLocale: const Locale('uk'),
      child: MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ThemeProvider()),

          // 1. Провайдер налаштувань (відповідає за валюти і курси)
          ChangeNotifierProvider(create: (_) => SettingsProvider()),

          // 2. Провайдер категорій (незалежний)
          ChangeNotifierProvider(create: (_) => CategoryProvider()),

          // 3. Провайдер транзакцій (слідкує за категоріями, щоб оновлювати їх баланси)
          ChangeNotifierProxyProvider2<
            CategoryProvider,
            SettingsProvider,
            TransactionProvider
          >(
            create: (_) => TransactionProvider(),
            update: (_, catProv, settingsProv, txProv) =>
                txProv!..updateDependencies(catProv, settingsProv),
          ),

          // 4. Провайдер підписок (слідкує за налаштуваннями, категоріями та транзакціями)
          ChangeNotifierProxyProvider3<
            CategoryProvider,
            TransactionProvider,
            SettingsProvider,
            SubscriptionProvider
          >(
            create: (_) => SubscriptionProvider(),
            update: (_, catProv, txProv, settingsProv, subProv) =>
                subProv!..updateDependencies(catProv, txProv, settingsProv),
          ),

          // 5. Провайдер статистики (Спеціалізований мозок для графіків)
          ChangeNotifierProxyProvider2<
            TransactionProvider,
            CategoryProvider,
            StatsProvider
          >(
            create: (_) => StatsProvider(),
            update: (_, txProv, catProv, statsProv) =>
                statsProv!..updateDependencies(txProv, catProv),
          ),
        ],
        child: DevicePreview(
          enabled: !kReleaseMode && showPreview,
          // 👇 ЗМІНЕНО: Передаємо статус онбордінгу в MyApp
          builder: (context) => MyApp(
            showOnboarding: !hasCompletedOnboarding,
            requirePin: isPinSet, // Передаємо статус ПІН-коду
          ),

          // ДЛЯ ПЕРЕВІРКИ ЕКРАНУ ОНБОРДИНГУ:
          // builder: (context) =>
          //    MyApp(showOnboarding: true), // Завжди показувати
        ),
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  final bool showOnboarding;
  final bool requirePin; // ДОДАНО: Параметр для ПІН-коду

  const MyApp({
    super.key,
    required this.showOnboarding,
    this.requirePin = false,
  });

  @override
  Widget build(BuildContext context) {
    // Слухаємо зміни теми через провайдер
    final themeProvider = context.watch<ThemeProvider>();

    // Отримуємо об'єкт теми з нашої фабрики AppTheme
    final currentTheme = AppTheme.getTheme(themeProvider.currentThemeId);

    // Встановлюємо стиль системних іконок (батарея, годинник) залежно від теми
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: currentTheme.brightness == Brightness.dark
            ? Brightness.light
            : Brightness.dark,
      ),
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'CoinFlow',

      // Локалізація
      localizationsDelegates: [
        ...context.localizationDelegates,
        GlobalCupertinoLocalizations
            .delegate, // Додаємо підтримку для Cupertino-віджетів
      ],
      supportedLocales: context.supportedLocales,
      locale: context.locale,

      // Налаштування теми
      theme: currentTheme,
      // Ми не використовуємо darkTheme параметр MaterialApp, бо наша система
      // через currentThemeId підтримує необмежену кількість кастомних тем.

      // Керування масштабуванням тексту (захист від занадто великих шрифтів у системі)
      builder: (context, child) {
        Widget currentChild = DevicePreview.appBuilder(context, child);
        final mediaQueryData = MediaQuery.of(context);
        final double baseScale = mediaQueryData.textScaler.scale(10) / 10;
        final double safeScale = baseScale.clamp(1.0, 1.15);

        return MediaQuery(
          data: mediaQueryData.copyWith(
            textScaler: TextScaler.linear(safeScale),
          ),
          child: currentChild,
        );
      },

      // Підтримка різних пристроїв введення (мишка, тачпад тощо)
      scrollBehavior: const MaterialScrollBehavior().copyWith(
        dragDevices: {
          PointerDeviceKind.mouse,
          PointerDeviceKind.touch,
          PointerDeviceKind.trackpad,
          PointerDeviceKind.stylus,
        },
      ),

      // Логіка: Онбордінг -> ПІН-код -> Головний екран
      home: showOnboarding
          ? const OnboardingScreen()
          : (requirePin ? const LockScreen() : const HomeScreen()),
    );
  }
}
