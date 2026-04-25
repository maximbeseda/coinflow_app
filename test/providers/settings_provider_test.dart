import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart'; // Додай: flutter pub add dev:mocktail
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:coin_flow/providers/all_providers.dart';
import 'package:coin_flow/services/currency_repository.dart';

// 1. Створюємо МОК для репозиторію курсів
class MockCurrencyRepository extends Mock implements CurrencyRepository {}

// 2. Створюємо ШПИГУНА для категорій, щоб перевірити інтеграцію
class SpyCategoryNotifier extends CategoryNotifier {
  String? updatedOldBase;
  @override
  CategoryState build() => CategoryState(
    incomes: [],
    accounts: [],
    expenses: [],
    archivedCategories: [],
    deletedCategories: [],
    isLoading: false,
  );

  @override
  Future<void> updateBaseCurrencyForCategories(
    String oldBase,
    String newBase,
  ) async {
    updatedOldBase = oldBase;
  }
}

void main() {
  late MockCurrencyRepository mockApi;
  late SharedPreferences prefs;

  // Функція для створення контейнера з усіма заглушками
  Future<ProviderContainer> createContainer() async {
    mockApi = MockCurrencyRepository();
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();

    // 👇 ФІКС: Обов'язково ставимо дефолтну відповідь для початкового завантаження курсів.
    // Це потрібно, бо build() викликає forceUpdateRates() автоматично.
    when(
      () => mockApi.fetchLatestRates(any()),
    ).thenAnswer((_) async => {'USD': 40.0, 'UAH': 1.0});

    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        currencyRepoProvider.overrideWithValue(mockApi),
        categoryProvider.overrideWith(() => SpyCategoryNotifier()),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  group('SettingsNotifier - Глибоке покриття', () {
    test(
      'Математика конвертації: convertAmount (USD -> JPY через UAH)',
      () async {
        final container = await createContainer();
        final notifier = container.read(settingsProvider.notifier);
        await Future.delayed(Duration.zero);

        // Жорстко задаємо курси для тесту
        notifier.state = SettingsState(
          baseCurrency: 'UAH',
          selectedCurrencies: const ['UAH', 'USD', 'JPY'],
          exchangeRates: const {
            'USD': 0.025,
            'JPY': 4.0,
          }, // 1 UAH = 0.025 USD, 1 UAH = 4 JPY
          historicalCache: const {},
        );

        // Конвертуємо 100 USD (в копійках - 10000)
        // 100 / 0.025 = 4000 UAH. 4000 * 4 = 16000 JPY.
        final result = notifier.convertAmount(
          amount: 10000,
          fromCurrency: 'USD',
          toCurrency: 'JPY',
        );

        expect(result, 1600000); // Очікуємо 160.00 JPY у копійках
      },
    );

    test('Міграція: setBaseCurrency змінює валюту та очищує кеш', () async {
      final container = await createContainer();
      final notifier = container.read(settingsProvider.notifier);
      final spyCategory =
          container.read(categoryProvider.notifier) as SpyCategoryNotifier;

      notifier.state = notifier.state.copyWith(
        baseCurrency: 'UAH',
        historicalCache: {'cache': 'data'},
      );

      // Готуємо "відповідь" від сервера
      when(
        () => mockApi.fetchLatestRates('USD'),
      ).thenAnswer((_) async => {'UAH': 0.025});

      await notifier.setBaseCurrency('USD');

      expect(notifier.state.baseCurrency, 'USD');
      expect(
        notifier.state.historicalCache.isEmpty,
        true,
      ); // Кеш має бути порожнім
      expect(
        spyCategory.updatedOldBase,
        'UAH',
      ); // Перевірка, що категорії отримали сигнал
      expect(
        prefs.getString('base_currency'),
        'USD',
      ); // Перевірка збереження на диск
    });

    test('toggleSelectedCurrency не дозволяє видалити базову валюту', () async {
      final container = await createContainer();
      final notifier = container.read(settingsProvider.notifier);

      final base = notifier.state.baseCurrency; // Зазвичай UAH

      // Спробуємо видалити базову валюту
      await notifier.toggleSelectedCurrency(base);

      // Вона МАЄ залишитися в списку
      expect(
        container.read(settingsProvider).selectedCurrencies.contains(base),
        true,
      );
    });

    // Твої оригінальні тести (інтегровані)
    test('toggleSelectedCurrency додає та видаляє сторонню валюту', () async {
      final container = await createContainer();
      final notifier = container.read(settingsProvider.notifier);
      const testCurrency = 'CAD';

      await notifier.toggleSelectedCurrency(testCurrency);
      expect(
        container
            .read(settingsProvider)
            .selectedCurrencies
            .contains(testCurrency),
        true,
      );

      await notifier.toggleSelectedCurrency(testCurrency);
      expect(
        container
            .read(settingsProvider)
            .selectedCurrencies
            .contains(testCurrency),
        false,
      );
    });
  });
}
