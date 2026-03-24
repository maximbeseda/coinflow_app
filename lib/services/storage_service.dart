import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/transaction_model.dart';
import '../models/category_model.dart';
import '../models/subscription_model.dart';
import '../theme/category_defaults.dart';
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
  // 1. СТРУКТУРНІ МІГРАЦІЇ
  // ==========================================
  static const String _dbVersionKey = 'db_version';
  static const int currentDbVersion = 1;

  static Future<void> runMigrationsIfNeeded() async {
    final box = Hive.box(_settingsBox);
    int savedVersion = box.get(_dbVersionKey, defaultValue: 1);

    if (savedVersion < currentDbVersion) {
      debugPrint(
        "Починаємо структурну міграцію DB з версії $savedVersion на $currentDbVersion...",
      );
      await box.put(_dbVersionKey, currentDbVersion);
      debugPrint("Структурну міграцію успішно завершено!");
    }
  }

  // ==========================================
  // 2. АВТО-СИНХРОНІЗАЦІЯ ДИЗАЙНУ
  // ==========================================
  static Future<void> syncSystemDesign() async {
    final categories = await loadCategories();
    bool needsUpdate = false;
    List<Category> updatedList = [];

    for (var cat in categories) {
      final targetBgColor = CategoryDefaults.getBgColor(cat.type);
      final targetIconColor = CategoryDefaults.getIconColor(cat.type);

      if (cat.bgColor.toARGB32() != targetBgColor.toARGB32() ||
          cat.iconColor.toARGB32() != targetIconColor.toARGB32()) {
        updatedList.add(
          cat.copyWith(bgColor: targetBgColor, iconColor: targetIconColor),
        );
        needsUpdate = true;
      } else {
        updatedList.add(cat);
      }
    }

    if (needsUpdate) {
      await saveCategories(updatedList);
      debugPrint(
        "🎨 Авто-синхронізація: кольори категорій успішно оновлено за стандартами!",
      );
    }
  }

  // --- НАЛАШТУВАННЯ (Теми) ---
  static Future<void> saveThemeId(String themeId) async {
    final box = Hive.box(_settingsBox);
    await box.put(_themeKey, themeId);
  }

  static String getThemeId() {
    final box = Hive.box(_settingsBox);
    return box.get(_themeKey, defaultValue: 'light');
  }

  // ==========================================
  // ОНБОРДІНГ (Перший запуск)
  // ==========================================
  static bool hasCompletedOnboarding() {
    final box = Hive.box(_settingsBox);
    return box.get('onboarding_completed', defaultValue: false) ?? false;
  }

  static Future<void> completeOnboarding() async {
    await Hive.box(_settingsBox).put('onboarding_completed', true);
  }

  // ==========================================
  // НОВЕ: НАЛАШТУВАННЯ ВАЛЮТ
  // ==========================================

  // 1. Базова валюта
  static String getBaseCurrency() {
    final box = Hive.box(_settingsBox);
    return box.get('base_currency', defaultValue: 'UAH');
  }

  static Future<void> setBaseCurrency(String code) async {
    await Hive.box(_settingsBox).put('base_currency', code);
  }

  // 2. Обрані валюти (для екрану курсів та створення рахунків)
  static List<String> getSelectedCurrencies() {
    final box = Hive.box(_settingsBox);
    final data = box.get(
      'selected_currencies',
      defaultValue: ['UAH', 'USD', 'EUR'],
    );
    return (data as List).cast<String>();
  }

  static Future<void> setSelectedCurrencies(List<String> codes) async {
    await Hive.box(_settingsBox).put('selected_currencies', codes);
  }

  // 3. Кешовані курси (відносно базової валюти)
  static Map<String, double> getExchangeRates() {
    final box = Hive.box(_settingsBox);
    final data = box.get('exchange_rates', defaultValue: {});

    // Hive може зберігати цілі числа як int, тому конвертуємо все в double надійно
    final map = (data as Map).cast<String, dynamic>();
    return map.map((key, value) => MapEntry(key, (value as num).toDouble()));
  }

  static Future<void> saveExchangeRates(Map<String, double> rates) async {
    await Hive.box(_settingsBox).put('exchange_rates', rates);
  }

  // 4. Час останнього оновлення курсів
  static DateTime? getLastRatesUpdateTime() {
    final ms = Hive.box(_settingsBox).get('last_rates_update');
    if (ms == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(ms);
  }

  static Future<void> setLastRatesUpdateTime(DateTime date) async {
    await Hive.box(
      _settingsBox,
    ).put('last_rates_update', date.millisecondsSinceEpoch);
  }

  // ==========================================

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
    final map = {for (var c in categories) c.id: c};
    await box.putAll(map);
  }

  static Future<void> saveCategory(Category category) async {
    final box = Hive.box(_categoriesBox);
    await box.put(category.id, category);
  }

  static Future<void> removeCategory(String id) async {
    final box = Hive.box(_categoriesBox);
    await box.delete(id);
  }

  static Future<List<Category>> loadCategories() async {
    try {
      final box = Hive.box(_categoriesBox);
      if (box.isEmpty) return [];

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

  // --- ІГНОРОВАНІ ПІДПИСКИ ---
  static List<String> getIgnoredSubscriptions() {
    final box = Hive.box(_settingsBox);
    final data = box.get('ignored_subs', defaultValue: []);
    return (data as List).cast<String>();
  }

  static Future<void> saveIgnoredSubscriptions(List<String> ids) async {
    await Hive.box(_settingsBox).put('ignored_subs', ids);
  }
}
