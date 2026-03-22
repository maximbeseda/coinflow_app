import 'package:flutter/material.dart';
import '../models/category_model.dart';
import '../models/transaction_model.dart';
import '../services/storage_service.dart';
import 'category_provider.dart';
import 'settings_provider.dart';

class TransactionProvider extends ChangeNotifier {
  CategoryProvider? _catProv;
  SettingsProvider? _settingsProv;

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

  void updateDependencies(
    CategoryProvider catProv,
    SettingsProvider settingsProv,
  ) {
    _catProv = catProv;
    _settingsProv = settingsProv;

    if (!isLoading && !catProv.isLoading && _settingsProv != null) {
      notifyListeners();
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

  // 👇 ДОДАНО: Головний метод для "безвтратного" підрахунку статистики
  Map<String, double> calculateTotalsForMonth(DateTime month) {
    double totalExpenses = 0.0;
    double totalIncomes = 0.0;

    if (_catProv == null || _settingsProv == null) {
      return {'expenses': 0.0, 'incomes': 0.0};
    }

    final baseCurrency = _settingsProv!.baseCurrency;
    final rates = _settingsProv!.exchangeRates;

    final monthHistory = history
        .where((t) => t.date.year == month.year && t.date.month == month.month)
        .toList();

    for (var tx in monthHistory) {
      // Визначаємо типи категорій для транзакції
      bool isExpense = _catProv!.expenses.any((c) => c.id == tx.toId);
      bool isIncome = _catProv!.incomes.any((c) => c.id == tx.fromId);

      if (isExpense) {
        // Якщо витрата в базовій валюті - беремо рівно скільки списалося (amount)
        if (tx.currency == baseCurrency) {
          totalExpenses += tx.amount;
        } else {
          // Якщо списалося у валюті - конвертуємо amount у базову валюту за поточним курсом
          double txRate = rates[tx.currency] ?? 1.0;
          double baseRate = rates[baseCurrency] ?? 1.0;
          totalExpenses += tx.amount * (baseRate / txRate);
        }
      }

      if (isIncome) {
        // Дохід завжди беремо з amount, бо джерело - це Income-категорія
        if (tx.currency == baseCurrency) {
          totalIncomes += tx.amount;
        } else {
          double txRate = rates[tx.currency] ?? 1.0;
          double baseRate = rates[baseCurrency] ?? 1.0;
          totalIncomes += tx.amount * (baseRate / txRate);
        }
      }
    }

    return {'expenses': totalExpenses, 'incomes': totalIncomes};
  }

  // 👇 ДОДАНО: Статистика з розбивкою по окремих категоріях (для графіків)
  Map<String, double> calculateCategoryTotalsForMonth(
    DateTime month,
    bool isExpenses, {
    bool inBaseCurrency = true, // Додаємо цей параметр
  }) {
    Map<String, double> totals = {};

    if (_catProv == null || _settingsProv == null) return totals;

    final baseCurrency = _settingsProv!.baseCurrency;
    final rates = _settingsProv!.exchangeRates;

    final monthHistory = history
        .where((t) => t.date.year == month.year && t.date.month == month.month)
        .toList();

    for (var tx in monthHistory) {
      if (isExpenses) {
        bool isExpenseCat = _catProv!.expenses.any((c) => c.id == tx.toId);
        if (isExpenseCat) {
          double value;
          if (inBaseCurrency) {
            // Для статистики: конвертуємо в UAH
            value = tx.currency == baseCurrency
                ? tx.amount
                : tx.amount * (rates[baseCurrency]! / rates[tx.currency]!);
          } else {
            // ДЛЯ МОНЕТОК: беремо суму, яка реально потрапила в категорію
            value = tx.targetAmount ?? tx.amount;
          }
          totals[tx.toId] = (totals[tx.toId] ?? 0.0) + value;
        }
      } else {
        bool isIncomeCat = _catProv!.incomes.any((c) => c.id == tx.fromId);
        if (isIncomeCat) {
          double value;
          if (inBaseCurrency) {
            value = tx.currency == baseCurrency
                ? tx.amount
                : tx.amount * (rates[baseCurrency]! / rates[tx.currency]!);
          } else {
            // Для доходів зазвичай це tx.amount
            value = tx.amount;
          }
          totals[tx.fromId] = (totals[tx.fromId] ?? 0.0) + value;
        }
      }
    }
    return totals;
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
    double? targetAmount,
  }) {
    if (source.type == CategoryType.account) {
      _catProv?.updateCategoryAmount(source.id, -amount);
    }
    if (target.type == CategoryType.account) {
      _catProv?.updateCategoryAmount(target.id, targetAmount ?? amount);
    }

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
    );

    addTransactionDirectly(newTx);
  }

  void editTransaction(
    Transaction oldT,
    double newAmount,
    DateTime newDate, {
    double? newTargetAmount,
  }) {
    _updateAccountBalance(oldT.fromId, oldT.amount);
    _updateAccountBalance(oldT.toId, -(oldT.targetAmount ?? oldT.amount));

    final double previousAmount = oldT.amount;

    oldT.amount = newAmount;
    oldT.date = newDate;

    if (newTargetAmount != null) {
      oldT.targetAmount = newTargetAmount;
    } else if (oldT.targetAmount != null && previousAmount > 0) {
      oldT.targetAmount = oldT.targetAmount! * (newAmount / previousAmount);
    } else {
      oldT.targetAmount = newAmount;
    }

    _updateAccountBalance(oldT.fromId, -oldT.amount);
    _updateAccountBalance(oldT.toId, oldT.targetAmount ?? oldT.amount);

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

  void addTransactionDirectly(Transaction tx) {
    _updateAccountBalance(tx.fromId, -tx.amount);
    _updateAccountBalance(tx.toId, tx.targetAmount ?? tx.amount);

    history.insert(0, tx);
    history.sort((a, b) => b.date.compareTo(a.date));
    StorageService.saveTransaction(tx);
    notifyListeners();
  }

  Future<void> clearAllTransactions() async {
    history.clear();
    await StorageService.saveHistory([]);
    notifyListeners();
  }
}
