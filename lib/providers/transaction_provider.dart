import 'package:flutter/material.dart';
import 'package:drift/drift.dart' as drift;
import '../database/app_database.dart';
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

    // Створюємо нову копію об'єкта з оновленими полями
    final updatedTx = tx.copyWith(
      baseCurrency: currentBase,
      baseAmount: _calculateBaseAmount(
        tx.amount,
        tx.currency,
        tx.targetAmount,
        tx.targetCurrency,
        currentBase,
      ),
    );

    // Додаємо оновлений об'єкт у список історії
    history.add(updatedTx);

    // Сортуємо історію, щоб нові транзакції були зверху
    history.sort((a, b) => b.date.compareTo(a.date));

    // Зберігаємо нову транзакцію в базу даних
    StorageService.saveTransaction(updatedTx);

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

    history.insert(0, newTx); // Додаємо на початок
    StorageService.saveTransaction(newTx); // Зберігаємо ТІЛЬКИ її
    notifyListeners();
  }

  void editTransaction(
    Transaction oldT,
    int newAmount,
    DateTime newDate, {
    int? newTargetAmount,
  }) {
    // 1. Повертаємо баланси до стану "до цієї транзакції"
    _updateAccountBalance(oldT.fromId, oldT.amount);
    _updateAccountBalance(oldT.toId, -(oldT.targetAmount ?? oldT.amount));

    final int previousAmount = oldT.amount;

    // 2. Вираховуємо нове значення targetAmount
    int finalTargetAmount;
    if (newTargetAmount != null) {
      finalTargetAmount = newTargetAmount;
    } else if (oldT.targetAmount != null && previousAmount > 0) {
      finalTargetAmount = (oldT.targetAmount! * (newAmount / previousAmount))
          .round();
    } else {
      finalTargetAmount = newAmount;
    }

    // 3. Вираховуємо нове значення baseAmount
    int finalBaseAmount;
    if (previousAmount > 0) {
      finalBaseAmount = (oldT.baseAmount * (newAmount / previousAmount))
          .round();
    } else {
      finalBaseAmount = _calculateBaseAmount(
        newAmount,
        oldT.currency,
        finalTargetAmount, // використовуємо вже нове значення
        oldT.targetCurrency,
        oldT.baseCurrency,
      );
    }

    // 4. Створюємо НОВИЙ об'єкт на основі старого
    final updatedT = oldT.copyWith(
      amount: newAmount,
      date: newDate,
      targetAmount: drift.Value(
        finalTargetAmount,
      ), // Drift використовує Value() для nullable полів у copyWith
      baseAmount: finalBaseAmount,
    );

    // 5. Оновлюємо баланси з новими значеннями
    _updateAccountBalance(updatedT.fromId, -updatedT.amount);
    _updateAccountBalance(
      updatedT.toId,
      updatedT.targetAmount ?? updatedT.amount,
    );

    // 6. Оновлюємо об'єкт у списку history та базі даних
    int index = history.indexWhere((t) => t.id == oldT.id);
    if (index != -1) {
      history[index] = updatedT;
    }

    StorageService.saveTransaction(updatedT);
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

    for (int i = 0; i < currentMonthTxs.length; i++) {
      var tx = currentMonthTxs[i];
      if (tx.baseCurrency == newBase) continue;

      // Створюємо оновлену копію транзакції
      tx = tx.copyWith(
        baseAmount: _calculateBaseAmount(
          tx.amount,
          tx.currency,
          tx.targetAmount,
          tx.targetCurrency,
          newBase,
        ),
        baseCurrency: newBase,
      );

      // Оновлюємо в масивах і зберігаємо
      currentMonthTxs[i] = tx;
      int mainIndex = history.indexWhere((t) => t.id == tx.id);
      if (mainIndex != -1) history[mainIndex] = tx;

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
