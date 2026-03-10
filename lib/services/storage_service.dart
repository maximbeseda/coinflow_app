import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/transaction_model.dart';
import '../models/category_model.dart';
import '../models/subscription_model.dart';
import '../theme/category_defaults.dart'; // ДОДАНО: Для авто-синхронізації
import '../utils/hive_adapters.dart';

class StorageService {
  static const String _historyBox = 'transactions';
  static const String _categoriesBox = 'categories';
  static const String _subscriptionsBox = 'subscriptions';
  static const String _settingsBox = 'settings';

  static const String _themeKey = 'current_theme_id';

  // ==========================================
  // РЕЄСТРАЦІЯ АДАПТЕРІВ
  // ==========================================
  static void registerAdapters() {
    Hive.registerAdapter(ColorAdapter());
    Hive.registerAdapter(IconDataAdapter());
    Hive.registerAdapter(CategoryTypeAdapter());
    Hive.registerAdapter(CategoryAdapter());
    Hive.registerAdapter(TransactionAdapter());
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(SubscriptionAdapter());
    }
  }

  // ==========================================
  // 1. СТРУКТУРНІ МІГРАЦІЇ (Тільки для нових полів у моделях)
  // ==========================================
  static const String _dbVersionKey = 'db_version';
  static const int currentDbVersion =
      1; // Піднімати ТІЛЬКИ якщо зміниш поля в моделях!

  static Future<void> runMigrationsIfNeeded() async {
    final box = Hive.box(_settingsBox);
    int savedVersion = box.get(_dbVersionKey, defaultValue: 1);

    if (savedVersion < currentDbVersion) {
      debugPrint(
        "Починаємо структурну міграцію DB з версії $savedVersion на $currentDbVersion...",
      );

      // Тут у майбутньому ти писатимеш міграції для нових полів
      // if (savedVersion < 2) { await _migrateToV2(); }

      await box.put(_dbVersionKey, currentDbVersion);
      debugPrint("Структурну міграцію успішно завершено!");
    }
  }

  // ==========================================
  // 2. АВТО-СИНХРОНІЗАЦІЯ ДИЗАЙНУ (Працює завжди)
  // ==========================================
  static Future<void> syncSystemDesign() async {
    final categories = await loadCategories();
    bool needsUpdate = false;
    List<Category> updatedList = [];

    for (var cat in categories) {
      // Запитуємо еталонні кольори
      final targetBgColor = CategoryDefaults.getBgColor(cat.type);
      final targetIconColor = CategoryDefaults.getIconColor(cat.type);

      // Перевіряємо, чи збігається база з еталоном
      if (cat.bgColor.toARGB32() != targetBgColor.toARGB32() ||
          cat.iconColor.toARGB32() != targetIconColor.toARGB32()) {
        // Якщо ні — створюємо копію з правильними кольорами
        updatedList.add(
          cat.copyWith(bgColor: targetBgColor, iconColor: targetIconColor),
        );
        needsUpdate = true;
      } else {
        updatedList.add(cat); // Залишаємо як є
      }
    }

    // Зберігаємо тільки якщо реально щось перефарбували
    if (needsUpdate) {
      await saveCategories(updatedList);
      debugPrint(
        "🎨 Авто-синхронізація: кольори категорій успішно оновлено за стандартами!",
      );
    }
  }

  // --- НАЛАШТУВАННЯ (Теми тощо) ---
  static Future<void> saveThemeId(String themeId) async {
    final box = Hive.box(_settingsBox);
    await box.put(_themeKey, themeId);
  }

  static String getThemeId() {
    final box = Hive.box(_settingsBox);
    return box.get(_themeKey, defaultValue: 'light');
  }

  // --- ІСТОРІЯ ТРАНЗАКЦІЙ ---
  static Future<void> saveHistory(List<Transaction> transactions) async {
    final box = Hive.box(_historyBox);
    await box.clear();
    final map = {for (var t in transactions) t.id: t};
    await box.putAll(map);
  }

  static Future<void> saveTransaction(Transaction transaction) async {
    final box = Hive.box(_historyBox);
    await box.put(transaction.id, transaction);
  }

  static Future<void> removeTransaction(String id) async {
    final box = Hive.box(_historyBox);
    await box.delete(id);
  }

  static Future<List<Transaction>> loadHistory() async {
    try {
      final box = Hive.box(_historyBox);
      if (box.isEmpty) return [];

      // БЕЗШОВНА МІГРАЦІЯ
      if (box.getAt(0) is Map) {
        debugPrint(
          "Виявлено старий формат транзакцій. Мігруємо на TypeAdapter...",
        );
        final oldList = box.values
            .map(
              (dynamic i) => Transaction.fromJson(Map<String, dynamic>.from(i)),
            )
            .toList();
        await box.clear();
        for (var t in oldList) {
          await box.put(t.id, t);
        }
        return oldList;
      }

      return box.values.cast<Transaction>().toList();
    } catch (e) {
      debugPrint("Помилка завантаження історії з Hive: $e");
      return [];
    }
  }

  // --- КАТЕГОРІЇ ---
  static Future<void> saveCategories(List<Category> categories) async {
    final box = Hive.box(_categoriesBox);
    await box.clear();
    final map = {
      for (var c in categories) c.id: c,
    }; // Більше не викликаємо .toJson()
    await box.putAll(map);
  }

  static Future<void> saveCategory(Category category) async {
    final box = Hive.box(_categoriesBox);
    await box.put(category.id, category); // Більше не викликаємо .toJson()
  }

  static Future<void> removeCategory(String id) async {
    final box = Hive.box(_categoriesBox);
    await box.delete(id);
  }

  static Future<List<Category>> loadCategories() async {
    try {
      final box = Hive.box(_categoriesBox);
      if (box.isEmpty) return [];

      // БЕЗШОВНА МІГРАЦІЯ: Якщо дані лежать у старому форматі JSON (Map)
      if (box.getAt(0) is Map) {
        debugPrint(
          "Виявлено старий формат категорій. Мігруємо на TypeAdapter...",
        );
        final oldList = box.values
            .map((dynamic i) => Category.fromJson(Map<String, dynamic>.from(i)))
            .toList();
        await box.clear();
        for (var c in oldList) {
          await box.put(c.id, c);
        }
        return oldList;
      }

      // Якщо формат вже новий (TypeAdapter)
      return box.values.cast<Category>().toList();
    } catch (e) {
      debugPrint("Помилка завантаження категорій з Hive: $e");
      return [];
    }
  }

  // --- ПІДПИСКИ ---
  static List<Subscription> getSubscriptions() {
    final box = Hive.box(_subscriptionsBox);
    return box.values.cast<Subscription>().toList();
  }

  static Future<void> saveSubscription(Subscription subscription) async {
    await Hive.box(_subscriptionsBox).put(subscription.id, subscription);
  }

  static Future<void> deleteSubscription(String id) async {
    await Hive.box(_subscriptionsBox).delete(id);
  }

  // --- ОЧИЩЕННЯ ---
  static Future<void> clearAll() async {
    await Hive.box(_historyBox).clear();
    await Hive.box(_categoriesBox).clear();
    await Hive.box(_subscriptionsBox).clear();
  }

  // ДОДАНО: Збереження та завантаження списку проігнорованих підписок
  static List<String> getIgnoredSubscriptions() {
    final box = Hive.box(_settingsBox);
    final data = box.get('ignored_subs', defaultValue: []);
    return (data as List).cast<String>();
  }

  static Future<void> saveIgnoredSubscriptions(List<String> ids) async {
    await Hive.box(_settingsBox).put('ignored_subs', ids);
  }
}
