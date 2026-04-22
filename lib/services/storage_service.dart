import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:drift/drift.dart' as drift;
import '../database/app_database.dart';

class StorageService {
  final SharedPreferences _prefs;

  // Конструктор
  StorageService(this._prefs);

  // ==========================================
  // НАЛАШТУВАННЯ (SharedPreferences)
  // ==========================================

  bool hasCompletedOnboarding() {
    return _prefs.getBool('has_completed_onboarding') ?? false;
  }

  Future<void> completeOnboarding() async {
    await _prefs.setBool('has_completed_onboarding', true);
  }

  String getThemeId() {
    return _prefs.getString('current_theme_id') ?? 'light';
  }

  Future<void> saveThemeId(String themeId) async {
    await _prefs.setString('current_theme_id', themeId);
  }

  String getBaseCurrency() {
    return _prefs.getString('base_currency') ?? 'UAH';
  }

  Future<void> saveBaseCurrency(String code) async {
    await _prefs.setString('base_currency', code);
  }

  List<String> getSelectedCurrencies() {
    return _prefs.getStringList('selected_currencies') ?? ['UAH', 'USD', 'EUR'];
  }

  Future<void> setSelectedCurrencies(List<String> codes) async {
    await _prefs.setStringList('selected_currencies', codes);
  }

  Map<String, double> getExchangeRates() {
    final str = _prefs.getString('exchange_rates');
    if (str == null) return {};
    final decoded = jsonDecode(str) as Map<String, dynamic>;
    return decoded.map(
      (key, value) => MapEntry(key, (value as num).toDouble()),
    );
  }

  Future<void> saveExchangeRates(Map<String, double> rates) async {
    await _prefs.setString('exchange_rates', jsonEncode(rates));
  }

  DateTime? getLastRatesUpdateTime() {
    final ms = _prefs.getInt('last_rates_update_time');
    if (ms == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(ms);
  }

  Future<void> setLastRatesUpdateTime(DateTime time) async {
    await _prefs.setInt('last_rates_update_time', time.millisecondsSinceEpoch);
  }

  Map<String, dynamic> getHistoricalRatesCache() {
    final str = _prefs.getString('historical_rates_cache');
    if (str == null) return {};
    return jsonDecode(str) as Map<String, dynamic>;
  }

  Future<void> saveHistoricalRatesCache(Map<String, dynamic> cache) async {
    await _prefs.setString('historical_rates_cache', jsonEncode(cache));
  }

  // ==========================================
  // ІГНОРОВАНІ ПІДПИСКИ
  // ==========================================
  List<String> getIgnoredSubscriptions() {
    return _prefs.getStringList('ignored_subscriptions') ?? [];
  }

  Future<void> saveIgnoredSubscriptions(List<String> ids) async {
    await _prefs.setStringList('ignored_subscriptions', ids);
  }

  // ==========================================
  // БІЗНЕС-ДАНІ (Drift SQLite) - СТАТИЧНІ МЕТОДИ
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

  static Future<void> deleteAllTransactions(AppDatabase db) async {
    await db.delete(db.transactions).go();
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
  // HARD RESET
  // ==========================================
  static Future<void> wipeEntireDatabase(AppDatabase db) async {
    await db.delete(db.transactions).go();
    await db.delete(db.categories).go();
    await db.delete(db.subscriptions).go();
  }
}
