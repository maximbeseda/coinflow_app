import 'package:hive_flutter/hive_flutter.dart';
import 'package:drift/drift.dart' as drift;
import '../database/app_database.dart'; // Наша нова база
import '../main.dart'; // Тут живе наша глобальна змінна appDb

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
  // ІГНОРОВАНІ ПІДПИСКИ (Тимчасовий стан UI)
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

  static Future<void> clearIgnoredSubscriptions() async {
    await Hive.box(_settingsBox).put('ignored_subscriptions', <String>[]);
  }

  // ==========================================
  // БІЗНЕС-ДАНІ (Тепер працюють через Drift SQLite!)
  // ==========================================

  // --- КАТЕГОРІЇ ---
  static Future<List<Category>> loadCategories() async {
    return await appDb.select(appDb.categories).get();
  }

  static Future<void> saveCategory(Category category) async {
    await appDb
        .into(appDb.categories)
        .insert(category, mode: drift.InsertMode.replace);
  }

  static Future<void> saveCategories(List<Category> categoriesList) async {
    await appDb.batch((batch) {
      batch.insertAll(
        appDb.categories,
        categoriesList,
        mode: drift.InsertMode.replace,
      );
    });
  }

  // --- ТРАНЗАКЦІЇ ---
  static Future<List<Transaction>> loadHistory() async {
    return await appDb.select(appDb.transactions).get();
  }

  static Future<void> saveTransaction(Transaction tx) async {
    await appDb
        .into(appDb.transactions)
        .insert(tx, mode: drift.InsertMode.replace);
  }

  static Future<void> saveHistory(List<Transaction> txs) async {
    await appDb.batch((batch) {
      batch.insertAll(appDb.transactions, txs, mode: drift.InsertMode.replace);
    });
  }

  static Future<void> removeTransaction(String id) async {
    await (appDb.delete(
      appDb.transactions,
    )..where((t) => t.id.equals(id))).go();
  }

  // --- ПІДПИСКИ ---
  static Future<List<Subscription>> getSubscriptions() async {
    return await appDb.select(appDb.subscriptions).get();
  }

  static Future<void> saveSubscription(Subscription subscription) async {
    await appDb
        .into(appDb.subscriptions)
        .insert(subscription, mode: drift.InsertMode.replace);
  }

  static Future<void> deleteSubscription(String id) async {
    await (appDb.delete(
      appDb.subscriptions,
    )..where((s) => s.id.equals(id))).go();
  }

  // --- ОЧИЩЕННЯ ТА ІНШЕ ---
  static Future<void> clearAll() async {
    await appDb.delete(appDb.transactions).go();
    await appDb.delete(appDb.categories).go();
    await appDb.delete(appDb.subscriptions).go();
  }

  static Future<void> runMigrationsIfNeeded() async {
    // Більше не потрібна тут, логіка перенесена в MigrationService
  }

  static Future<void> syncSystemDesign() async {
    // Поки залишаємо пустою
  }
}
