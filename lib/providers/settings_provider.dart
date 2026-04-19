import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../services/storage_service.dart';
import '../services/currency_repository.dart';

// 👇 ДОДАНО: Імпорт провайдера категорій, щоб мати змогу їх оновити
import 'category_provider.dart';

part 'settings_provider.g.dart';

@Riverpod(keepAlive: true)
class CurrencyRepo extends _$CurrencyRepo {
  @override
  CurrencyRepository build() {
    return FawazahmedApi();
  }
}

class SettingsState {
  final String baseCurrency;
  final List<String> selectedCurrencies;
  final Map<String, double> exchangeRates;
  final DateTime? lastRatesUpdate;
  final Map<String, dynamic> historicalCache;

  SettingsState({
    required this.baseCurrency,
    required this.selectedCurrencies,
    required this.exchangeRates,
    this.lastRatesUpdate,
    required this.historicalCache,
  });

  SettingsState copyWith({
    String? baseCurrency,
    List<String>? selectedCurrencies,
    Map<String, double>? exchangeRates,
    DateTime? lastRatesUpdate,
    Map<String, dynamic>? historicalCache,
  }) {
    return SettingsState(
      baseCurrency: baseCurrency ?? this.baseCurrency,
      selectedCurrencies: selectedCurrencies ?? this.selectedCurrencies,
      exchangeRates: exchangeRates ?? this.exchangeRates,
      lastRatesUpdate: lastRatesUpdate ?? this.lastRatesUpdate,
      historicalCache: historicalCache ?? this.historicalCache,
    );
  }
}

@Riverpod(keepAlive: true)
class SettingsNotifier extends _$SettingsNotifier {
  CurrencyRepository get _api => ref.read(currencyRepoProvider);

  @override
  SettingsState build() {
    String base = StorageService.getBaseCurrency();
    List<String> selected = StorageService.getSelectedCurrencies();

    if (!selected.contains(base)) {
      selected.insert(0, base);
    } else {
      selected.remove(base);
      selected.insert(0, base);
    }

    final rates = StorageService.getExchangeRates();
    final lastUpdate = StorageService.getLastRatesUpdateTime();
    final cache = StorageService.getHistoricalRatesCache();

    final initialState = SettingsState(
      baseCurrency: base,
      selectedCurrencies: selected,
      exchangeRates: rates,
      lastRatesUpdate: lastUpdate,
      historicalCache: cache,
    );

    Future.microtask(() => _checkRatesUpdate(initialState));

    return initialState;
  }

  Future<void> _checkRatesUpdate(SettingsState currentState) async {
    final now = DateTime.now();
    if (currentState.lastRatesUpdate == null ||
        now.difference(currentState.lastRatesUpdate!).inHours >= 12) {
      await forceUpdateRates();
    }
  }

  Future<double?> getRateForDate(String currencyCode, DateTime date) async {
    if (currencyCode == state.baseCurrency) return 1.0;

    String dateKey =
        "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";

    if (state.historicalCache.containsKey(dateKey)) {
      final dayRates = state.historicalCache[dateKey] as Map;
      if (dayRates.containsKey(currencyCode)) {
        return (dayRates[currencyCode] as num).toDouble();
      }
    }

    final now = DateTime.now();
    final isToday =
        date.year == now.year && date.month == now.month && date.day == now.day;

    if (isToday || date.isAfter(now)) {
      return state.exchangeRates[currencyCode];
    }

    final historicalRates = await _api.fetchHistoricalRates(
      state.baseCurrency,
      date,
    );

    if (historicalRates != null && historicalRates.isNotEmpty) {
      final newCache = Map<String, dynamic>.from(state.historicalCache);
      newCache[dateKey] = historicalRates;

      state = state.copyWith(historicalCache: newCache);
      await StorageService.saveHistoricalRatesCache(newCache);

      if (historicalRates.containsKey(currencyCode)) {
        return historicalRates[currencyCode]!;
      }
    }
    return null;
  }

  Future<void> setBaseCurrency(String code) async {
    if (state.baseCurrency == code) return;

    // 👇 1. Фіксуємо СТАРУ базову валюту перед зміною
    final oldBaseCurrency = state.baseCurrency;

    final newRates = await _api.fetchLatestRates(code);

    if (newRates == null) {
      debugPrint(
        'Помилка: не вдалося отримати курси для $code. Міграцію скасовано.',
      );
      return;
    }

    final now = DateTime.now();

    await StorageService.saveBaseCurrency(code);
    await StorageService.saveExchangeRates(newRates);
    await StorageService.setLastRatesUpdateTime(now);

    List<String> newSelected = List.from(state.selectedCurrencies);
    newSelected.remove(code);
    newSelected.insert(0, code);
    await StorageService.setSelectedCurrencies(newSelected);
    await StorageService.saveHistoricalRatesCache({});

    // 👇 2. ВИКЛИКАЄМО РОЗУМНЕ ОНОВЛЕННЯ КАТЕГОРІЙ
    // Провайдер категорій знайде всі "старі" базові категорії і замінить їм валюту на нову
    ref
        .read(categoryProvider.notifier)
        .updateBaseCurrencyForCategories(oldBaseCurrency, code);

    // 3. Оновлюємо власний стан
    state = state.copyWith(
      baseCurrency: code,
      selectedCurrencies: newSelected,
      exchangeRates: newRates,
      lastRatesUpdate: now,
      historicalCache: {},
    );
  }

  Future<void> toggleSelectedCurrency(String code) async {
    List<String> newSelected = List.from(state.selectedCurrencies);

    if (newSelected.contains(code)) {
      if (code == state.baseCurrency) return;
      newSelected.remove(code);
    } else {
      newSelected.add(code);
    }

    await StorageService.setSelectedCurrencies(newSelected);
    state = state.copyWith(selectedCurrencies: newSelected);
  }

  Future<bool> forceUpdateRates() async {
    debugPrint('Завантаження нових курсів для: ${state.baseCurrency}');

    final newRates = await _api.fetchLatestRates(state.baseCurrency);

    if (newRates != null) {
      final now = DateTime.now();
      await StorageService.saveExchangeRates(newRates);
      await StorageService.setLastRatesUpdateTime(now);

      state = state.copyWith(exchangeRates: newRates, lastRatesUpdate: now);
      return true;
    }
    return false;
  }

  int convertToBase(int amount, String fromCurrency) {
    if (fromCurrency == state.baseCurrency) return amount;

    final rate = state.exchangeRates[fromCurrency];
    if (rate == null || rate == 0) return amount;
    return (amount / rate).round();
  }

  int convertAmount({
    required int amount,
    required String fromCurrency,
    required String toCurrency,
  }) {
    if (fromCurrency == toCurrency) return amount;

    double inBase = fromCurrency == state.baseCurrency
        ? amount.toDouble()
        : amount / (state.exchangeRates[fromCurrency] ?? 1.0);

    double result = toCurrency == state.baseCurrency
        ? inBase
        : inBase * (state.exchangeRates[toCurrency] ?? 1.0);

    return result.round();
  }
}
