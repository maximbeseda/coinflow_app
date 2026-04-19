import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:drift/drift.dart' as drift;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/app_database.dart';
import '../services/storage_service.dart';
import 'all_providers.dart';

part 'transaction_provider.g.dart';

// 1. СТАН (State) - Тільки повна історія для статистики
class TransactionState {
  final List<Transaction> history;
  final List<Transaction> deletedHistory; // 👇 НОВЕ: Кошик транзакцій
  final DateTime selectedMonth;
  final bool isLoading;
  final bool isMigrating;
  final String? lastKnownBaseCurrency;

  TransactionState({
    required this.history,
    required this.deletedHistory,
    required this.selectedMonth,
    required this.isLoading,
    required this.isMigrating,
    this.lastKnownBaseCurrency,
  });

  TransactionState copyWith({
    List<Transaction>? history,
    List<Transaction>? deletedHistory,
    DateTime? selectedMonth,
    bool? isLoading,
    bool? isMigrating,
    String? lastKnownBaseCurrency,
  }) {
    return TransactionState(
      history: history ?? this.history,
      deletedHistory: deletedHistory ?? this.deletedHistory,
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
      if (previous != null && previous != next) {
        _migrateCurrentMonthBaseCurrency(next);
      }
    });

    final initialState = TransactionState(
      history: [],
      deletedHistory: [], // 👇 Ініціалізація
      selectedMonth: DateTime(DateTime.now().year, DateTime.now().month, 1),
      isLoading: true,
      isMigrating: false,
    );

    Future.microtask(() => _init());

    return initialState;
  }

  Future<void> _init() async {
    await loadHistory();

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

    // 👇 РОЗДІЛЯЄМО НА АКТИВНІ ТА ВИДАЛЕНІ
    final activeHistory = loadedHistory
        .where((t) => t.deletedAt == null)
        .toList();
    final deletedHistory = loadedHistory
        .where((t) => t.deletedAt != null)
        .toList();

    state = state.copyWith(
      history: activeHistory,
      deletedHistory: deletedHistory,
      isLoading: false,
    );
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

  Future<int> _calculateBaseAmountAsync(
    int amount,
    String currency,
    int? targetAmount,
    String? targetCurrency,
    String baseCur,
    DateTime txDate,
  ) async {
    if (currency == baseCur) return amount;
    if (targetCurrency == baseCur && targetAmount != null) return targetAmount;

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

  Future<void> addTransactionDirectly(Transaction tx) async {
    final db = ref.read(databaseProvider);
    final currentBase = ref.read(settingsProvider).baseCurrency;

    int baseAmt;
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

    _updateAccountBalance(updatedTx.fromId, -updatedTx.amount);
    _updateAccountBalance(
      updatedTx.toId,
      updatedTx.targetAmount ?? updatedTx.amount,
    );
  }

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
    final baseAmt = await _calculateBaseAmountAsync(
      amount,
      source.currency,
      targetAmount,
      targetAmount != null ? target.currency : null,
      currentBase,
      date,
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
      finalBaseAmount = await _calculateBaseAmountAsync(
        newAmount,
        oldT.currency,
        finalTargetAmount,
        oldT.targetCurrency,
        oldT.baseCurrency,
        newDate,
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
    if (index != -1) newHistory[index] = updatedT;
    newHistory.sort((a, b) => b.date.compareTo(a.date));

    state = state.copyWith(history: newHistory);
    await StorageService.saveTransaction(db, updatedT);
  }

  // ==========================================
  // 👇 НОВА ЛОГІКА КОШИКА (Soft Delete)
  // ==========================================

  // 1. М'яке видалення в кошик
  Future<void> moveToTrash(Transaction t) async {
    final db = ref.read(databaseProvider);

    // ВАЖЛИВО: Скасовуємо вплив транзакції на баланси рахунків (повертаємо гроші)
    _updateAccountBalance(t.fromId, t.amount);
    _updateAccountBalance(t.toId, -(t.targetAmount ?? t.amount));

    // Встановлюємо дату видалення
    final trashedT = t.copyWith(deletedAt: drift.Value(DateTime.now()));
    await StorageService.saveTransaction(db, trashedT);

    await loadHistory(); // Оновлюємо списки
  }

  // 2. Відновлення з кошика
  Future<void> restoreFromTrash(Transaction t) async {
    final db = ref.read(databaseProvider);

    // ВАЖЛИВО: Знову застосовуємо вплив транзакції на баланси
    _updateAccountBalance(t.fromId, -t.amount);
    _updateAccountBalance(t.toId, (t.targetAmount ?? t.amount));

    // Очищаємо дату видалення
    final restoredT = t.copyWith(deletedAt: const drift.Value(null));
    await StorageService.saveTransaction(db, restoredT);

    await loadHistory();
  }

  // 3. Фізичне видалення назавжди (з кошика)
  Future<void> deletePermanently(Transaction t) async {
    final db = ref.read(databaseProvider);

    // Ми НЕ міняємо баланси, бо ми їх вже змінили під час moveToTrash!
    await StorageService.removeTransaction(db, t.id);
    await loadHistory();
  }

  // ==========================================

  Future<void> _migrateCurrentMonthBaseCurrency(String newBase) async {
    final db = ref.read(databaseProvider);
    final now = DateTime.now();
    final newHistory = List<Transaction>.from(state.history);

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

      final int newBaseAmount = await _calculateBaseAmountAsync(
        tx.amount,
        tx.currency,
        tx.targetAmount,
        tx.targetCurrency,
        newBase,
        tx.date,
      );

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
    state = state.copyWith(history: [], deletedHistory: []);

    // Тут в ідеалі теж треба було б чистити все через базу, але поки залишимо так
    await StorageService.saveHistory(db, []);
  }
}
