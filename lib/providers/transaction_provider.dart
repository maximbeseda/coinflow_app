import 'package:flutter/material.dart';
import '../models/category_model.dart';
import '../models/transaction_model.dart';
import '../services/storage_service.dart';
import 'category_provider.dart';
import 'settings_provider.dart';

class TransactionProvider extends ChangeNotifier {
  CategoryProvider? _catProv;
  SettingsProvider? _settingsProv;
  String? _lastKnownBaseCurrency;

  List<Transaction> history = [];
  DateTime selectedMonth = DateTime(
    DateTime.now().year,
    DateTime.now().month,
    1,
  );
  bool isLoading = true;
  bool isMigrating = false;

  TransactionProvider() {
    loadHistory();
  }

  void updateDependencies(
    CategoryProvider catProv,
    SettingsProvider settingsProv,
  ) {
    _catProv = catProv;
    _settingsProv = settingsProv;

    if (_settingsProv != null) {
      final currentBase = _settingsProv!.baseCurrency;

      if (_lastKnownBaseCurrency != null &&
          _lastKnownBaseCurrency != currentBase) {
        _migrateCurrentMonthBaseCurrency(currentBase);
      }
      _lastKnownBaseCurrency = currentBase;
    }

    if (!isLoading && !catProv.isLoading && _settingsProv != null) {
      notifyListeners();
    }
  }

  bool get isCurrentMonth {
    final now = DateTime.now();
    return selectedMonth.year == now.year && selectedMonth.month == now.month;
  }

  Future<void> loadHistory() async {
    final loadedHistory = await StorageService.loadHistory();
    loadedHistory.sort((a, b) => b.date.compareTo(a.date));
    history = loadedHistory;
    isLoading = false;
    notifyListeners();
  }

  void changeMonth(int offset) {
    selectedMonth = DateTime(
      selectedMonth.year,
      selectedMonth.month + offset,
      1,
    );
    notifyListeners();
  }

  void setMonth(DateTime newMonth) {
    selectedMonth = DateTime(newMonth.year, newMonth.month, 1);
    notifyListeners();
  }

  // =======================================================
  // ВНУТРІШНІЙ МЕТОД: Підрахунок базової суми (ТЕПЕР В INT)
  // =======================================================
  // 👇 ЗМІНЕНО: Повертає int, приймає int
  int _calculateBaseAmount(
    int amount,
    String currency,
    int? targetAmount,
    String? targetCurrency,
    String baseCur,
  ) {
    if (currency == baseCur) return amount;
    if (targetCurrency == baseCur && targetAmount != null) return targetAmount;

    double fromRate = _settingsProv?.exchangeRates[currency] ?? 1.0;
    double toRate = _settingsProv?.exchangeRates[baseCur] ?? 1.0;

    if (fromRate == 0) fromRate = 1.0;

    // 👇 ПРАВИЛЬНА МАТЕМАТИКА: множимо int на double і округлюємо до найближчого цілого (копійки)
    return (amount * (toRate / fromRate)).round();
  }

  // 👇 ЗМІНЕНО: delta тепер int
  void _updateAccountBalance(String categoryId, int delta) {
    if (_catProv == null) return;
    final category = _catProv!.allCategoriesList
        .where((c) => c.id == categoryId)
        .firstOrNull;

    if (category != null && category.type == CategoryType.account) {
      _catProv!.updateCategoryAmount(categoryId, delta);
    }
  }

  // =======================================================
  // ДОДАВАННЯ ТА РЕДАГУВАННЯ ТРАНЗАКЦІЙ
  // =======================================================
  void addTransactionDirectly(Transaction tx) {
    if (_settingsProv == null) return;
    final currentBase = _settingsProv!.baseCurrency;

    tx.baseCurrency = currentBase;
    tx.baseAmount = _calculateBaseAmount(
      tx.amount,
      tx.currency,
      tx.targetAmount,
      tx.targetCurrency,
      currentBase,
    );

    history.add(tx);
    StorageService.saveHistory(history);
    notifyListeners();
  }

  void addTransfer(
    Category source,
    Category target,
    int amount, // 👇 ЗМІНЕНО на int
    DateTime date, {
    int? targetAmount, // 👇 ЗМІНЕНО на int?
  }) {
    if (source.type == CategoryType.account) {
      _catProv?.updateCategoryAmount(source.id, -amount);
    }
    if (target.type == CategoryType.account) {
      _catProv?.updateCategoryAmount(target.id, targetAmount ?? amount);
    }

    final currentBase = _settingsProv?.baseCurrency ?? 'UAH';
    final baseAmt = _calculateBaseAmount(
      amount,
      source.currency,
      targetAmount,
      targetAmount != null ? target.currency : null,
      currentBase,
    );

    final newTx = Transaction(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      fromId: source.id,
      toId: target.id,
      title: target.name,
      amount: amount,
      date: date,
      currency: source.currency,
      targetAmount: targetAmount,
      targetCurrency: targetAmount != null ? target.currency : null,
      baseAmount: baseAmt,
      baseCurrency: currentBase,
    );

    history.add(newTx);
    StorageService.saveHistory(history);
    notifyListeners();
  }

  void editTransaction(
    Transaction oldT,
    int newAmount, // 👇 ЗМІНЕНО на int
    DateTime newDate, {
    int? newTargetAmount, // 👇 ЗМІНЕНО на int?
  }) {
    _updateAccountBalance(oldT.fromId, oldT.amount);
    _updateAccountBalance(oldT.toId, -(oldT.targetAmount ?? oldT.amount));

    final int previousAmount = oldT.amount; // 👇 ЗМІНЕНО на int
    oldT.amount = newAmount;
    oldT.date = newDate;

    if (newTargetAmount != null) {
      oldT.targetAmount = newTargetAmount;
    } else if (oldT.targetAmount != null && previousAmount > 0) {
      // 👇 ЗМІНЕНО: розрахунок через double-коефіцієнт з фінальним round()
      oldT.targetAmount = (oldT.targetAmount! * (newAmount / previousAmount))
          .round();
    } else {
      oldT.targetAmount = newAmount;
    }

    _updateAccountBalance(oldT.fromId, -oldT.amount);
    _updateAccountBalance(oldT.toId, oldT.targetAmount ?? oldT.amount);

    if (previousAmount > 0) {
      // 👇 ЗМІНЕНО: точне масштабування базової суми
      oldT.baseAmount = (oldT.baseAmount * (newAmount / previousAmount))
          .round();
    } else {
      oldT.baseAmount = _calculateBaseAmount(
        newAmount,
        oldT.currency,
        oldT.targetAmount,
        oldT.targetCurrency,
        oldT.baseCurrency,
      );
    }

    StorageService.saveTransaction(oldT);
    history.sort((a, b) => b.date.compareTo(a.date));
    notifyListeners();
  }

  void deleteTransaction(Transaction t) {
    _updateAccountBalance(t.fromId, t.amount);
    _updateAccountBalance(t.toId, -(t.targetAmount ?? t.amount));

    history.removeWhere((item) => item.id == t.id);
    StorageService.removeTransaction(t.id);
    notifyListeners();
  }

  // =======================================================
  // МІГРАЦІЯ ПОТОЧНОГО МІСЯЦЯ (При зміні базової валюти)
  // =======================================================
  Future<void> _migrateCurrentMonthBaseCurrency(String newBase) async {
    final now = DateTime.now();
    final currentMonthTxs = history
        .where((tx) => tx.date.year == now.year && tx.date.month == now.month)
        .toList();

    if (currentMonthTxs.isEmpty) return;

    isMigrating = true;
    notifyListeners();

    for (var tx in currentMonthTxs) {
      if (tx.baseCurrency == newBase) continue;

      tx.baseAmount = _calculateBaseAmount(
        tx.amount,
        tx.currency,
        tx.targetAmount,
        tx.targetCurrency,
        newBase,
      );
      tx.baseCurrency = newBase;

      StorageService.saveTransaction(tx);
    }

    isMigrating = false;
    notifyListeners();
  }

  Future<void> clearAllTransactions() async {
    history.clear();
    await StorageService.saveHistory([]);
    notifyListeners();
  }
}
