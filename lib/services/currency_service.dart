import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'storage_service.dart';

class CurrencyService {
  // Використовуємо надійне безкоштовне API без авторизації
  static const String _baseUrl = 'https://open.er-api.com/v6/latest';

  // Метод, який перевіряє, чи не час оновити курси (наприклад, раз на 12 годин)
  static Future<bool> updateRatesIfNeeded(String baseCurrency) async {
    try {
      final lastUpdate = StorageService.getLastRatesUpdateTime();
      final now = DateTime.now();

      // Оновлюємо, якщо даних ще немає, або пройшло більше 12 годин
      if (lastUpdate == null || now.difference(lastUpdate).inHours >= 12) {
        return await forceUpdateRates(baseCurrency);
      }
      return false; // Оновлення поки не потрібне
    } catch (e) {
      debugPrint('Помилка перевірки курсів валют: $e');
      return false;
    }
  }

  // Примусове завантаження свіжих курсів
  static Future<bool> forceUpdateRates(String baseCurrency) async {
    try {
      debugPrint('Завантаження нових курсів валют для бази: $baseCurrency...');
      final response = await http.get(Uri.parse('$_baseUrl/$baseCurrency'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // API повертає Map<String, dynamic>, приводимо до Map<String, double>
        final rates = (data['rates'] as Map<String, dynamic>).map(
          (key, value) => MapEntry(key, (value as num).toDouble()),
        );

        await StorageService.saveExchangeRates(rates);
        await StorageService.setLastRatesUpdateTime(DateTime.now());
        debugPrint('Курси валют успішно оновлено!');
        return true;
      } else {
        debugPrint('Помилка API курсів валют: код ${response.statusCode}');
        return false;
      }
    } catch (e) {
      debugPrint('Помилка завантаження курсів валют: $e');
      return false;
    }
  }
}
