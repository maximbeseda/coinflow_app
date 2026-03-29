import 'package:flutter/material.dart';
import '../models/transaction_model.dart';
import 'transaction_provider.dart';
import 'category_provider.dart';

class StatsProvider extends ChangeNotifier {
  TransactionProvider? _txProv;
  CategoryProvider? _catProv;

  // Наш кеш для трендів
  Map<String, Map<String, Map<String, double>>>? _cachedTrends;

  // Запам'ятовуємо "зліпок" історії, щоб знати, коли скидати кеш
  int _lastHistoryHash = 0;

  void updateDependencies(
    TransactionProvider txProv,
    CategoryProvider catProv,
  ) {
    _txProv = txProv;
    _catProv = catProv;

    // Якщо історія транзакцій змінилася (додали/видалили), хеш буде іншим
    int currentHash = Object.hashAll(_txProv?.history ?? []);
    if (_lastHistoryHash != currentHash) {
      _cachedTrends = null; // Скидаємо кеш
      _lastHistoryHash = currentHash;
    }
  }

  // =======================================================
  // АНАЛІТИКА ТРЕНДІВ (ДЛЯ ГРАФІКІВ)
  // =======================================================
  Map<String, Map<String, Map<String, double>>> calculateTrends() {
    if (_cachedTrends != null) return _cachedTrends!;
    if (_catProv == null || _txProv == null) return {};

    Map<String, Map<String, Map<String, double>>> trends = {};

    var sortedHistory = List<Transaction>.from(_txProv!.history)
      ..sort((a, b) => a.date.compareTo(b.date));

    for (var tx in sortedHistory) {
      String epoch = tx.baseCurrency.isEmpty ? 'UAH' : tx.baseCurrency;
      String monthKey =
          "${tx.date.year}-${tx.date.month.toString().padLeft(2, '0')}";

      trends.putIfAbsent(epoch, () => {});
      trends[epoch]!.putIfAbsent(
        monthKey,
        () => {'incomes': 0.0, 'expenses': 0.0},
      );

      bool isExpense = _catProv!.expenses.any((c) => c.id == tx.toId);
      bool isIncome = _catProv!.incomes.any((c) => c.id == tx.fromId);

      if (isExpense) {
        trends[epoch]![monthKey]!['expenses'] =
            (trends[epoch]![monthKey]!['expenses'] ?? 0) + tx.baseAmount;
      }
      if (isIncome) {
        trends[epoch]![monthKey]!['incomes'] =
            (trends[epoch]![monthKey]!['incomes'] ?? 0) + tx.baseAmount;
      }
    }

    _cachedTrends = trends;
    return trends;
  }

  // =======================================================
  // АНАЛІТИКА КРУГОВОЇ ДІАГРАМИ ТА ЗАГАЛЬНИХ СУМ
  // =======================================================
  Map<String, double> calculateTotalsForMonth(DateTime month) {
    double totalExpenses = 0.0;
    double totalIncomes = 0.0;

    if (_catProv == null || _txProv == null) {
      return {'expenses': 0.0, 'incomes': 0.0};
    }

    // Відфільтровуємо транзакції за обраний місяць
    final monthHistory = _txProv!.history.where(
      (t) => t.date.year == month.year && t.date.month == month.month,
    );

    for (var tx in monthHistory) {
      bool isExpense = _catProv!.expenses.any((c) => c.id == tx.toId);
      bool isIncome = _catProv!.incomes.any((c) => c.id == tx.fromId);

      if (isExpense) totalExpenses += tx.baseAmount;
      if (isIncome) totalIncomes += tx.baseAmount;
    }

    return {
      'expenses': double.parse(totalExpenses.toStringAsFixed(2)),
      'incomes': double.parse(totalIncomes.toStringAsFixed(2)),
    };
  }

  Map<String, double> calculateCategoryTotalsForMonth(
    DateTime month,
    bool isExpenses, {
    bool inBaseCurrency = true,
  }) {
    Map<String, double> totals = {};
    if (_catProv == null || _txProv == null) return totals;

    final monthHistory = _txProv!.history.where(
      (t) => t.date.year == month.year && t.date.month == month.month,
    );

    for (var tx in monthHistory) {
      if (isExpenses) {
        bool isExpenseCat = _catProv!.expenses.any((c) => c.id == tx.toId);
        if (isExpenseCat) {
          double value = inBaseCurrency
              ? tx.baseAmount
              : (tx.targetAmount ?? tx.amount);
          totals[tx.toId] = (totals[tx.toId] ?? 0.0) + value;
        }
      } else {
        bool isIncomeCat = _catProv!.incomes.any((c) => c.id == tx.fromId);
        if (isIncomeCat) {
          double value = inBaseCurrency ? tx.baseAmount : tx.amount;
          totals[tx.fromId] = (totals[tx.fromId] ?? 0.0) + value;
        }
      }
    }

    // Заокруглюємо результати для уникнення артефактів double
    totals.forEach((key, value) {
      totals[key] = double.parse(value.toStringAsFixed(2));
    });

    return totals;
  }
}
