import 'package:hive_flutter/hive_flutter.dart';
import '../models/transaction_model.dart';
import '../models/category_model.dart';

class StorageService {
  static const String _historyBox = 'transactions';
  static const String _categoriesBox = 'categories';

  // --- ІСТОРІЯ ТРАНЗАКЦІЙ ---
  static Future<void> saveHistory(List<Transaction> history) async {
    final box = Hive.box(_historyBox);
    await box.clear(); // Очищаємо старі дані

    // Перетворюємо список у Map для миттєвого збереження в базу
    final map = {for (var t in history) t.id: t.toJson()};
    await box.putAll(map);
  }

  static Future<List<Transaction>> loadHistory() async {
    final box = Hive.box(_historyBox);
    if (box.isEmpty) return [];

    return box.values
        .map((dynamic i) => Transaction.fromJson(Map<String, dynamic>.from(i)))
        .toList();
  }

  // --- КАТЕГОРІЇ ---
  static Future<void> saveCategories(List<Category> categories) async {
    final box = Hive.box(_categoriesBox);
    await box.clear();

    final map = {for (var c in categories) c.id: c.toJson()};
    await box.putAll(map);
  }

  static Future<List<Category>> loadCategories() async {
    final box = Hive.box(_categoriesBox);
    if (box.isEmpty) return [];

    return box.values
        .map((dynamic i) => Category.fromJson(Map<String, dynamic>.from(i)))
        .toList();
  }

  // --- БАЛАНСИ КАТЕГОРІЙ ---
  // Зберігаємо зміну балансу прямо всередині збереженої категорії
  static Future<void> saveAmount(String id, double amount) async {
    final box = Hive.box(_categoriesBox);
    final raw = box.get(id);
    if (raw != null) {
      final catMap = Map<String, dynamic>.from(raw);
      catMap['amount'] = amount;
      await box.put(id, catMap);
    }
  }

  static Future<double?> loadAmount(String id) async {
    final box = Hive.box(_categoriesBox);
    final raw = box.get(id);
    if (raw != null) {
      return Map<String, dynamic>.from(raw)['amount']?.toDouble();
    }
    return null;
  }
}
