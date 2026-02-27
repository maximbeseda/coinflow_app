import 'package:flutter/material.dart';
import '../models/category_model.dart';
import '../models/transaction_model.dart';
import '../services/storage_service.dart';

class FinanceProvider extends ChangeNotifier {
  List<Category> incomes = [];
  List<Category> accounts = [];
  List<Category> expenses = [];
  List<Transaction> history = [];

  DateTime selectedMonth = DateTime(
    DateTime.now().year,
    DateTime.now().month,
    1,
  );
  bool isLoading = true;

  bool get isCurrentMonth {
    final now = DateTime.now();
    return selectedMonth.year == now.year && selectedMonth.month == now.month;
  }

  FinanceProvider() {
    loadData();
  }

  Future<void> loadData() async {
    final savedCats = await StorageService.loadCategories();

    if (savedCats.isNotEmpty) {
      // ЗМІНЕНО: Фільтруємо безпечно через Enum!
      incomes = savedCats.where((c) => c.type == CategoryType.income).toList();
      accounts = savedCats
          .where((c) => c.type == CategoryType.account)
          .toList();
      expenses = savedCats
          .where((c) => c.type == CategoryType.expense)
          .toList();
    }

    final loadedHistory = await StorageService.loadHistory();
    history = loadedHistory;
    history.sort((a, b) => b.date.compareTo(a.date));

    _recalculateMonthTotals();
    isLoading = false;
    notifyListeners();
  }

  void changeMonth(int offset) {
    selectedMonth = DateTime(
      selectedMonth.year,
      selectedMonth.month + offset,
      1,
    );
    // БІЛЬШЕ НЕ ВИКЛИКАЄМО _recalculateMonthTotals();
    notifyListeners();
  }

  void setMonth(DateTime newMonth) {
    selectedMonth = DateTime(newMonth.year, newMonth.month, 1);
    // БІЛЬШЕ НЕ ВИКЛИКАЄМО _recalculateMonthTotals();
    notifyListeners();
  }

  // ТЕПЕР РАХУЄМО ТІЛЬКИ ДЛЯ ГОЛОВНОГО ЕКРАНУ (ЗАВЖДИ ПОТОЧНИЙ МІСЯЦЬ)
  void _recalculateMonthTotals() {
    final now = DateTime.now(); // Жорстко фіксуємо поточний час

    for (var inc in incomes) {
      inc.amount = 0.0;
    }
    for (var exp in expenses) {
      exp.amount = 0.0;
    }

    final currentMonthHistory = history
        .where((t) => t.date.year == now.year && t.date.month == now.month)
        .toList();

    final allCategories = [...incomes, ...accounts, ...expenses];

    for (var t in currentMonthHistory) {
      try {
        final fromCat = allCategories.firstWhere((c) => c.id == t.fromId);
        if (fromCat.type == CategoryType.income) {
          incomes.firstWhere((c) => c.id == t.fromId).amount += t.amount;
        }
      } catch (_) {}

      try {
        final toCat = allCategories.firstWhere((c) => c.id == t.toId);
        if (toCat.type == CategoryType.expense) {
          expenses.firstWhere((c) => c.id == t.toId).amount += t.amount;
        }
      } catch (_) {}
    }
  }

  void addTransfer(
    Category source,
    Category target,
    double amount,
    DateTime date,
  ) {
    if (source.type == CategoryType.account) source.amount -= amount;
    if (target.type == CategoryType.account) target.amount += amount;

    final newTx = Transaction(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      fromId: source.id,
      toId: target.id,
      title: target.name,
      amount: amount,
      date: date,
    );

    history.insert(0, newTx);
    history.sort((a, b) => b.date.compareTo(a.date));

    _recalculateMonthTotals();
    StorageService.saveTransaction(newTx);
    StorageService.saveCategory(source);
    StorageService.saveCategory(target);
    notifyListeners();
  }

  void editTransaction(Transaction oldT, double newAmount, DateTime newDate) {
    final all = [...incomes, ...accounts, ...expenses];
    try {
      final src = all.firstWhere((c) => c.id == oldT.fromId);
      final dst = all.firstWhere((c) => c.id == oldT.toId);

      if (src.type == CategoryType.account) src.amount += oldT.amount;
      if (dst.type == CategoryType.account) dst.amount -= oldT.amount;

      oldT.amount = newAmount;
      oldT.date = newDate;

      if (src.type == CategoryType.account) src.amount -= oldT.amount;
      if (dst.type == CategoryType.account) dst.amount += oldT.amount;

      history.sort((a, b) => b.date.compareTo(a.date));
      _recalculateMonthTotals();

      StorageService.saveTransaction(oldT);
      StorageService.saveCategory(src);
      StorageService.saveCategory(dst);
      notifyListeners();
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  void deleteTransaction(Transaction t) {
    final all = [...incomes, ...accounts, ...expenses];
    try {
      final src = all.firstWhere((c) => c.id == t.fromId);
      final dst = all.firstWhere((c) => c.id == t.toId);

      if (src.type == CategoryType.account) src.amount += t.amount;
      if (dst.type == CategoryType.account) dst.amount -= t.amount;

      StorageService.saveCategory(src);
      StorageService.saveCategory(dst);
    } catch (e) {
      debugPrint(e.toString());
    }

    history.removeWhere((item) => item.id == t.id);
    _recalculateMonthTotals();
    StorageService.removeTransaction(t.id);
    notifyListeners();
  }

  // ЗМІНЕНО: Більше не передаємо String type. Категорія сама знає свій тип!
  void addOrUpdateCategory(Category cat) {
    List<Category> targetList;

    if (cat.type == CategoryType.income) {
      targetList = incomes;
    } else if (cat.type == CategoryType.account) {
      targetList = accounts;
    } else {
      targetList = expenses;
    }

    int index = targetList.indexWhere((c) => c.id == cat.id);

    if (index == -1) {
      targetList.add(cat);
    } else {
      targetList[index] = cat;
    }

    StorageService.saveCategory(cat);
    notifyListeners();
  }

  // ЗМІНЕНО: Прибрали String type
  void deleteCategory(Category cat) {
    if (cat.type == CategoryType.income) {
      incomes.remove(cat);
    } else if (cat.type == CategoryType.account) {
      accounts.remove(cat);
    } else {
      expenses.remove(cat);
    }

    final relatedTransactions = history
        .where((t) => t.fromId == cat.id || t.toId == cat.id)
        .toList();
    for (var t in relatedTransactions) {
      StorageService.removeTransaction(t.id);
    }
    history.removeWhere((t) => t.fromId == cat.id || t.toId == cat.id);

    _recalculateMonthTotals();
    StorageService.removeCategory(cat.id);
    notifyListeners();
  }

  void reorderCategories(Category dragged, Category target) {
    // ЗМІНЕНО: Перевірка через Enum замість підрядків
    if (dragged.type != target.type) return;

    List<Category> targetList;
    if (dragged.type == CategoryType.income) {
      targetList = incomes;
    } else if (dragged.type == CategoryType.account) {
      targetList = accounts;
    } else {
      targetList = expenses;
    }

    int oldIndex = targetList.indexWhere((c) => c.id == dragged.id);
    int newIndex = targetList.indexWhere((c) => c.id == target.id);

    if (oldIndex != -1 && newIndex != -1 && oldIndex != newIndex) {
      final item = targetList.removeAt(oldIndex);
      targetList.insert(newIndex, item);

      StorageService.saveCategories([...incomes, ...accounts, ...expenses]);
      notifyListeners();
    }
  }
}
