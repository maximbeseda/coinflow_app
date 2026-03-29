import 'package:flutter/material.dart';
import '../models/category_model.dart';
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

  // 👇 ЗМІНЕНО: delta тепер int
  void updateCategoryAmount(String id, int delta) {
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

  Future<void> resetAllBalances() async {
    // 👇 ЗМІНЕНО: 0 замість 0.0 в усіх циклах
    for (var i = 0; i < incomes.length; i++) {
      incomes[i] = incomes[i].copyWith(amount: 0);
    }
    for (var i = 0; i < accounts.length; i++) {
      accounts[i] = accounts[i].copyWith(amount: 0);
    }
    for (var i = 0; i < expenses.length; i++) {
      expenses[i] = expenses[i].copyWith(amount: 0);
    }
    for (var i = 0; i < archivedCategories.length; i++) {
      archivedCategories[i] = archivedCategories[i].copyWith(amount: 0);
    }
    await StorageService.saveCategories(allCategoriesList);
    notifyListeners();
  }
}
