import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import '../services/currency_repository.dart'; // 👇 Підключили новий файл

class SettingsProvider with ChangeNotifier {
  // 👇 ОСЬ ВОНО! НАШ АДАПТЕР!
  // Якщо колись зміниш API, просто напишеш: final CurrencyRepository _api = NewPaidApi();
  // І більше ЖОДНОГО рядка коду в додатку міняти не доведеться.
  final CurrencyRepository _api = FawazahmedApi();

  String _baseCurrency = 'UAH';
  List<String> _selectedCurrencies = ['UAH', 'USD', 'EUR'];
  Map<String, double> _exchangeRates = {};
  DateTime? _lastRatesUpdate;
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
    _historicalCache = StorageService.getHistoricalRatesCache();

    notifyListeners();

    // 👇 Логіка перевірки "чи пройшло 12 годин" тепер живе тут
    final now = DateTime.now();
    if (_lastRatesUpdate == null ||
        now.difference(_lastRatesUpdate!).inHours >= 12) {
      await forceUpdateRates();
    }
  }

  Future<double?> getRateForDate(String currencyCode, DateTime date) async {
    if (currencyCode == _baseCurrency) return 1.0;

    String dateKey =
        "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";

    if (_historicalCache.containsKey(dateKey)) {
      final dayRates = _historicalCache[dateKey] as Map;
      if (dayRates.containsKey(currencyCode)) {
        return (dayRates[currencyCode] as num).toDouble();
      }
    }

    final now = DateTime.now();
    if ((date.year == now.year &&
            date.month == now.month &&
            date.day == now.day) ||
        date.isAfter(now)) {
      return _exchangeRates[currencyCode];
    }

    // 👇 Звертаємось до API через абстрактний інтерфейс
    final historicalRates = await _api.fetchHistoricalRates(
      _baseCurrency,
      date,
    );

    if (historicalRates != null && historicalRates.isNotEmpty) {
      _historicalCache[dateKey] = historicalRates;
      await StorageService.saveHistoricalRatesCache(_historicalCache);

      if (historicalRates.containsKey(currencyCode)) {
        return historicalRates[currencyCode]!;
      }
    }

    return null;
  }

  void _enforceBaseCurrencyAtTop() {
    _selectedCurrencies.remove(_baseCurrency);
    _selectedCurrencies.insert(0, _baseCurrency);
  }

  Future<void> setBaseCurrency(String code) async {
    if (_baseCurrency == code) return;

    _baseCurrency = code;
    await StorageService.saveBaseCurrency(code);

    _enforceBaseCurrencyAtTop();
    await StorageService.setSelectedCurrencies(_selectedCurrencies);

    _historicalCache.clear();
    await StorageService.saveHistoricalRatesCache({});

    notifyListeners();
    await forceUpdateRates();
  }

  Future<void> toggleSelectedCurrency(String code) async {
    if (_selectedCurrencies.contains(code)) {
      if (code == _baseCurrency) return;
      _selectedCurrencies.remove(code);
    } else {
      _selectedCurrencies.add(code);
    }
    await StorageService.setSelectedCurrencies(_selectedCurrencies);
    notifyListeners();
  }

  Future<bool> forceUpdateRates() async {
    debugPrint('Завантаження нових курсів валют для бази: $_baseCurrency...');

    // 👇 Отримуємо курси з нашого Адаптера
    final newRates = await _api.fetchLatestRates(_baseCurrency);

    if (newRates != null) {
      _exchangeRates = newRates;
      _lastRatesUpdate = DateTime.now();

      await StorageService.saveExchangeRates(_exchangeRates);
      await StorageService.setLastRatesUpdateTime(_lastRatesUpdate!);

      notifyListeners();
      debugPrint('Курси валют успішно оновлено!');
      return true;
    }

    debugPrint('Всі сервери курсів валют недоступні.');
    return false;
  }

  int convertToBase(int amount, String fromCurrency) {
    if (fromCurrency == _baseCurrency) return amount;
    final rate = _exchangeRates[fromCurrency];
    if (rate == null || rate == 0) return amount;
    return (amount / rate).round();
  }

  int convertAmount({
    required int amount,
    required String fromCurrency,
    required String toCurrency,
  }) {
    if (fromCurrency == toCurrency) return amount;

    double inBase = fromCurrency == _baseCurrency
        ? amount.toDouble()
        : amount / (_exchangeRates[fromCurrency] ?? 1.0);

    double result = toCurrency == _baseCurrency
        ? inBase
        : inBase * (_exchangeRates[toCurrency] ?? 1.0);

    return result.round();
  }
}
