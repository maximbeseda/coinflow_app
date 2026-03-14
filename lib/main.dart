import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:device_preview/device_preview.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:easy_localization/easy_localization.dart';
import 'dart:ui';

import 'package:provider/provider.dart';
import 'screens/home_screen.dart';
import 'providers/category_provider.dart';
import 'providers/transaction_provider.dart';
import 'providers/subscription_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/settings_provider.dart';
import 'theme/app_theme.dart';
import 'services/storage_service.dart';

void main() async {
  // 1. Гарантуємо ініціалізацію Flutter
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Ініціалізуємо локалізацію
  await EasyLocalization.ensureInitialized();

  // 3. Фіксуємо орієнтацію екрана
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // 4. Ініціалізуємо базу даних Hive
  await Hive.initFlutter();

  // Реєструємо всі адаптери через наш сервіс
  StorageService.registerAdapters();

  // Відкриваємо всі необхідні бокси
  await Future.wait([
    Hive.openBox('categories'),
    Hive.openBox('transactions'),
    Hive.openBox('subscriptions'),
    Hive.openBox('settings'),
  ]);

  // ==========================================
  // Глобальний менеджер міграцій баз даних
  // ==========================================
  // Виконується строго ПІСЛЯ відкриття боксів, але ДО запуску UI
  await StorageService.runMigrationsIfNeeded();

  // ==========================================
  // АВТО-СИНХРОНІЗАЦІЯ ДИЗАЙНУ
  // Перефарбовує старі категорії у актуальні кольори
  // ==========================================
  await StorageService.syncSystemDesign();

  // 5. Ініціалізуємо формати дат
  await initializeDateFormatting('uk_UA', null);

  const bool showPreview = false;

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
          ChangeNotifierProxyProvider<CategoryProvider, TransactionProvider>(
            create: (_) => TransactionProvider(),
            update: (_, catProv, txProv) =>
                txProv!..updateDependencies(catProv),
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
        ],
        child: DevicePreview(
          enabled: !kReleaseMode && showPreview,
          builder: (context) => const MyApp(),
        ),
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

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
      localizationsDelegates: context.localizationDelegates,
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

      home: const HomeScreen(),
    );
  }
}
