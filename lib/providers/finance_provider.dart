import 'package:flutter/material.dart';
import '../models/category_model.dart';
import '../models/transaction_model.dart';
import '../services/storage_service.dart';

class FinanceProvider extends ChangeNotifier {
  List<Category> incomes = [];
  List<Category> accounts = [];
  List<Category> expenses = [];
  List<Transaction> history = [];

  bool isLoading = true;

  FinanceProvider() {
    loadData();
  }

  // --- ЗАВАНТАЖЕННЯ ДАНИХ ---
  Future<void> loadData() async {
    final savedCats = await StorageService.loadCategories();

    if (savedCats.isNotEmpty) {
      incomes = savedCats.where((c) => c.id.startsWith("inc")).toList();
      accounts = savedCats.where((c) => c.id.startsWith("acc")).toList();
      expenses = savedCats.where((c) => c.id.startsWith("exp")).toList();
    }

    for (var c in accounts) {
      c.amount = await StorageService.loadAmount(c.id) ?? c.amount;
    }

    final loadedHistory = await StorageService.loadHistory();
    history = loadedHistory;
    history.sort((a, b) => b.date.compareTo(a.date));

    _recalculateMonthTotals();

    isLoading = false;
    notifyListeners(); // Оновлюємо UI
  }

  // --- РОЗУМНИЙ ПІДРАХУНОК ---
  void _recalculateMonthTotals() {
    final now = DateTime.now();

    for (var inc in incomes) {
      inc.amount = 0.0;
    }
    for (var exp in expenses) {
      exp.amount = 0.0;
    }

    final currentMonthHistory = history
        .where((t) => t.date.year == now.year && t.date.month == now.month)
        .toList();

    for (var t in currentMonthHistory) {
      if (t.fromId.startsWith("inc")) {
        try {
          incomes.firstWhere((c) => c.id == t.fromId).amount += t.amount;
        } catch (_) {}
      }
      if (t.toId.startsWith("exp")) {
        try {
          expenses.firstWhere((c) => c.id == t.toId).amount += t.amount;
        } catch (_) {}
      }
    }
  }

  // --- ЗБЕРЕЖЕННЯ ---
  Future<void> _saveAll() async {
    await StorageService.saveHistory(history);
    await StorageService.saveCategories([...incomes, ...accounts, ...expenses]);

    for (var c in accounts) {
      await StorageService.saveAmount(c.id, c.amount);
    }
  }

  // --- ДОДАВАННЯ ТРАНЗАКЦІЇ ---
  void addTransfer(
    Category source,
    Category target,
    double amount,
    DateTime date,
  ) {
    if (source.id.startsWith("acc")) source.amount -= amount;
    if (target.id.startsWith("acc")) target.amount += amount;

    history.insert(
      0,
      Transaction(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        fromId: source.id,
        toId: target.id,
        title: target.name,
        amount: amount,
        date: date,
      ),
    );
    history.sort((a, b) => b.date.compareTo(a.date));

    _recalculateMonthTotals();
    _saveAll();
    notifyListeners();
  }

  // --- РЕДАГУВАННЯ ТРАНЗАКЦІЇ ---
  void editTransaction(Transaction oldT, double newAmount, DateTime newDate) {
    final all = [...incomes, ...accounts, ...expenses];
    try {
      final src = all.firstWhere((c) => c.id == oldT.fromId);
      final dst = all.firstWhere((c) => c.id == oldT.toId);

      // Відкат
      if (src.id.startsWith("acc")) src.amount += oldT.amount;
      if (dst.id.startsWith("acc")) dst.amount -= oldT.amount;

      oldT.amount = newAmount;
      oldT.date = newDate;

      // Нові значення
      if (src.id.startsWith("acc")) src.amount -= oldT.amount;
      if (dst.id.startsWith("acc")) dst.amount += oldT.amount;

      history.sort((a, b) => b.date.compareTo(a.date));
      _recalculateMonthTotals();
      _saveAll();
      notifyListeners();
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  // --- ВИДАЛЕННЯ ТРАНЗАКЦІЇ ---
  void deleteTransaction(Transaction t) {
    final all = [...incomes, ...accounts, ...expenses];
    try {
      final src = all.firstWhere((c) => c.id == t.fromId);
      final dst = all.firstWhere((c) => c.id == t.toId);

      if (src.id.startsWith("acc")) src.amount += t.amount;
      if (dst.id.startsWith("acc")) dst.amount -= t.amount;
    } catch (e) {
      debugPrint(e.toString());
    }
    history.removeWhere((item) => item.id == t.id);

    _recalculateMonthTotals();
    _saveAll();
    notifyListeners();
  }

  // --- ДОДАВАННЯ АБО ОНОВЛЕННЯ КАТЕГОРІЇ ---
  void addOrUpdateCategory(Category cat, String type) {
    List<Category> targetList;

    // 1. Визначаємо, з яким списком працюємо
    if (type == 'inc') {
      targetList = incomes;
    } else if (type == 'acc') {
      targetList = accounts;
    } else {
      targetList = expenses;
    }

    // 2. Шукаємо, чи є вже така монетка у списку
    int index = targetList.indexWhere((c) => c.id == cat.id);

    if (index == -1) {
      // Якщо не знайшли (це нова монетка) — додаємо в кінець
      targetList.add(cat);
    } else {
      // Якщо знайшли (редагування) — просто оновлюємо її на тому ж місці
      targetList[index] = cat;
    }

    _saveAll();
    notifyListeners();
  }

  // --- ВИДАЛЕННЯ КАТЕГОРІЇ ---
  void deleteCategory(Category cat, String type) {
    if (type == 'inc') {
      incomes.remove(cat);
    } else if (type == 'acc') {
      accounts.remove(cat);
    } else if (type == 'exp') {
      expenses.remove(cat);
    }

    // Також видаляємо всю історію, пов'язану з цією категорією
    history.removeWhere((t) => t.fromId == cat.id || t.toId == cat.id);

    _recalculateMonthTotals();
    _saveAll();
    notifyListeners();
  }

  // --- ЗМІНА МІСЦЯМИ (СОРТУВАННЯ НА ЛЬОТУ ЗІ ЗСУВОМ - ВИПРАВЛЕНО) ---
  // --- ЗМІНА МІСЦЯМИ (СОРТУВАННЯ НА ЛЬОТУ) ---
  void reorderCategories(Category dragged, Category target) {
    if (dragged.id.substring(0, 3) != target.id.substring(0, 3)) return;

    List<Category> targetList;
    if (dragged.id.startsWith('inc')) {
      targetList = incomes;
    } else if (dragged.id.startsWith('acc')) {
      targetList = accounts;
    } else {
      targetList = expenses;
    }

    int oldIndex = targetList.indexWhere((c) => c.id == dragged.id);
    int newIndex = targetList.indexWhere((c) => c.id == target.id);

    if (oldIndex != -1 && newIndex != -1 && oldIndex != newIndex) {
      final item = targetList.removeAt(oldIndex);
      // Більше ніяких newIndex-- ! Вставляємо рівно туди, куди вказав користувач
      targetList.insert(newIndex, item);

      _saveAll();
      notifyListeners();
    }
  }
}
