import 'package:hive_flutter/hive_flutter.dart';
import 'package:drift/drift.dart' as drift;
import '../database/app_database.dart';

class StorageService {
  static const String _settingsBox = 'settings';

  // ==========================================
  // НАЛАШТУВАННЯ (Залишаються в Hive)
  // ==========================================

  static bool hasCompletedOnboarding() {
    return Hive.box(
      _settingsBox,
    ).get('has_completed_onboarding', defaultValue: false);
  }

  static Future<void> completeOnboarding() async {
    await Hive.box(_settingsBox).put('has_completed_onboarding', true);
  }

  static String getThemeId() {
    return Hive.box(
      _settingsBox,
    ).get('current_theme_id', defaultValue: 'light');
  }

  static Future<void> saveThemeId(String themeId) async {
    await Hive.box(_settingsBox).put('current_theme_id', themeId);
  }

  static String getBaseCurrency() {
    return Hive.box(_settingsBox).get('base_currency', defaultValue: 'UAH');
  }

  static Future<void> saveBaseCurrency(String code) async {
    await Hive.box(_settingsBox).put('base_currency', code);
  }

  static List<String> getSelectedCurrencies() {
    final list = Hive.box(
      _settingsBox,
    ).get('selected_currencies', defaultValue: <dynamic>['UAH', 'USD', 'EUR']);
    return List<String>.from(list);
  }

  static Future<void> setSelectedCurrencies(List<String> codes) async {
    await Hive.box(_settingsBox).put('selected_currencies', codes);
  }

  static Map<String, double> getExchangeRates() {
    final data = Hive.box(
      _settingsBox,
    ).get('exchange_rates', defaultValue: <dynamic, dynamic>{});
    return Map<String, double>.from(data);
  }

  static Future<void> saveExchangeRates(Map<String, double> rates) async {
    await Hive.box(_settingsBox).put('exchange_rates', rates);
  }

  static DateTime? getLastRatesUpdateTime() {
    final ms = Hive.box(_settingsBox).get('last_rates_update_time');
    if (ms == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(ms);
  }

  static Future<void> setLastRatesUpdateTime(DateTime time) async {
    await Hive.box(
      _settingsBox,
    ).put('last_rates_update_time', time.millisecondsSinceEpoch);
  }

  static Map<String, dynamic> getHistoricalRatesCache() {
    final data = Hive.box(
      _settingsBox,
    ).get('historical_rates_cache', defaultValue: <dynamic, dynamic>{});
    return Map<String, dynamic>.from(data);
  }

  static Future<void> saveHistoricalRatesCache(
    Map<String, dynamic> cache,
  ) async {
    await Hive.box(_settingsBox).put('historical_rates_cache', cache);
  }

  // ==========================================
  // ІГНОРОВАНІ ПІДПИСКИ
  // ==========================================
  static List<String> getIgnoredSubscriptions() {
    final list = Hive.box(
      _settingsBox,
    ).get('ignored_subscriptions', defaultValue: <dynamic>[]);
    return List<String>.from(list);
  }

  static Future<void> saveIgnoredSubscriptions(List<String> ids) async {
    await Hive.box(_settingsBox).put('ignored_subscriptions', ids);
  }

  // ==========================================
  // БІЗНЕС-ДАНІ (Drift SQLite)
  // ==========================================

  // --- КАТЕГОРІЇ ---
  static Future<List<Category>> loadCategories(AppDatabase db) async {
    return await db.select(db.categories).get();
  }

  static Future<void> saveCategory(AppDatabase db, Category category) async {
    await db
        .into(db.categories)
        .insert(category, mode: drift.InsertMode.replace);
  }

  static Future<void> saveCategories(
    AppDatabase db,
    List<Category> categoriesList,
  ) async {
    await db.batch((batch) {
      batch.insertAll(
        db.categories,
        categoriesList,
        mode: drift.InsertMode.replace,
      );
    });
  }

  static Future<void> deleteCategoryFromDb(AppDatabase db, String id) async {
    await (db.delete(db.categories)..where((t) => t.id.equals(id))).go();
  }

  // --- ТРАНЗАКЦІЇ ---
  static Future<List<Transaction>> loadHistory(AppDatabase db) async {
    return await db.select(db.transactions).get();
  }

  static Future<void> saveTransaction(AppDatabase db, Transaction tx) async {
    await db.into(db.transactions).insert(tx, mode: drift.InsertMode.replace);
  }

  static Future<void> saveHistory(AppDatabase db, List<Transaction> txs) async {
    await db.batch((batch) {
      batch.insertAll(db.transactions, txs, mode: drift.InsertMode.replace);
    });
  }

  static Future<void> removeTransaction(AppDatabase db, String id) async {
    await (db.delete(db.transactions)..where((t) => t.id.equals(id))).go();
  }

  // --- ПІДПИСКИ ---
  static Future<List<Subscription>> getSubscriptions(AppDatabase db) async {
    return await db.select(db.subscriptions).get();
  }

  static Future<void> saveSubscription(
    AppDatabase db,
    Subscription subscription,
  ) async {
    await db
        .into(db.subscriptions)
        .insert(subscription, mode: drift.InsertMode.replace);
  }

  static Future<void> deleteSubscription(AppDatabase db, String id) async {
    await (db.delete(db.subscriptions)..where((s) => s.id.equals(id))).go();
  }

  // ==========================================
  // HARD RESET (ПОВНЕ ОЧИЩЕННЯ БАЗИ ДАНИХ)
  // ==========================================
  static Future<void> wipeEntireDatabase(AppDatabase db) async {
    // Фізично видаляємо всі записи з таблиць
    await db.delete(db.transactions).go();
    await db.delete(db.categories).go();
    await db.delete(db.subscriptions).go();
  }
}
