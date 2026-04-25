import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

// =======================================================
// 1. КОНТРАКТ (ІНТЕРФЕЙС)
// =======================================================
// Це правило для будь-якого майбутнього API: воно зобов'язане
// віддавати курси у вигляді Map<String, double>
abstract class CurrencyRepository {
  Future<Map<String, double>?> fetchLatestRates(String baseCurrency);
  Future<Map<String, double>?> fetchHistoricalRates(
    String baseCurrency,
    DateTime date,
  );
}

// =======================================================
// 2. АДАПТЕР ДЛЯ ПОТОЧНОГО API (Fawazahmed)
// =======================================================
class FawazahmedApi implements CurrencyRepository {
  // 👇 ДОДАНО: Зберігаємо клієнт
  final http.Client _client;

  // 👇 ДОДАНО: Якщо клієнт не передали, створюємо стандартний (для реального додатку)
  FawazahmedApi({http.Client? client}) : _client = client ?? http.Client();

  // Внутрішній метод API, про який знає тільки цей адаптер
  Future<http.Response?> _fetchWithFallback(
    String dateStr,
    String baseLower,
  ) async {
    final List<String> urls = [
      'https://cdn.jsdelivr.net/npm/@fawazahmed0/currency-api@$dateStr/v1/currencies/$baseLower.json',
      'https://$dateStr.currency-api.pages.dev/v1/currencies/$baseLower.json',
    ];

    for (var url in urls) {
      try {
        final response = await _client
            .get(Uri.parse(url))
            .timeout(const Duration(seconds: 5));
        if (response.statusCode == 200) {
          return response;
        }
      } catch (e) {
        debugPrint('Помилка запиту до дзеркала $url: $e');
      }
    }
    return null;
  }

  @override
  Future<Map<String, double>?> fetchLatestRates(String baseCurrency) async {
    try {
      final String baseLower = baseCurrency.toLowerCase();
      final response = await _fetchWithFallback('latest', baseLower);

      if (response != null) {
        // ВИПРАВЛЕНО: Додано "as Map<String, dynamic>", щоб Dart знав тип даних
        final data = json.decode(response.body) as Map<String, dynamic>;
        final ratesData = data[baseLower] as Map<String, dynamic>;

        // Тут ми приводимо дані до формату, який вимагає наш додаток
        return ratesData.map(
          (key, value) =>
              MapEntry(key.toUpperCase(), (value as num).toDouble()),
        );
      }
      return null;
    } catch (e) {
      debugPrint('Помилка парсингу свіжих курсів: $e');
      return null;
    }
  }

  @override
  Future<Map<String, double>?> fetchHistoricalRates(
    String baseCurrency,
    DateTime date,
  ) async {
    try {
      final String baseLower = baseCurrency.toLowerCase();
      final dateStr =
          "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";

      final response = await _fetchWithFallback(dateStr, baseLower);

      if (response != null) {
        // ВИПРАВЛЕНО: Додано явне приведення типу
        final data = json.decode(response.body) as Map<String, dynamic>;
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

// Приклад того, як легко буде додати нове API в майбутньому:
/*
class NewPaidApi implements CurrencyRepository {
  @override
  Future<Map<String, double>?> fetchLatestRates(String baseCurrency) async {
     // тут логіка для іншого API з перевертанням дробів або іншими ключами
  }
  // ...
}
*/
