import 'package:flutter/material.dart';
import '../models/category_model.dart';
import '../models/transaction_model.dart';
import '../services/storage_service.dart';
import 'category_provider.dart';

class TransactionProvider extends ChangeNotifier {
  CategoryProvider? _catProv; // Посилання на провайдер категорій

  bool _isInitialRecalculationDone = false;

  List<Transaction> history = [];
  DateTime selectedMonth = DateTime(
    DateTime.now().year,
    DateTime.now().month,
    1,
  );
  bool isLoading = true;

  TransactionProvider() {
    loadHistory();
  }

  void updateDependencies(CategoryProvider catProv) {
    _catProv = catProv;

    if (!isLoading && !catProv.isLoading && !_isInitialRecalculationDone) {
      _isInitialRecalculationDone = true;
      _catProv?.recalculateMonthTotals(history, selectedMonth);
    }
  }

  bool get isCurrentMonth {
    final now = DateTime.now();
    return selectedMonth.year == now.year && selectedMonth.month == now.month;
  }

  Future<void> loadHistory() async {
    history = await StorageService.loadHistory();
    history.sort((a, b) => b.date.compareTo(a.date));
    isLoading = false;

    if (_catProv != null &&
        !_catProv!.isLoading &&
        !_isInitialRecalculationDone) {
      _isInitialRecalculationDone = true;
      _catProv?.recalculateMonthTotals(history, selectedMonth);
    }

    notifyListeners();
  }

  void changeMonth(int offset) {
    selectedMonth = DateTime(
      selectedMonth.year,
      selectedMonth.month + offset,
      1,
    );
    _catProv?.recalculateMonthTotals(history, selectedMonth);
    notifyListeners();
  }

  void setMonth(DateTime newMonth) {
    selectedMonth = DateTime(newMonth.year, newMonth.month, 1);
    _catProv?.recalculateMonthTotals(history, selectedMonth);
    notifyListeners();
  }

  void _updateAccountBalance(String categoryId, double delta) {
    if (_catProv == null) return;
    final category = _catProv!.allCategoriesList
        .where((c) => c.id == categoryId)
        .firstOrNull;

    if (category != null && category.type == CategoryType.account) {
      _catProv!.updateCategoryAmount(categoryId, delta);
    }
  }

  void addTransfer(
    Category source,
    Category target,
    double amount,
    DateTime date, {
    double? targetAmount, // ДОДАНО: Сума для цільового рахунку
  }) {
    if (source.type == CategoryType.account) {
      _catProv?.updateCategoryAmount(source.id, -amount);
    }
    if (target.type == CategoryType.account) {
      // ЗМІНЕНО: Використовуємо targetAmount, якщо він є
      _catProv?.updateCategoryAmount(target.id, targetAmount ?? amount);
    }

    final newTx = Transaction(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      fromId: source.id,
      toId: target.id,
      title: target.name,
      amount: amount,
      date: date,
      // ДОДАНО: Зберігаємо дані про валюти у транзакцію
      currency: source.currency,
      targetAmount: targetAmount,
      targetCurrency: targetAmount != null ? target.currency : null,
    );

    addTransactionDirectly(newTx);
  }

  void editTransaction(
    Transaction oldT,
    double newAmount,
    DateTime newDate, {
    double? newTargetAmount,
  }) {
    // 1. Скасовуємо стару транзакцію
    _updateAccountBalance(oldT.fromId, oldT.amount);
    _updateAccountBalance(oldT.toId, -(oldT.targetAmount ?? oldT.amount));

    // 2. Оновлюємо дані транзакції
    oldT.amount = newAmount;
    oldT.date = newDate;

    // ДОДАНО: Якщо ми передали нову цільову суму (з розумного діалогу) - зберігаємо її
    if (newTargetAmount != null) {
      oldT.targetAmount = newTargetAmount;
    } else if (oldT.targetAmount != null && oldT.amount > 0) {
      // Резервний варіант: пропорційна зміна (якщо колись викличемо без newTargetAmount)
      oldT.targetAmount = oldT.targetAmount! * (newAmount / oldT.amount);
    }

    // 3. Застосовуємо нові дані
    _updateAccountBalance(oldT.fromId, -oldT.amount);
    _updateAccountBalance(oldT.toId, oldT.targetAmount ?? oldT.amount);

    StorageService.saveTransaction(oldT);
    history.sort((a, b) => b.date.compareTo(a.date));
    _catProv?.recalculateMonthTotals(history, selectedMonth);
    notifyListeners();
  }

  void deleteTransaction(Transaction t) {
    // Скасовуємо вплив транзакції на баланс
    _updateAccountBalance(t.fromId, t.amount);
    // ЗМІНЕНО: Скасовуємо правильну цільову суму
    _updateAccountBalance(t.toId, -(t.targetAmount ?? t.amount));

    history.removeWhere((item) => item.id == t.id);
    StorageService.removeTransaction(t.id);

    _catProv?.recalculateMonthTotals(history, selectedMonth);
    notifyListeners();
  }

  void addTransactionDirectly(Transaction tx) {
    history.insert(0, tx);
    history.sort((a, b) => b.date.compareTo(a.date));
    StorageService.saveTransaction(tx);
    _catProv?.recalculateMonthTotals(history, selectedMonth);
    notifyListeners();
  }
}
