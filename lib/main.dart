import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart'; // ДОДАНО: Бібліотека для керування орієнтацією екрана
import 'package:device_preview/device_preview.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'screens/home_screen.dart';
import 'package:provider/provider.dart';
import 'providers/finance_provider.dart';

void main() async {
  // Обов'язково для ініціалізації бази даних та системних налаштувань до запуску UI
  WidgetsFlutterBinding.ensureInitialized();

  // ДОДАНО: Жорстко фіксуємо орієнтацію екрана (тільки портретна)
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Ініціалізуємо Hive
  await Hive.initFlutter();

  // Відкриваємо наші локальні сховища
  await Hive.openBox('categories');
  await Hive.openBox('transactions');

  // Ініціалізуємо українські дати для кастомного календаря
  await initializeDateFormatting('uk_UA', null);

  // --- ТУТ МИ КЕРУЄМО ПЕРЕГЛЯДОМ ---
  const bool showPreview = true;

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => FinanceProvider(),
        ), // Підключаємо мозок
      ],
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
      // ДОДАНО: Підключаємо системні словники Flutter
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      // ДОДАНО: Список підтримуваних мов
      supportedLocales: const [
        Locale('uk', 'UA'), // Українська
        Locale('en', 'US'), // Англійська (як запасний варіант)
      ],
      builder: (context, child) {
        // Спочатку застосовуємо DevicePreview (якщо він увімкнений)
        Widget currentChild = DevicePreview.appBuilder(context, child);

        // ВИПРАВЛЕНО: Безпечне обмеження масштабування тексту, що не конфліктує з DatePicker
        final mediaQueryData = MediaQuery.of(context);
        final double baseScale = mediaQueryData.textScaler.scale(10) / 10;
        final double safeScale = baseScale.clamp(1.0, 1.15);

        return MediaQuery(
          data: mediaQueryData.copyWith(
            textScaler: TextScaler.linear(
              safeScale,
            ), // Використовуємо лінійний скейлер
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

      theme: ThemeData(useMaterial3: true),
      home: const HomeScreen(),
    );
  }
}
