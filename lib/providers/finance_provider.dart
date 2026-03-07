import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../models/category_model.dart';
import '../models/transaction_model.dart';
import '../models/subscription_model.dart';
import '../services/storage_service.dart';
import '../services/subscription_service.dart';

class FinanceProvider extends ChangeNotifier {
  List<Category> incomes = [];
  List<Category> accounts = [];
  List<Category> expenses = [];
  List<Transaction> history = [];
  List<Category> archivedCategories = [];

  List<Category> get allCategoriesList => [
    ...incomes,
    ...accounts,
    ...expenses,
    ...archivedCategories,
  ];

  // --- ПІДПИСКИ ---
  List<Subscription> subscriptions = [];
  List<Subscription> dueSubscriptions = [];
  final Set<String> _ignoredSubIds = {};

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

  // Допоміжний метод для оновлення балансу/суми категорії в пам'яті та базі
  void _updateCategoryAmount(String id, double delta) {
    final all = allCategoriesList;
    final index = all.indexWhere((c) => c.id == id);
    if (index == -1) return;

    final category = all[index];
    final updatedCategory = category.copyWith(amount: category.amount + delta);

    // Оновлюємо у відповідному списку
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
  }

  void _refreshUI() {
    history.sort((a, b) => b.date.compareTo(a.date));
    _recalculateMonthTotals();
    notifyListeners();
  }

  Future<void> loadData() async {
    // ДАНІ ВЖЕ ПРОЙШЛИ МІГРАЦІЮ В main.dart
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

    history = await StorageService.loadHistory();
    subscriptions = StorageService.getSubscriptions();
    await processAutoPayments();
    _checkDueSubscriptions();

    _refreshUI();
    isLoading = false;
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

  void _recalculateMonthTotals() {
    final now = DateTime.now();

    // Зануляємо суми через copyWith
    incomes = incomes.map((c) => c.copyWith(amount: 0.0)).toList();
    expenses = expenses.map((c) => c.copyWith(amount: 0.0)).toList();

    final currentMonthHistory = history
        .where((t) => t.date.year == now.year && t.date.month == now.month)
        .toList();

    for (var t in currentMonthHistory) {
      // Оновлення доходів у списку
      int incIdx = incomes.indexWhere((c) => c.id == t.fromId);
      if (incIdx != -1) {
        incomes[incIdx] = incomes[incIdx].copyWith(
          amount: incomes[incIdx].amount + t.amount,
        );
      }

      // Оновлення витрат у списку
      int expIdx = expenses.indexWhere((c) => c.id == t.toId);
      if (expIdx != -1) {
        expenses[expIdx] = expenses[expIdx].copyWith(
          amount: expenses[expIdx].amount + t.amount,
        );
      }
    }
  }

  // --- ОПЕРАЦІЇ З ТРАНЗАКЦІЯМИ ---

  void addTransfer(
    Category source,
    Category target,
    double amount,
    DateTime date,
  ) {
    if (source.type == CategoryType.account) {
      _updateCategoryAmount(source.id, -amount);
    }
    if (target.type == CategoryType.account) {
      _updateCategoryAmount(target.id, amount);
    }

    final newTx = Transaction(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      fromId: source.id,
      toId: target.id,
      title: target.name,
      amount: amount,
      date: date,
    );

    history.insert(0, newTx);
    StorageService.saveTransaction(newTx);
    _refreshUI();
  }

  void editTransaction(Transaction oldT, double newAmount, DateTime newDate) {
    // Скасовуємо стару суму
    _updateCategoryAmount(oldT.fromId, oldT.amount);
    _updateCategoryAmount(oldT.toId, -oldT.amount);

    oldT.amount = newAmount;
    oldT.date = newDate;

    // Застосовуємо нову суму
    _updateCategoryAmount(oldT.fromId, -oldT.amount);
    _updateCategoryAmount(oldT.toId, oldT.amount);

    StorageService.saveTransaction(oldT);
    _refreshUI();
  }

  void deleteTransaction(Transaction t) {
    _updateCategoryAmount(t.fromId, t.amount);
    _updateCategoryAmount(t.toId, -t.amount);

    history.removeWhere((item) => item.id == t.id);
    StorageService.removeTransaction(t.id);
    _refreshUI();
  }

  // --- КАТЕГОРІЇ ---

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

  // --- ПІДПИСКИ ---

  void _checkDueSubscriptions() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    dueSubscriptions = subscriptions.where((sub) {
      if (_ignoredSubIds.contains(sub.id)) return false;
      final paymentDate = DateTime(
        sub.nextPaymentDate.year,
        sub.nextPaymentDate.month,
        sub.nextPaymentDate.day,
      );
      return paymentDate.isBefore(today) || paymentDate.isAtSameMomentAs(today);
    }).toList();
  }

  Future<void> addSubscription(Subscription sub) async {
    subscriptions.add(sub);
    await StorageService.saveSubscription(sub);
    await processAutoPayments();
    _checkDueSubscriptions();
    notifyListeners();
  }

  Future<void> updateSubscription(Subscription updatedSub) async {
    int index = subscriptions.indexWhere((s) => s.id == updatedSub.id);
    if (index != -1) {
      subscriptions[index] = updatedSub;
      await StorageService.saveSubscription(updatedSub);
      await processAutoPayments();
      _checkDueSubscriptions();
      notifyListeners();
    }
  }

  Future<void> deleteSubscription(String id) async {
    subscriptions.removeWhere((s) => s.id == id);
    await StorageService.deleteSubscription(id);
    _checkDueSubscriptions();
    notifyListeners();
  }

  Future<(bool, String)> confirmSubscriptionPayment(
    Subscription sub,
    double finalAmount,
  ) async {
    final all = allCategoriesList;
    Category? sourceAccount;
    Category? targetExpense;

    try {
      sourceAccount = all.firstWhere((c) => c.id == sub.accountId);
      targetExpense = all.firstWhere((c) => c.id == sub.categoryId);
      if (sourceAccount.isArchived || targetExpense.isArchived) {
        return (false, 'error_category_deleted'.tr());
      }
    } catch (e) {
      return (false, 'error_category_not_found'.tr());
    }

    if (sourceAccount.amount < finalAmount) {
      return (false, 'not_enough_funds'.tr(args: [sourceAccount.name]));
    }

    _updateCategoryAmount(sourceAccount.id, -finalAmount);
    _updateCategoryAmount(targetExpense.id, finalAmount);

    final newTx = Transaction(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      fromId: sourceAccount.id,
      toId: targetExpense.id,
      title: sub.name,
      amount: finalAmount,
      date: sub.nextPaymentDate,
    );

    history.insert(0, newTx);
    await StorageService.saveTransaction(newTx);
    await SubscriptionService.shiftSubscriptionDate(sub);

    _checkDueSubscriptions();
    _refreshUI();
    return (true, 'paid_success'.tr(args: [sub.name]));
  }

  Future<void> processAutoPayments() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    bool processedAny = false;

    for (var sub in subscriptions) {
      if (!sub.isAutoPay) continue;
      final pDate = DateTime(
        sub.nextPaymentDate.year,
        sub.nextPaymentDate.month,
        sub.nextPaymentDate.day,
      );

      if (pDate.isBefore(today) || pDate.isAtSameMomentAs(today)) {
        final all = allCategoriesList;
        final account = all.where((c) => c.id == sub.accountId).firstOrNull;
        final expense = all.where((c) => c.id == sub.categoryId).firstOrNull;

        if (account != null &&
            expense != null &&
            account.amount >= sub.amount &&
            !account.isArchived &&
            !expense.isArchived) {
          _updateCategoryAmount(account.id, -sub.amount);
          _updateCategoryAmount(expense.id, sub.amount);

          final newTx = Transaction(
            id: "${DateTime.now().millisecondsSinceEpoch}_${sub.id}",
            fromId: account.id,
            toId: expense.id,
            title: 'auto_payment_marker'.tr(args: [sub.name]),
            amount: sub.amount,
            date: sub.nextPaymentDate,
          );

          history.insert(0, newTx);
          await StorageService.saveTransaction(newTx);
          await SubscriptionService.shiftSubscriptionDate(sub);
          processedAny = true;
        }
      }
    }
    if (processedAny) _refreshUI();
  }

  Future<void> skipSubscriptionPayment(Subscription sub) async {
    await SubscriptionService.shiftSubscriptionDate(sub);
    _checkDueSubscriptions();
    notifyListeners();
  }

  void ignoreSubscriptionForSession(String subId) {
    _ignoredSubIds.add(subId);
    _checkDueSubscriptions();
  }
}
