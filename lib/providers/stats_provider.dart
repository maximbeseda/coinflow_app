import 'package:flutter/material.dart';
import '../models/transaction_model.dart';
import 'transaction_provider.dart';
import 'category_provider.dart';

class StatsProvider extends ChangeNotifier {
  TransactionProvider? _txProv;
  CategoryProvider? _catProv;

  // 👇 ЗМІНЕНО: Map тепер зберігає int (копійки)
  Map<String, Map<String, Map<String, int>>>? _cachedTrends;

  int _lastHistoryHash = 0;

  void updateDependencies(
    TransactionProvider txProv,
    CategoryProvider catProv,
  ) {
    _txProv = txProv;
    _catProv = catProv;

    int currentHash = Object.hashAll(_txProv?.history ?? []);
    if (_lastHistoryHash != currentHash) {
      _cachedTrends = null;
      _lastHistoryHash = currentHash;
    }
  }

  // =======================================================
  // АНАЛІТИКА ТРЕНДІВ (ДЛЯ ГРАФІКІВ)
  // =======================================================
  // 👇 ЗМІНЕНО: Повертає int
  Map<String, Map<String, Map<String, int>>> calculateTrends() {
    if (_cachedTrends != null) return _cachedTrends!;
    if (_catProv == null || _txProv == null) return {};

    Map<String, Map<String, Map<String, int>>> trends = {};

    var sortedHistory = List<Transaction>.from(_txProv!.history)
      ..sort((a, b) => a.date.compareTo(b.date));

    for (var tx in sortedHistory) {
      String epoch = tx.baseCurrency.isEmpty ? 'UAH' : tx.baseCurrency;
      String monthKey =
          "${tx.date.year}-${tx.date.month.toString().padLeft(2, '0')}";

      trends.putIfAbsent(epoch, () => {});
      trends[epoch]!.putIfAbsent(
        monthKey,
        () => {'incomes': 0, 'expenses': 0}, // 👇 ЗМІНЕНО: 0 замість 0.0
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
  // 👇 ЗМІНЕНО: Повертає int
  Map<String, int> calculateTotalsForMonth(DateTime month) {
    int totalExpenses = 0; // 👇 ЗМІНЕНО: int
    int totalIncomes = 0; // 👇 ЗМІНЕНО: int

    if (_catProv == null || _txProv == null) {
      return {'expenses': 0, 'incomes': 0};
    }

    final monthHistory = _txProv!.history.where(
      (t) => t.date.year == month.year && t.date.month == month.month,
    );

    for (var tx in monthHistory) {
      bool isExpense = _catProv!.expenses.any((c) => c.id == tx.toId);
      bool isIncome = _catProv!.incomes.any((c) => c.id == tx.fromId);

      if (isExpense) totalExpenses += tx.baseAmount;
      if (isIncome) totalIncomes += tx.baseAmount;
    }

    return {'expenses': totalExpenses, 'incomes': totalIncomes};
    // 👇 ВИДАЛЕНО: double.parse(...toStringAsFixed(2)), воно більше не потрібне!
  }

  // 👇 ЗМІНЕНО: Повертає int
  Map<String, int> calculateCategoryTotalsForMonth(
    DateTime month,
    bool isExpenses, {
    bool inBaseCurrency = true,
  }) {
    Map<String, int> totals = {};
    if (_catProv == null || _txProv == null) return totals;

    final monthHistory = _txProv!.history.where(
      (t) => t.date.year == month.year && t.date.month == month.month,
    );

    for (var tx in monthHistory) {
      if (isExpenses) {
        bool isExpenseCat = _catProv!.expenses.any((c) => c.id == tx.toId);
        if (isExpenseCat) {
          int value =
              inBaseCurrency // 👇 ЗМІНЕНО: int
              ? tx.baseAmount
              : (tx.targetAmount ?? tx.amount);
          totals[tx.toId] = (totals[tx.toId] ?? 0) + value;
        }
      } else {
        bool isIncomeCat = _catProv!.incomes.any((c) => c.id == tx.fromId);
        if (isIncomeCat) {
          int value = inBaseCurrency
              ? tx.baseAmount
              : tx.amount; // 👇 ЗМІНЕНО: int
          totals[tx.fromId] = (totals[tx.fromId] ?? 0) + value;
        }
      }
    }

    // 👇 ВИДАЛЕНО: цикл з заокругленням. Цілі числа і так ідеально точні.
    return totals;
  }
}
