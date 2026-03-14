import 'package:flutter/material.dart';
import '../models/category_model.dart';
import '../models/transaction_model.dart';
import '../services/storage_service.dart';

class CategoryProvider extends ChangeNotifier {
  List<Category> incomes = [];
  List<Category> accounts = [];
  List<Category> expenses = [];
  List<Category> archivedCategories = [];

  bool isLoading = true;

  List<Category> get allCategoriesList => [
    ...incomes,
    ...accounts,
    ...expenses,
    ...archivedCategories,
  ];

  CategoryProvider() {
    loadCategories();
  }

  Future<void> loadCategories() async {
    final savedCats = await StorageService.loadCategories();

    if (savedCats.isNotEmpty) {
      incomes = savedCats
          .where((c) => c.type == CategoryType.income && !c.isArchived)
          .toList();
      accounts = savedCats
          .where((c) => c.type == CategoryType.account && !c.isArchived)
          .toList();
      expenses = savedCats
          .where((c) => c.type == CategoryType.expense && !c.isArchived)
          .toList();
      archivedCategories = savedCats.where((c) => c.isArchived).toList();
    }

    isLoading = false;
    notifyListeners();
  }

  // Оновлення балансу конкретної категорії
  void updateCategoryAmount(String id, double delta) {
    final all = allCategoriesList;
    final index = all.indexWhere((c) => c.id == id);
    if (index == -1) return;

    final category = all[index];
    final updatedCategory = category.copyWith(amount: category.amount + delta);

    if (updatedCategory.type == CategoryType.income) {
      int idx = incomes.indexWhere((c) => c.id == id);
      if (idx != -1) incomes[idx] = updatedCategory;
    } else if (updatedCategory.type == CategoryType.account) {
      int idx = accounts.indexWhere((c) => c.id == id);
      if (idx != -1) accounts[idx] = updatedCategory;
    } else {
      int idx = expenses.indexWhere((c) => c.id == id);
      if (idx != -1) expenses[idx] = updatedCategory;
    }

    StorageService.saveCategory(updatedCategory);
    notifyListeners();
  }

  // Перерахунок сумарних витрат/доходів за поточний місяць (викликається з транзакцій)
  void recalculateMonthTotals(
    List<Transaction> history,
    DateTime selectedMonth,
  ) {
    incomes = incomes.map((c) => c.copyWith(amount: 0.0)).toList();
    expenses = expenses.map((c) => c.copyWith(amount: 0.0)).toList();

    final currentMonthHistory = history
        .where(
          (t) =>
              t.date.year == selectedMonth.year &&
              t.date.month == selectedMonth.month,
        )
        .toList();

    for (var t in currentMonthHistory) {
      int incIdx = incomes.indexWhere((c) => c.id == t.fromId);
      if (incIdx != -1) {
        // Доходи завжди є джерелом (fromId), тому для них беремо базовий amount
        incomes[incIdx] = incomes[incIdx].copyWith(
          amount: incomes[incIdx].amount + t.amount,
        );
      }

      int expIdx = expenses.indexWhere((c) => c.id == t.toId);
      if (expIdx != -1) {
        // ФІКС: Витрати є ціллю (toId), тому для них беремо targetAmount (якщо він є)
        expenses[expIdx] = expenses[expIdx].copyWith(
          amount: expenses[expIdx].amount + (t.targetAmount ?? t.amount),
        );
      }
    }
    notifyListeners();
  }

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

  void deleteCategory(Category cat) {
    final archived = cat.copyWith(isArchived: true);
    StorageService.saveCategory(archived);

    if (cat.type == CategoryType.income) {
      incomes.removeWhere((c) => c.id == cat.id);
    } else if (cat.type == CategoryType.account) {
      accounts.removeWhere((c) => c.id == cat.id);
    } else {
      expenses.removeWhere((c) => c.id == cat.id);
    }

    archivedCategories.add(archived);
    notifyListeners();
  }

  void reorderCategories(Category dragged, Category target) {
    if (dragged.type != target.type) return;

    List<Category> targetList = (dragged.type == CategoryType.income)
        ? incomes
        : (dragged.type == CategoryType.account)
        ? accounts
        : expenses;

    int oldIndex = targetList.indexWhere((c) => c.id == dragged.id);
    int newIndex = targetList.indexWhere((c) => c.id == target.id);

    if (oldIndex != -1 && newIndex != -1 && oldIndex != newIndex) {
      final item = targetList.removeAt(oldIndex);
      targetList.insert(newIndex, item);
      StorageService.saveCategories(allCategoriesList);
      notifyListeners();
    }
  }
}
