import 'package:flutter/foundation.dart'
    hide Category; // Сховали системну Category
import 'package:hive_flutter/hive_flutter.dart';
import '../models/transaction_model.dart';
import '../models/category_model.dart';

class StorageService {
  static const String _historyBox = 'transactions';
  static const String _categoriesBox = 'categories';

  // --- ІСТОРІЯ ТРАНЗАКЦІЙ ---
  static Future<void> saveHistory(List<Transaction> history) async {
    final box = Hive.box(_historyBox);
    final map = {for (var t in history) t.id: t.toJson()};
    await box.putAll(map);
  }

  static Future<void> saveTransaction(Transaction t) async {
    final box = Hive.box(_historyBox);
    await box.put(t.id, t.toJson());
  }

  static Future<void> removeTransaction(String id) async {
    final box = Hive.box(_historyBox);
    await box.delete(id);
  }

  static Future<List<Transaction>> loadHistory() async {
    try {
      final box = Hive.box(_historyBox);
      if (box.isEmpty) return [];

      return box.values
          .map(
            (dynamic i) => Transaction.fromJson(Map<String, dynamic>.from(i)),
          )
          .toList();
    } catch (e) {
      debugPrint("Помилка завантаження історії з Hive: $e");
      return []; // Рятуємо додаток від крашу, повертаючи порожній список
    }
  }

  // --- КАТЕГОРІЇ ---
  static Future<void> saveCategories(List<Category> categories) async {
    final box = Hive.box(_categoriesBox);
    final map = {for (var c in categories) c.id: c.toJson()};
    await box.putAll(map);
  }

  static Future<void> saveCategory(Category category) async {
    final box = Hive.box(_categoriesBox);
    await box.put(category.id, category.toJson());
  }

  static Future<void> removeCategory(String id) async {
    final box = Hive.box(_categoriesBox);
    await box.delete(id);
  }

  static Future<List<Category>> loadCategories() async {
    try {
      final box = Hive.box(_categoriesBox);
      if (box.isEmpty) return [];

      return box.values
          .map((dynamic i) => Category.fromJson(Map<String, dynamic>.from(i)))
          .toList();
    } catch (e) {
      debugPrint("Помилка завантаження категорій з Hive: $e");
      return []; // Рятуємо додаток від крашу
    }
  }

  // --- ДОДАНО ДЛЯ БЕКАПІВ: Повне очищення бази перед відновленням ---
  static Future<void> clearAll() async {
    await Hive.box(_historyBox).clear();
    await Hive.box(_categoriesBox).clear();
  }
}
