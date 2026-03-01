import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:device_preview/device_preview.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'dart:ui'; // ДОДАНО: Для PointerDeviceKind
import 'screens/home_screen.dart';
import 'package:provider/provider.dart';
import 'providers/finance_provider.dart';
import 'models/subscription_model.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  await Hive.initFlutter();

  // Реєструємо адаптер для Підписок
  Hive.registerAdapter(SubscriptionAdapter());

  await Hive.openBox('categories');
  await Hive.openBox('transactions');
  await Hive.openBox('subscriptions'); // Відкриваємо коробку для Підписок

  await initializeDateFormatting('uk_UA', null);

  const bool showPreview = false;

  runApp(
    MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => FinanceProvider())],
      child: DevicePreview(
        enabled: !kReleaseMode && showPreview,
        builder: (context) => const MyApp(),
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      locale: DevicePreview.locale(context),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('uk', 'UA'), Locale('en', 'US')],
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

      debugShowCheckedModeBanner: false,
      title: 'CoinFlow',

      scrollBehavior: const MaterialScrollBehavior().copyWith(
        dragDevices: {
          PointerDeviceKind.mouse,
          PointerDeviceKind.touch,
          PointerDeviceKind.trackpad,
          PointerDeviceKind.stylus,
        },
      ),

      // --- ПІДКЛЮЧАЄМО ЗОВНІШНІ ТЕМИ ---
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode:
          ThemeMode.light, // Згодом тут можна буде поставити ThemeMode.system
      // ------------------------------------------------
      home: const HomeScreen(),
    );
  }
}
