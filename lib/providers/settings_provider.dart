import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import '../services/currency_service.dart';

class SettingsProvider with ChangeNotifier {
  String _baseCurrency = 'UAH';
  List<String> _selectedCurrencies = ['UAH', 'USD', 'EUR'];
  Map<String, double> _exchangeRates = {};
  DateTime? _lastRatesUpdate;

  // ДОДАНО: Локальна змінна для історичного кешу
  Map<String, dynamic> _historicalCache = {};

  String get baseCurrency => _baseCurrency;
  List<String> get selectedCurrencies => _selectedCurrencies;
  Map<String, double> get exchangeRates => _exchangeRates;
  DateTime? get lastRatesUpdate => _lastRatesUpdate;

  SettingsProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    _baseCurrency = StorageService.getBaseCurrency();
    _selectedCurrencies = StorageService.getSelectedCurrencies();

    _enforceBaseCurrencyAtTop();

    _exchangeRates = StorageService.getExchangeRates();
    _lastRatesUpdate = StorageService.getLastRatesUpdateTime();

    // ДОДАНО: Завантажуємо історичний кеш при старті
    _historicalCache = StorageService.getHistoricalRatesCache();

    notifyListeners();

    bool updated = await CurrencyService.updateRatesIfNeeded(_baseCurrency);
    if (updated) {
      _exchangeRates = StorageService.getExchangeRates();
      _lastRatesUpdate = StorageService.getLastRatesUpdateTime();
      notifyListeners();
    }
  }

  // =======================================================
  // 👇 ПОВНІСТЮ ОНОВЛЕНО: "Ліниве завантаження" історії
  // =======================================================
  Future<double?> getRateForDate(String currencyCode, DateTime date) async {
    if (currencyCode == _baseCurrency) return 1.0;

    // Формуємо ключ, наприклад: "2026-03-15"
    String dateKey =
        "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";

    // 1. ШУКАЄМО В ЛОКАЛЬНОМУ КЕШІ (0 мілісекунд)
    if (_historicalCache.containsKey(dateKey)) {
      final dayRates = _historicalCache[dateKey] as Map;
      if (dayRates.containsKey(currencyCode)) {
        return (dayRates[currencyCode] as num).toDouble();
      }
    }

    final now = DateTime.now();
    // 2. Якщо це майбутня дата або сьогодні — беремо поточний кеш (це норма)
    if ((date.year == now.year &&
            date.month == now.month &&
            date.day == now.day) ||
        date.isAfter(now)) {
      return _exchangeRates[currencyCode]; // Може повернути null, тоді спрацює "Страховка" в UI
    }

    // 3. ЯКЩО НЕМАЄ - ЙДЕМО В ІНТЕРНЕТ (API)
    final historicalRates = await CurrencyService.getHistoricalRates(
      _baseCurrency,
      date,
    );

    if (historicalRates != null && historicalRates.isNotEmpty) {
      // 4. ЗБЕРІГАЄМО ВЕСЬ СЛОВНИК В КЕШ НАЗАВЖДИ
      _historicalCache[dateKey] = historicalRates;
      await StorageService.saveHistoricalRatesCache(_historicalCache);

      if (historicalRates.containsKey(currencyCode)) {
        return historicalRates[currencyCode]!;
      }
    }

    // 5. Якщо курсу за цю дату немає в API — чесно повертаємо null
    return null;
  }

  void _enforceBaseCurrencyAtTop() {
    _selectedCurrencies.remove(_baseCurrency);
    _selectedCurrencies.insert(0, _baseCurrency);
  }

  Future<void> setBaseCurrency(String code) async {
    if (_baseCurrency == code) return;

    _baseCurrency = code;
    await StorageService.setBaseCurrency(code);

    _enforceBaseCurrencyAtTop();
    await StorageService.setSelectedCurrencies(_selectedCurrencies);

    // 👇 ДОДАНО: Очищаємо кеш історії, бо Якір змінився!
    _historicalCache.clear();
    await StorageService.saveHistoricalRatesCache({});

    notifyListeners();
    await forceUpdateRates();
  }

  Future<void> toggleSelectedCurrency(String code) async {
    if (_selectedCurrencies.contains(code)) {
      if (code == _baseCurrency) return; // Захист: не можна видалити базову
      _selectedCurrencies.remove(code);
    } else {
      _selectedCurrencies.add(code);
    }
    await StorageService.setSelectedCurrencies(_selectedCurrencies);
    notifyListeners();
  }

  Future<bool> forceUpdateRates() async {
    bool updated = await CurrencyService.forceUpdateRates(_baseCurrency);
    if (updated) {
      _exchangeRates = StorageService.getExchangeRates();
      _lastRatesUpdate = StorageService.getLastRatesUpdateTime();
      notifyListeners();
    }
    return updated;
  }

  double convertToBase(double amount, String fromCurrency) {
    if (fromCurrency == _baseCurrency) return amount;

    final rate = _exchangeRates[fromCurrency];
    if (rate == null || rate == 0) return amount;

    return amount / rate;
  }
}
