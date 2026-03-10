import 'package:flutter/material.dart';
import '../models/category_model.dart';
import '../models/transaction_model.dart';
import '../services/storage_service.dart';
import 'category_provider.dart';

class TransactionProvider extends ChangeNotifier {
  CategoryProvider? _catProv; // Посилання на провайдер категорій

  // ДОДАНО: Прапорець для синхронізації при старті додатку
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

  // ВИПРАВЛЕНО: Синхронізація з CategoryProvider
  void updateDependencies(CategoryProvider catProv) {
    _catProv = catProv;

    // Перевіряємо, чи обидва провайдери завантажили дані, щоб зробити перший перерахунок
    if (!isLoading && !catProv.isLoading && !_isInitialRecalculationDone) {
      _isInitialRecalculationDone = true;
      _catProv?.recalculateMonthTotals(history, selectedMonth);
    }
  }

  bool get isCurrentMonth {
    final now = DateTime.now();
    return selectedMonth.year == now.year && selectedMonth.month == now.month;
  }

  // ВИПРАВЛЕНО: Перевірка на завершення завантаження
  Future<void> loadHistory() async {
    history = await StorageService.loadHistory();
    history.sort((a, b) => b.date.compareTo(a.date));
    isLoading = false;

    // Якщо категоріям вдалося завантажитися швидше за історію
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

  // ДОДАНО: Безпечний метод, який оновлює постійний баланс у Hive ТІЛЬКИ для Рахунків
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
    DateTime date,
  ) {
    if (source.type == CategoryType.account) {
      _catProv?.updateCategoryAmount(source.id, -amount);
    }
    if (target.type == CategoryType.account) {
      _catProv?.updateCategoryAmount(target.id, amount);
    }

    final newTx = Transaction(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      fromId: source.id,
      toId: target.id,
      title: target.name,
      amount: amount,
      date: date,
    );

    addTransactionDirectly(newTx);
  }

  // ВИПРАВЛЕНО: Використання безпечного методу _updateAccountBalance
  void editTransaction(Transaction oldT, double newAmount, DateTime newDate) {
    // Скасовуємо стару транзакцію (ТІЛЬКИ для рахунків)
    _updateAccountBalance(oldT.fromId, oldT.amount);
    _updateAccountBalance(oldT.toId, -oldT.amount);

    // Оновлюємо дані транзакції
    oldT.amount = newAmount;
    oldT.date = newDate;

    // Застосовуємо нові дані (ТІЛЬКИ для рахунків)
    _updateAccountBalance(oldT.fromId, -oldT.amount);
    _updateAccountBalance(oldT.toId, oldT.amount);

    StorageService.saveTransaction(oldT);
    history.sort((a, b) => b.date.compareTo(a.date));
    _catProv?.recalculateMonthTotals(history, selectedMonth);
    notifyListeners();
  }

  // ВИПРАВЛЕНО: Використання безпечного методу _updateAccountBalance
  void deleteTransaction(Transaction t) {
    // Скасовуємо вплив транзакції на баланс (ТІЛЬКИ для рахунків)
    _updateAccountBalance(t.fromId, t.amount);
    _updateAccountBalance(t.toId, -t.amount);

    history.removeWhere((item) => item.id == t.id);
    StorageService.removeTransaction(t.id);

    _catProv?.recalculateMonthTotals(history, selectedMonth);
    notifyListeners();
  }

  // Допоміжний метод (також використовується для авто-платежів)
  void addTransactionDirectly(Transaction tx) {
    history.insert(0, tx);
    history.sort((a, b) => b.date.compareTo(a.date));
    StorageService.saveTransaction(tx);
    _catProv?.recalculateMonthTotals(history, selectedMonth);
    notifyListeners();
  }
}
