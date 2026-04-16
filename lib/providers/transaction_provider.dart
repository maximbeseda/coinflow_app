import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:drift/drift.dart' as drift;
// 👇 ДОДАНО: необхідно для методу .select
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/app_database.dart';
import '../services/storage_service.dart';

// Імпортуємо наш хаб провайдерів
import 'all_providers.dart';

part 'transaction_provider.g.dart';

// 1. СТАН (State)
class TransactionState {
  final List<Transaction> history;
  final DateTime selectedMonth;
  final bool isLoading;
  final bool isMigrating;
  final String? lastKnownBaseCurrency;

  TransactionState({
    required this.history,
    required this.selectedMonth,
    required this.isLoading,
    required this.isMigrating,
    this.lastKnownBaseCurrency,
  });

  TransactionState copyWith({
    List<Transaction>? history,
    DateTime? selectedMonth,
    bool? isLoading,
    bool? isMigrating,
    String? lastKnownBaseCurrency,
  }) {
    return TransactionState(
      history: history ?? this.history,
      selectedMonth: selectedMonth ?? this.selectedMonth,
      isLoading: isLoading ?? this.isLoading,
      isMigrating: isMigrating ?? this.isMigrating,
      lastKnownBaseCurrency:
          lastKnownBaseCurrency ?? this.lastKnownBaseCurrency,
    );
  }

  bool get isCurrentMonth {
    final now = DateTime.now();
    return selectedMonth.year == now.year && selectedMonth.month == now.month;
  }
}

// 2. СУЧАСНИЙ NOTIFIER
@Riverpod(keepAlive: true)
class TransactionNotifier extends _$TransactionNotifier {
  @override
  TransactionState build() {
    ref.listen<String>(settingsProvider.select((s) => s.baseCurrency), (
      previous,
      next,
    ) {
      // Запускаємо міграцію тільки якщо це реальна зміна
      if (previous != null && previous != next) {
        _migrateCurrentMonthBaseCurrency(next);
      }
    });

    final initialState = TransactionState(
      history: [],
      selectedMonth: DateTime(DateTime.now().year, DateTime.now().month, 1),
      isLoading: true,
      isMigrating: false,
    );

    Future.microtask(() => _init());

    return initialState;
  }

  Future<void> _init() async {
    await loadHistory();

    // Захист при старті. Перевіряємо, чи не збилася валюта поточного місяця
    final currentBase = ref.read(settingsProvider).baseCurrency;
    final now = DateTime.now();
    final currentMonthTxs = state.history
        .where((tx) => tx.date.year == now.year && tx.date.month == now.month)
        .toList();

    if (currentMonthTxs.isNotEmpty &&
        currentMonthTxs.first.baseCurrency != currentBase) {
      _migrateCurrentMonthBaseCurrency(currentBase);
    }
  }

  Future<void> loadHistory() async {
    final db = ref.read(databaseProvider);
    final loadedHistory = await StorageService.loadHistory(db);
    loadedHistory.sort((a, b) => b.date.compareTo(a.date));

    state = state.copyWith(history: loadedHistory, isLoading: false);
  }

  void changeMonth(int offset) {
    state = state.copyWith(
      selectedMonth: DateTime(
        state.selectedMonth.year,
        state.selectedMonth.month + offset,
        1,
      ),
    );
  }

  void setMonth(DateTime newMonth) {
    state = state.copyWith(
      selectedMonth: DateTime(newMonth.year, newMonth.month, 1),
    );
  }

  // 👇 ВИПРАВЛЕНО: Асинхронний метод, який враховує дату транзакції
  Future<int> _calculateBaseAmountAsync(
    int amount,
    String currency,
    int? targetAmount,
    String? targetCurrency,
    String baseCur,
    DateTime txDate,
  ) async {
    // Принцип ідентичності: якщо валюта транзакції співпадає з базовою, повертаємо як є
    if (currency == baseCur) return amount;
    if (targetCurrency == baseCur && targetAmount != null) return targetAmount;

    // Отримуємо курси саме на дату транзакції (або з кешу, або з API)
    final settingsNotif = ref.read(settingsProvider.notifier);
    double fromRate =
        (await settingsNotif.getRateForDate(currency, txDate)) ?? 1.0;
    double toRate =
        (await settingsNotif.getRateForDate(baseCur, txDate)) ?? 1.0;

    if (fromRate == 0) fromRate = 1.0;

    return (amount * (toRate / fromRate)).round();
  }

  void _updateAccountBalance(String categoryId, int delta) {
    final catState = ref.read(categoryProvider);
    final catNotifier = ref.read(categoryProvider.notifier);

    final category = catState.allCategoriesList
        .where((c) => c.id == categoryId)
        .firstOrNull;

    if (category != null && category.type == CategoryType.account) {
      catNotifier.updateCategoryAmount(categoryId, delta);
    }
  }

  // 👇 ВИПРАВЛЕНО: Додано async/await
  Future<void> addTransactionDirectly(Transaction tx) async {
    final db = ref.read(databaseProvider);
    final currentBase = ref.read(settingsProvider).baseCurrency;

    int baseAmt;
    // Якщо базова валюта вже порахована при імпорті — не йдемо в інтернет
    if (tx.baseCurrency == currentBase && tx.baseAmount != 0) {
      baseAmt = tx.baseAmount;
    } else {
      baseAmt = await _calculateBaseAmountAsync(
        tx.amount,
        tx.currency,
        tx.targetAmount,
        tx.targetCurrency,
        currentBase,
        tx.date,
      );
    }

    final updatedTx = tx.copyWith(
      baseCurrency: currentBase,
      baseAmount: baseAmt,
    );

    final newHistory = List<Transaction>.from(state.history)..add(updatedTx);
    newHistory.sort((a, b) => b.date.compareTo(a.date));

    state = state.copyWith(history: newHistory);
    await StorageService.saveTransaction(db, updatedTx);

    // 👇 ВИПРАВЛЕНО: Тепер при імпорті рахунки будуть отримувати гроші!
    _updateAccountBalance(updatedTx.fromId, -updatedTx.amount);
    _updateAccountBalance(
      updatedTx.toId,
      updatedTx.targetAmount ?? updatedTx.amount,
    );
  }

  // 👇 ВИПРАВЛЕНО: Додано async/await
  Future<void> addTransfer(
    Category source,
    Category target,
    int amount,
    DateTime date, {
    int? targetAmount,
  }) async {
    final db = ref.read(databaseProvider);
    final catNotifier = ref.read(categoryProvider.notifier);

    if (source.type == CategoryType.account) {
      catNotifier.updateCategoryAmount(source.id, -amount);
    }
    if (target.type == CategoryType.account) {
      catNotifier.updateCategoryAmount(target.id, targetAmount ?? amount);
    }

    final currentBase = ref.read(settingsProvider).baseCurrency;

    // Чекаємо на прорахунок
    final baseAmt = await _calculateBaseAmountAsync(
      amount,
      source.currency,
      targetAmount,
      targetAmount != null ? target.currency : null,
      currentBase,
      date, // Історична дата переказу
    );

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
      baseAmount: baseAmt,
      baseCurrency: currentBase,
    );

    final newHistory = List<Transaction>.from(state.history)..insert(0, newTx);
    state = state.copyWith(history: newHistory);

    await StorageService.saveTransaction(db, newTx);
  }

  // 👇 ВИПРАВЛЕНО: Додано async/await
  Future<void> editTransaction(
    Transaction oldT,
    int newAmount,
    DateTime newDate, {
    int? newTargetAmount,
  }) async {
    final db = ref.read(databaseProvider);
    _updateAccountBalance(oldT.fromId, oldT.amount);
    _updateAccountBalance(oldT.toId, -(oldT.targetAmount ?? oldT.amount));

    final int previousAmount = oldT.amount;

    int finalTargetAmount;
    if (newTargetAmount != null) {
      finalTargetAmount = newTargetAmount;
    } else if (oldT.targetAmount != null && previousAmount > 0) {
      finalTargetAmount = (oldT.targetAmount! * (newAmount / previousAmount))
          .round();
    } else {
      finalTargetAmount = newAmount;
    }

    int finalBaseAmount;
    if (previousAmount > 0) {
      finalBaseAmount = (oldT.baseAmount * (newAmount / previousAmount))
          .round();
    } else {
      // Чекаємо на прорахунок за новою датою
      finalBaseAmount = await _calculateBaseAmountAsync(
        newAmount,
        oldT.currency,
        finalTargetAmount,
        oldT.targetCurrency,
        oldT.baseCurrency,
        newDate, // Нова дата
      );
    }

    final updatedT = oldT.copyWith(
      amount: newAmount,
      date: newDate,
      targetAmount: drift.Value(finalTargetAmount),
      baseAmount: finalBaseAmount,
    );

    _updateAccountBalance(updatedT.fromId, -updatedT.amount);
    _updateAccountBalance(
      updatedT.toId,
      updatedT.targetAmount ?? updatedT.amount,
    );

    final newHistory = List<Transaction>.from(state.history);
    int index = newHistory.indexWhere((t) => t.id == oldT.id);
    if (index != -1) {
      newHistory[index] = updatedT;
    }
    newHistory.sort((a, b) => b.date.compareTo(a.date));

    state = state.copyWith(history: newHistory);
    await StorageService.saveTransaction(db, updatedT);
  }

  void deleteTransaction(Transaction t) {
    final db = ref.read(databaseProvider);
    _updateAccountBalance(t.fromId, t.amount);
    _updateAccountBalance(t.toId, -(t.targetAmount ?? t.amount));

    final newHistory = List<Transaction>.from(state.history)
      ..removeWhere((item) => item.id == t.id);
    state = state.copyWith(history: newHistory);
    StorageService.removeTransaction(db, t.id);
  }

  Future<void> _migrateCurrentMonthBaseCurrency(String newBase) async {
    final db = ref.read(databaseProvider);
    final now = DateTime.now();
    final newHistory = List<Transaction>.from(state.history);

    // Фільтруємо ТІЛЬКИ транзакції ПОТОЧНОГО календарного місяця
    final currentMonthTxs = newHistory
        .where((tx) => tx.date.year == now.year && tx.date.month == now.month)
        .toList();

    if (currentMonthTxs.isEmpty) {
      state = state.copyWith(lastKnownBaseCurrency: newBase);
      return;
    }

    state = state.copyWith(isMigrating: true, lastKnownBaseCurrency: newBase);

    for (int i = 0; i < currentMonthTxs.length; i++) {
      var tx = currentMonthTxs[i];

      // 👇 ВИПРАВЛЕНО: Асинхронний виклик
      final int newBaseAmount = await _calculateBaseAmountAsync(
        tx.amount,
        tx.currency,
        tx.targetAmount,
        tx.targetCurrency,
        newBase,
        tx.date,
      );

      // Захист від мікро-округлень
      if (tx.baseAmount == newBaseAmount && tx.baseCurrency == newBase) {
        continue;
      }

      tx = tx.copyWith(baseAmount: newBaseAmount, baseCurrency: newBase);

      int mainIndex = newHistory.indexWhere((t) => t.id == tx.id);
      if (mainIndex != -1) newHistory[mainIndex] = tx;

      await StorageService.saveTransaction(db, tx);
    }

    state = state.copyWith(history: newHistory, isMigrating: false);
  }

  Future<void> clearAllTransactions() async {
    final db = ref.read(databaseProvider);
    state = state.copyWith(history: []);
    await StorageService.saveHistory(db, []);
  }
}
