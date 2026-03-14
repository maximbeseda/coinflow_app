import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import '../services/currency_service.dart';

class SettingsProvider with ChangeNotifier {
  String _baseCurrency = 'UAH';
  List<String> _selectedCurrencies = ['UAH', 'USD', 'EUR'];
  Map<String, double> _exchangeRates = {};
  DateTime? _lastRatesUpdate;

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

    // ФІКС 1: Завжди тримаємо базову валюту на першому місці при завантаженні
    _enforceBaseCurrencyAtTop();

    _exchangeRates = StorageService.getExchangeRates();
    _lastRatesUpdate = StorageService.getLastRatesUpdateTime();

    notifyListeners();

    bool updated = await CurrencyService.updateRatesIfNeeded(_baseCurrency);
    if (updated) {
      _exchangeRates = StorageService.getExchangeRates();
      _lastRatesUpdate = StorageService.getLastRatesUpdateTime();
      notifyListeners();
    }
  }

  // --- ДОДАНО: Отримання курсу на конкретну дату ---
  // ЗМІНЕНО: Тепер повертає double? (може бути null, якщо курсу немає)
  Future<double?> getRateForDate(String currencyCode, DateTime date) async {
    if (currencyCode == _baseCurrency) return 1.0;

    final now = DateTime.now();
    // 1. Якщо це майбутня дата або сьогодні — беремо поточний кеш (це норма)
    if (date.year == now.year &&
            date.month == now.month &&
            date.day == now.day ||
        date.isAfter(now)) {
      return _exchangeRates[currencyCode] ?? 1.0;
    }

    // 2. Робимо запит за історичним курсом
    final historicalRates = await CurrencyService.getHistoricalRates(
      _baseCurrency,
      date,
    );

    if (historicalRates != null && historicalRates.containsKey(currencyCode)) {
      return historicalRates[currencyCode]!;
    }

    // 3. Якщо курсу за цю стару дату немає в API — чесно повертаємо null
    return null;
  }

  // Приватний метод для сортування списку
  void _enforceBaseCurrencyAtTop() {
    _selectedCurrencies.remove(_baseCurrency);
    _selectedCurrencies.insert(0, _baseCurrency);
  }

  Future<void> setBaseCurrency(String code) async {
    if (_baseCurrency == code) return;

    _baseCurrency = code;
    await StorageService.setBaseCurrency(code);

    // ФІКС 2: При зміні базової валюти вона автоматично стає першою в списку обраних
    _enforceBaseCurrencyAtTop();
    await StorageService.setSelectedCurrencies(_selectedCurrencies);

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

  Future<void> forceUpdateRates() async {
    bool updated = await CurrencyService.forceUpdateRates(_baseCurrency);
    if (updated) {
      _exchangeRates = StorageService.getExchangeRates();
      _lastRatesUpdate = StorageService.getLastRatesUpdateTime();
      notifyListeners();
    }
  }

  double convertToBase(double amount, String fromCurrency) {
    if (fromCurrency == _baseCurrency) return amount;

    final rate = _exchangeRates[fromCurrency];
    if (rate == null || rate == 0) return amount;

    return amount / rate;
  }
}
