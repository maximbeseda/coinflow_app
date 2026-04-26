import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

import 'package:coin_flow/main.dart';
import 'package:coin_flow/providers/all_providers.dart';
import 'package:coin_flow/screens/home_screen.dart';
import 'package:coin_flow/screens/onboarding_screen.dart';
import 'package:coin_flow/screens/lock_screen.dart';

// Фейкова реалізація для шляхів до файлів (щоб база даних не падала)
class FakePathProvider extends PathProviderPlatform {
  @override
  Future<String?> getApplicationDocumentsPath() async => '.';
}

void main() {
  late SharedPreferences sharedPrefs;

  setUpAll(() async {
    // Ініціалізація зв'язку з фреймворком
    TestWidgetsFlutterBinding.ensureInitialized();

    // 1. Мокаємо Path Provider (важливо для Drift DB)
    PathProviderPlatform.instance = FakePathProvider();

    // 2. Спочатку мокаємо SharedPreferences
    SharedPreferences.setMockInitialValues({});

    // 3. Мокаємо Secure Storage
    FlutterSecureStorage.setMockInitialValues({});

    // 4. Тепер ініціалізуємо локалізацію
    await EasyLocalization.ensureInitialized();

    // 5. Мокаємо PackageInfo
    PackageInfo.setMockInitialValues(
      appName: 'CoinFlow',
      packageName: 'com.example.coinflow',
      version: '1.0.0',
      buildNumber: '1',
      buildSignature: 'buildSignature',
    );
  });

  setUp(() async {
    sharedPrefs = await SharedPreferences.getInstance();
  });

  group('MyApp Navigation Tests', () {
    Widget createTestableMyApp({
      required bool showOnboarding,
      bool requirePin = false,
    }) {
      return ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(sharedPrefs)],
        child: EasyLocalization(
          supportedLocales: const [Locale('uk'), Locale('en')],
          path: 'assets/translations',
          useOnlyLangCode: true,
          child: Builder(
            builder: (context) {
              return MyApp(
                showOnboarding: showOnboarding,
                requirePin: requirePin,
              );
            },
          ),
        ),
      );
    }

    testWidgets('1. Показує OnboardingScreen, якщо showOnboarding: true', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;

      await tester.runAsync(() async {
        await tester.pumpWidget(createTestableMyApp(showOnboarding: true));
        await tester.pump(const Duration(milliseconds: 200));
        expect(find.byType(OnboardingScreen), findsOneWidget);
      });

      addTearDown(tester.view.resetPhysicalSize);
    });

    testWidgets('2. Показує LockScreen, якщо PIN встановлено', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);

      await tester.runAsync(() async {
        await tester.pumpWidget(
          createTestableMyApp(showOnboarding: false, requirePin: true),
        );
        await tester.pump(const Duration(milliseconds: 200));
        expect(find.byType(LockScreen), findsOneWidget);
      });

      addTearDown(tester.view.resetPhysicalSize);
    });

    testWidgets('3. Показує HomeScreen, якщо онбординг пройдено', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);

      await tester.runAsync(() async {
        await tester.pumpWidget(
          createTestableMyApp(showOnboarding: false, requirePin: false),
        );
        await tester.pump(const Duration(milliseconds: 200));
        expect(find.byType(HomeScreen), findsOneWidget);
      });

      addTearDown(tester.view.resetPhysicalSize);
    });
  });
}
