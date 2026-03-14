import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'storage_service.dart';

class CurrencyService {
  // --- РОЗУМНИЙ МЕТОД З РЕЗЕРВНИМИ КАНАЛАМИ (FALLBACKS) ---
  static Future<http.Response?> _fetchWithFallback(
    String dateStr,
    String baseLower,
  ) async {
    // Список дзеркал: від найшвидшого до резервних
    final List<String> urls = [
      'https://cdn.jsdelivr.net/npm/@fawazahmed0/currency-api@$dateStr/v1/currencies/$baseLower.json',
      'https://$dateStr.currency-api.pages.dev/v1/currencies/$baseLower.json',
    ];

    for (var url in urls) {
      try {
        // Ставимо таймаут 5 секунд. Якщо сервер не відповідає, йдемо до наступного URL
        final response = await http
            .get(Uri.parse(url))
            .timeout(const Duration(seconds: 5));
        if (response.statusCode == 200) {
          return response; // Успіх! Повертаємо дані
        }
      } catch (e) {
        debugPrint('Помилка запиту до дзеркала $url: $e');
        // Продовжуємо цикл, щоб спробувати наступний URL
      }
    }
    return null; // Всі сервери недоступні (немає інтернету)
  }

  // --- 1. ПЕРЕВІРКА ТА ОНОВЛЕННЯ ПОТОЧНИХ КУРСІВ ---
  static Future<bool> updateRatesIfNeeded(String baseCurrency) async {
    try {
      final lastUpdate = StorageService.getLastRatesUpdateTime();
      final now = DateTime.now();

      // Оновлюємо раз на 12 годин
      if (lastUpdate == null || now.difference(lastUpdate).inHours >= 12) {
        return await forceUpdateRates(baseCurrency);
      }
      return false;
    } catch (e) {
      debugPrint('Помилка перевірки курсів валют: $e');
      return false;
    }
  }

  // --- 2. ПРИМУСОВЕ ЗАВАНТАЖЕННЯ ПОТОЧНИХ КУРСІВ ---
  static Future<bool> forceUpdateRates(String baseCurrency) async {
    try {
      debugPrint('Завантаження нових курсів валют для бази: $baseCurrency...');
      final String baseLower = baseCurrency.toLowerCase();

      final response = await _fetchWithFallback('latest', baseLower);

      if (response != null) {
        final data = json.decode(response.body);
        final ratesData = data[baseLower] as Map<String, dynamic>;

        final rates = ratesData.map(
          (key, value) =>
              MapEntry(key.toUpperCase(), (value as num).toDouble()),
        );

        await StorageService.saveExchangeRates(rates);
        await StorageService.setLastRatesUpdateTime(DateTime.now());
        debugPrint('Курси валют успішно оновлено!');
        return true;
      }

      debugPrint('Всі сервери курсів валют недоступні.');
      return false;
    } catch (e) {
      debugPrint('Помилка парсингу курсів валют: $e');
      return false;
    }
  }

  // --- 3. ОТРИМАННЯ ІСТОРИЧНИХ КУРСІВ ЗА ДАТОЮ ---
  static Future<Map<String, double>?> getHistoricalRates(
    String baseCurrency,
    DateTime date,
  ) async {
    try {
      final String baseLower = baseCurrency.toLowerCase();
      final dateStr =
          "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";

      final response = await _fetchWithFallback(dateStr, baseLower);

      if (response != null) {
        final data = json.decode(response.body);
        final ratesData = data[baseLower] as Map<String, dynamic>;

        return ratesData.map(
          (key, value) =>
              MapEntry(key.toUpperCase(), (value as num).toDouble()),
        );
      }
      return null;
    } catch (e) {
      debugPrint('Помилка парсингу історичних курсів: $e');
      return null;
    }
  }
}
