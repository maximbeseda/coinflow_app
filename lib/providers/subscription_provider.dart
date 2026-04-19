import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:collection/collection.dart';
import 'package:drift/drift.dart' as drift; // 👇 ДОДАНО для роботи з deletedAt

import '../database/app_database.dart';
import '../services/storage_service.dart';
import '../services/subscription_service.dart';

// Імпортуємо наш хаб провайдерів
import 'all_providers.dart';

part 'subscription_provider.g.dart';

class SubscriptionState {
  final List<Subscription> subscriptions;
  final List<Subscription> dueSubscriptions;
  final List<Subscription> deletedSubscriptions; // 👇 НОВЕ: Кошик підписок
  final Set<String> ignoredSubIds;

  SubscriptionState({
    required this.subscriptions,
    required this.dueSubscriptions,
    required this.deletedSubscriptions,
    required this.ignoredSubIds,
  });

  SubscriptionState copyWith({
    List<Subscription>? subscriptions,
    List<Subscription>? dueSubscriptions,
    List<Subscription>? deletedSubscriptions,
    Set<String>? ignoredSubIds,
  }) {
    return SubscriptionState(
      subscriptions: subscriptions ?? this.subscriptions,
      dueSubscriptions: dueSubscriptions ?? this.dueSubscriptions,
      deletedSubscriptions: deletedSubscriptions ?? this.deletedSubscriptions,
      ignoredSubIds: ignoredSubIds ?? this.ignoredSubIds,
    );
  }

  bool get hasPendingPayments {
    DateTime now = DateTime.now();
    DateTime today = DateTime(now.year, now.month, now.day);

    return subscriptions.any((sub) {
      DateTime pDate = DateTime(
        sub.nextPaymentDate.year,
        sub.nextPaymentDate.month,
        sub.nextPaymentDate.day,
      );
      return pDate.isBefore(today) || pDate.isAtSameMomentAs(today);
    });
  }
}

@Riverpod(keepAlive: true)
class SubscriptionNotifier extends _$SubscriptionNotifier {
  @override
  SubscriptionState build() {
    final initialState = SubscriptionState(
      subscriptions: [],
      dueSubscriptions: [],
      deletedSubscriptions: [], // 👇 Ініціалізація
      ignoredSubIds: {},
    );

    Future.microtask(() => loadSubscriptions());

    return initialState;
  }

  Future<void> loadSubscriptions() async {
    final db = ref.read(databaseProvider);
    final allSubs = await StorageService.getSubscriptions(db);
    final ignored = StorageService.getIgnoredSubscriptions().toSet();

    // 👇 ФІЛЬТРУЄМО АКТИВНІ ТА ВИДАЛЕНІ
    final activeSubs = allSubs.where((s) => s.deletedAt == null).toList();
    final deletedSubs = allSubs.where((s) => s.deletedAt != null).toList();

    state = state.copyWith(
      subscriptions: activeSubs,
      deletedSubscriptions: deletedSubs,
      ignoredSubIds: ignored,
    );

    await processAutoPayments();
    _checkDueSubscriptions();
  }

  void _checkDueSubscriptions() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final due = state.subscriptions.where((sub) {
      if (state.ignoredSubIds.contains(sub.id)) return false;
      final paymentDate = DateTime(
        sub.nextPaymentDate.year,
        sub.nextPaymentDate.month,
        sub.nextPaymentDate.day,
      );
      return paymentDate.isBefore(today) || paymentDate.isAtSameMomentAs(today);
    }).toList();

    state = state.copyWith(dueSubscriptions: due);
  }

  Future<void> addSubscription(Subscription sub) async {
    final db = ref.read(databaseProvider);
    final newSubs = List<Subscription>.from(state.subscriptions)..add(sub);
    state = state.copyWith(subscriptions: newSubs);

    await StorageService.saveSubscription(db, sub);
    await processAutoPayments();
    _checkDueSubscriptions();
  }

  Future<void> updateSubscription(Subscription updatedSub) async {
    final db = ref.read(databaseProvider);
    final newSubs = List<Subscription>.from(state.subscriptions);
    int index = newSubs.indexWhere((s) => s.id == updatedSub.id);
    if (index != -1) {
      newSubs[index] = updatedSub;
      state = state.copyWith(subscriptions: newSubs);

      await StorageService.saveSubscription(db, updatedSub);
      await processAutoPayments();
      _checkDueSubscriptions();
    }
  }

  // ==========================================
  // 👇 НОВА ЛОГІКА КОШИКА ТА ВИДАЛЕННЯ
  // ==========================================

  // 1. М'яке видалення в кошик
  Future<void> moveToTrash(Subscription sub) async {
    final db = ref.read(databaseProvider);

    // Встановлюємо дату видалення
    final deletedSub = sub.copyWith(deletedAt: drift.Value(DateTime.now()));
    await StorageService.saveSubscription(db, deletedSub);

    await loadSubscriptions(); // Перезавантажуємо списки
  }

  // 2. Відновлення з кошика
  Future<void> restoreFromTrash(Subscription sub) async {
    final db = ref.read(databaseProvider);

    // Очищаємо дату видалення
    final restoredSub = sub.copyWith(deletedAt: const drift.Value(null));
    await StorageService.saveSubscription(db, restoredSub);

    await loadSubscriptions();
  }

  // 3. Фізичне видалення назавжди (з кошика)
  Future<void> deletePermanently(String id) async {
    final db = ref.read(databaseProvider);

    await StorageService.deleteSubscription(db, id);
    await loadSubscriptions();
  }

  // ==========================================

  Future<(bool, String)> confirmSubscriptionPayment(
    Subscription sub,
    int finalAmount,
  ) async {
    final db = ref.read(databaseProvider);
    final catState = ref.read(categoryProvider);
    final txNotifier = ref.read(transactionProvider.notifier);
    final settingsState = ref.read(settingsProvider);

    final all = catState.allCategoriesList;
    final sourceAccount = all.firstWhereOrNull((c) => c.id == sub.accountId);
    final targetExpense = all.firstWhereOrNull((c) => c.id == sub.categoryId);

    if (sourceAccount == null || targetExpense == null) {
      return (false, 'error_category_not_found'.tr());
    }

    if (sourceAccount.isArchived || targetExpense.isArchived) {
      return (false, 'error_category_deleted'.tr());
    }

    final currentDue = List<Subscription>.from(state.dueSubscriptions)
      ..removeWhere((s) => s.id == sub.id);
    state = state.copyWith(dueSubscriptions: currentDue);

    double subRate = settingsState.exchangeRates[sub.currency] ?? 1.0;
    double accRate = settingsState.exchangeRates[sourceAccount.currency] ?? 1.0;
    double expRate = settingsState.exchangeRates[targetExpense.currency] ?? 1.0;

    if (accRate == 0) accRate = 1.0;
    if (expRate == 0) expRate = 1.0;

    int accountDeduction = finalAmount;
    if (sourceAccount.currency != sub.currency) {
      accountDeduction = (finalAmount * (accRate / subRate)).round();
    }

    int expenseAddition = finalAmount;
    if (targetExpense.currency != sub.currency) {
      expenseAddition = (finalAmount * (expRate / subRate)).round();
    }

    if (sourceAccount.amount < accountDeduction) {
      _checkDueSubscriptions();
      return (false, 'not_enough_funds'.tr(args: [sourceAccount.name]));
    }

    bool isMultiCurrency = sourceAccount.currency != targetExpense.currency;

    final newTx = Transaction(
      id: "${DateTime.now().millisecondsSinceEpoch}_${sub.id}",
      fromId: sourceAccount.id,
      toId: targetExpense.id,
      title: sub.name,
      amount: accountDeduction,
      date: sub.nextPaymentDate,
      currency: sourceAccount.currency,
      targetAmount: isMultiCurrency ? expenseAddition : null,
      targetCurrency: isMultiCurrency ? targetExpense.currency : null,
      baseAmount: 0,
      baseCurrency: '',
    );

    txNotifier.addTransactionDirectly(newTx);

    await SubscriptionService.advanceOnePeriod(db, sub);

    final newIgnored = Set<String>.from(state.ignoredSubIds)..remove(sub.id);
    state = state.copyWith(ignoredSubIds: newIgnored);
    await StorageService.saveIgnoredSubscriptions(newIgnored.toList());

    await loadSubscriptions();
    return (true, 'paid_success'.tr(args: [sub.name]));
  }

  void ignoreSubscriptionPermanently(String subId) {
    final newIgnored = Set<String>.from(state.ignoredSubIds)..add(subId);
    state = state.copyWith(ignoredSubIds: newIgnored);
    StorageService.saveIgnoredSubscriptions(newIgnored.toList());
    _checkDueSubscriptions();
  }

  Future<void> refreshOnAppResume() async {
    await processAutoPayments();
    _checkDueSubscriptions();
  }

  Future<void> processAutoPayments() async {
    final db = ref.read(databaseProvider);
    final catState = ref.read(categoryProvider);
    final txNotifier = ref.read(transactionProvider.notifier);
    final settingsState = ref.read(settingsProvider);

    DateTime now = DateTime.now();
    DateTime today = DateTime(now.year, now.month, now.day);
    bool processedAny = false;

    List<Transaction> pendingTransactions = [];
    List<Subscription> updatedSubs = [];

    // 👇 Цикл йде ТІЛЬКИ по активних підписках (state.subscriptions)
    for (var sub in state.subscriptions) {
      if (!sub.isAutoPay) continue;

      final all = catState.allCategoriesList;
      final account = all.where((c) => c.id == sub.accountId).firstOrNull;
      final expense = all.where((c) => c.id == sub.categoryId).firstOrNull;

      if (account == null ||
          expense == null ||
          account.isArchived ||
          expense.isArchived) {
        continue;
      }

      double subRate = settingsState.exchangeRates[sub.currency] ?? 1.0;
      double accRate = settingsState.exchangeRates[account.currency] ?? 1.0;
      double expRate = settingsState.exchangeRates[expense.currency] ?? 1.0;

      if (accRate == 0) accRate = 1.0;
      if (expRate == 0) expRate = 1.0;

      int accountDeduction = sub.amount;
      if (account.currency != sub.currency) {
        accountDeduction = (sub.amount * (accRate / subRate)).round();
      }

      int expenseAddition = sub.amount;
      if (expense.currency != sub.currency) {
        expenseAddition = (sub.amount * (expRate / subRate)).round();
      }

      bool isMultiCurrency = account.currency != expense.currency;
      int currentBalance = account.amount;
      bool subUpdated = false;
      var currentSub = sub;

      while (true) {
        DateTime pDate = DateTime(
          currentSub.nextPaymentDate.year,
          currentSub.nextPaymentDate.month,
          currentSub.nextPaymentDate.day,
        );

        if (pDate.isAfter(today)) break;

        if (currentBalance >= accountDeduction) {
          final newTx = Transaction(
            id: "${DateTime.now().millisecondsSinceEpoch}_${currentSub.id}_${pDate.millisecondsSinceEpoch}",
            fromId: account.id,
            toId: expense.id,
            title: 'auto_payment_marker'.tr(args: [currentSub.name]),
            amount: accountDeduction,
            date: currentSub.nextPaymentDate,
            currency: account.currency,
            targetAmount: isMultiCurrency ? expenseAddition : null,
            targetCurrency: isMultiCurrency ? expense.currency : null,
            baseAmount: 0,
            baseCurrency: '',
          );

          pendingTransactions.add(newTx);
          currentBalance -= accountDeduction;

          if (currentSub.periodicity == 'monthly') {
            int nextMonth = pDate.month == 12 ? 1 : pDate.month + 1;
            int nextYear = pDate.month == 12 ? pDate.year + 1 : pDate.year;
            int nextDay = currentSub.nextPaymentDate.day;
            final lastDayOfNextMonth = DateTime(nextYear, nextMonth + 1, 0).day;
            if (nextDay > lastDayOfNextMonth) nextDay = lastDayOfNextMonth;
            currentSub = currentSub.copyWith(
              nextPaymentDate: DateTime(nextYear, nextMonth, nextDay),
            );
          } else if (currentSub.periodicity == 'yearly') {
            currentSub = currentSub.copyWith(
              nextPaymentDate: DateTime(pDate.year + 1, pDate.month, pDate.day),
            );
          } else if (currentSub.periodicity == 'weekly') {
            currentSub = currentSub.copyWith(
              nextPaymentDate: pDate.add(const Duration(days: 7)),
            );
          }

          subUpdated = true;
          processedAny = true;
        } else {
          break;
        }
      }

      if (subUpdated) {
        updatedSubs.add(currentSub);
        await StorageService.saveSubscription(db, currentSub);
      }
    }

    for (var tx in pendingTransactions) {
      txNotifier.addTransactionDirectly(tx);
    }

    if (processedAny) {
      final newSubs = List<Subscription>.from(state.subscriptions);
      for (var us in updatedSubs) {
        int index = newSubs.indexWhere((s) => s.id == us.id);
        if (index != -1) newSubs[index] = us;
      }
      state = state.copyWith(subscriptions: newSubs);
    }
  }

  Future<void> skipSubscriptionPayment(Subscription sub) async {
    final currentDue = List<Subscription>.from(state.dueSubscriptions)
      ..removeWhere((s) => s.id == sub.id);
    state = state.copyWith(dueSubscriptions: currentDue);

    final db = ref.read(databaseProvider);
    await SubscriptionService.advanceOnePeriod(db, sub);
    await loadSubscriptions();
  }

  void ignoreSubscriptionForSession(String subId) {
    final newIgnored = Set<String>.from(state.ignoredSubIds)..add(subId);
    state = state.copyWith(ignoredSubIds: newIgnored);
    _checkDueSubscriptions();
  }

  Future<void> clearAllSubscriptions() async {
    final db = ref.read(databaseProvider);

    // 👇 ВИПРАВЛЕНО: Видаляємо як активні, так і ті, що вже в кошику
    for (var sub in [...state.subscriptions, ...state.deletedSubscriptions]) {
      await StorageService.deleteSubscription(db, sub.id);
    }

    await StorageService.saveIgnoredSubscriptions([]);
    state = state.copyWith(
      subscriptions: [],
      dueSubscriptions: [],
      deletedSubscriptions: [],
      ignoredSubIds: {},
    );
  }
}
