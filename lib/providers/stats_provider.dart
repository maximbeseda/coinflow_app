import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../database/app_database.dart';
// Імпортуємо наш хаб, щоб мати доступ до транзакцій та категорій
import 'all_providers.dart';

part 'stats_provider.g.dart';

@Riverpod(keepAlive: true)
class Stats extends _$Stats {
  Map<String, Map<String, Map<String, int>>>? _cachedTrends;
  int _lastHistoryHash = 0;

  @override
  void build() {
    final txState = ref.watch(transactionProvider);
    ref.watch(categoryProvider);

    int currentHash = Object.hashAll(txState.history);
    if (_lastHistoryHash != currentHash) {
      _cachedTrends = null;
      _lastHistoryHash = currentHash;
    }
  }

  // =======================================================
  // АНАЛІТИКА ТРЕНДІВ (ДЛЯ ГРАФІКІВ)
  // =======================================================
  Map<String, Map<String, Map<String, int>>> calculateTrends() {
    if (_cachedTrends != null) return _cachedTrends!;

    final txState = ref.read(transactionProvider);
    final catState = ref.read(categoryProvider);

    Map<String, Map<String, Map<String, int>>> trends = {};

    var sortedHistory = List<Transaction>.from(txState.history)
      ..sort((a, b) => a.date.compareTo(b.date));

    // Створюємо набір ID рахунків для швидкої перевірки (O(1))
    final accountIds = catState.accounts.map((a) => a.id).toSet();

    for (var tx in sortedHistory) {
      String epoch = tx.baseCurrency.isEmpty ? 'UAH' : tx.baseCurrency;
      String monthKey =
          "${tx.date.year}-${tx.date.month.toString().padLeft(2, '0')}";

      trends.putIfAbsent(epoch, () => {});
      trends[epoch]!.putIfAbsent(monthKey, () => {'incomes': 0, 'expenses': 0});

      // 👇 НОВА ЛОГІКА: Визначаємо тип за рахунками, а не за категоріями
      bool fromIsAccount = accountIds.contains(tx.fromId);
      bool toIsAccount = accountIds.contains(tx.toId);

      // 1. Витрата: з рахунку на НЕ рахунок
      if (fromIsAccount && !toIsAccount) {
        trends[epoch]![monthKey]!['expenses'] =
            (trends[epoch]![monthKey]!['expenses'] ?? 0) + tx.baseAmount;
      }
      // 2. Дохід: з НЕ рахунку на рахунок
      if (!fromIsAccount && toIsAccount) {
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
  Map<String, int> calculateTotalsForMonth(DateTime month) {
    int totalExpenses = 0;
    int totalIncomes = 0;

    final txState = ref.read(transactionProvider);
    final catState = ref.read(categoryProvider);

    final monthHistory = txState.history.where(
      (t) => t.date.year == month.year && t.date.month == month.month,
    );

    final accountIds = catState.accounts.map((a) => a.id).toSet();

    for (var tx in monthHistory) {
      bool fromIsAccount = accountIds.contains(tx.fromId);
      bool toIsAccount = accountIds.contains(tx.toId);

      if (fromIsAccount && !toIsAccount) {
        totalExpenses += tx.baseAmount;
      } else if (!fromIsAccount && toIsAccount) {
        totalIncomes += tx.baseAmount;
      }
    }

    return {'expenses': totalExpenses, 'incomes': totalIncomes};
  }

  Map<String, int> calculateCategoryTotalsForMonth(
    DateTime month,
    bool isExpenses, {
    bool inBaseCurrency = true,
  }) {
    Map<String, int> totals = {};

    final txState = ref.read(transactionProvider);
    final catState = ref.read(categoryProvider);

    final monthHistory = txState.history.where(
      (t) => t.date.year == month.year && t.date.month == month.month,
    );

    final accountIds = catState.accounts.map((a) => a.id).toSet();

    for (var tx in monthHistory) {
      bool fromIsAccount = accountIds.contains(tx.fromId);
      bool toIsAccount = accountIds.contains(tx.toId);

      if (isExpenses) {
        // Якщо це витрата (з рахунку на категорію)
        if (fromIsAccount && !toIsAccount) {
          int value = inBaseCurrency
              ? tx.baseAmount
              : (tx.targetAmount ?? tx.amount);
          // Використовуємо ID категорії (навіть якщо вона видалена, ID в транзакції лишився)
          totals[tx.toId] = (totals[tx.toId] ?? 0) + value;
        }
      } else {
        // Якщо це дохід (з категорії на рахунок)
        if (!fromIsAccount && toIsAccount) {
          int value = inBaseCurrency ? tx.baseAmount : tx.amount;
          totals[tx.fromId] = (totals[tx.fromId] ?? 0) + value;
        }
      }
    }

    return totals;
  }
}
