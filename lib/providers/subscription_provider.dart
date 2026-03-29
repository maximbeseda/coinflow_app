import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:collection/collection.dart';
import '../models/category_model.dart';
import '../models/transaction_model.dart';
import '../models/subscription_model.dart';
import '../services/storage_service.dart';
import '../services/subscription_service.dart';
import 'category_provider.dart';
import 'transaction_provider.dart';
import 'settings_provider.dart';

class SubscriptionProvider extends ChangeNotifier {
  CategoryProvider? _catProv;
  TransactionProvider? _txProv;
  SettingsProvider? _settingsProv;

  List<Subscription> subscriptions = [];
  List<Subscription> dueSubscriptions = [];
  Set<String> _ignoredSubIds = {};

  bool _isLoaded = false;

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

  void updateDependencies(
    CategoryProvider catProv,
    TransactionProvider txProv,
    SettingsProvider settingsProv,
  ) {
    _catProv = catProv;
    _txProv = txProv;
    _settingsProv = settingsProv;

    if (!_isLoaded && !catProv.isLoading && !txProv.isLoading) {
      _isLoaded = true;
      loadSubscriptions();
    }
  }

  Future<void> loadSubscriptions() async {
    subscriptions = StorageService.getSubscriptions();
    _ignoredSubIds = StorageService.getIgnoredSubscriptions().toSet();

    await processAutoPayments();
    _checkDueSubscriptions();
    notifyListeners();
  }

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
    if (_catProv == null || _txProv == null || _settingsProv == null) {
      return (false, 'error_category_not_found'.tr());
    }

    final all = _catProv!.allCategoriesList;
    Category? sourceAccount;
    Category? targetExpense;

    sourceAccount = all.firstWhereOrNull((c) => c.id == sub.accountId);
    targetExpense = all.firstWhereOrNull((c) => c.id == sub.categoryId);

    if (sourceAccount == null || targetExpense == null) {
      return (false, 'error_category_not_found'.tr());
    }

    if (sourceAccount.isArchived || targetExpense.isArchived) {
      return (false, 'error_category_deleted'.tr());
    }

    // МИТТЄВИЙ ЛОКАЛЬНИЙ КЕШ замість API-запитів
    double subRate = _settingsProv!.exchangeRates[sub.currency] ?? 1.0;
    double accRate =
        _settingsProv!.exchangeRates[sourceAccount.currency] ?? 1.0;
    double expRate =
        _settingsProv!.exchangeRates[targetExpense.currency] ?? 1.0;

    if (accRate == 0) accRate = 1.0;
    if (expRate == 0) expRate = 1.0;

    double accountDeduction = finalAmount;
    if (sourceAccount.currency != sub.currency) {
      // Виправлена математична формула (Валюта1 -> Валюта2)
      double exactAmount = finalAmount * (subRate / accRate);
      accountDeduction = double.parse(exactAmount.toStringAsFixed(2));
    }

    double expenseAddition = finalAmount;
    if (targetExpense.currency != sub.currency) {
      double exactAmount = finalAmount * (subRate / expRate);
      expenseAddition = double.parse(exactAmount.toStringAsFixed(2));
    }

    if (sourceAccount.amount < accountDeduction) {
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
      // Делегуємо провайдеру транзакцій обчислення базової суми
      baseAmount: 0.0,
      baseCurrency: '',
    );

    _txProv!.addTransactionDirectly(newTx);

    await SubscriptionService.advanceOnePeriod(sub);

    _ignoredSubIds.remove(sub.id);
    StorageService.saveIgnoredSubscriptions(_ignoredSubIds.toList());

    _checkDueSubscriptions();
    notifyListeners();
    return (true, 'paid_success'.tr(args: [sub.name]));
  }

  void ignoreSubscriptionPermanently(String subId) {
    _ignoredSubIds.add(subId);
    StorageService.saveIgnoredSubscriptions(_ignoredSubIds.toList());
    _checkDueSubscriptions();
    notifyListeners();
  }

  Future<void> refreshOnAppResume() async {
    if (!_isLoaded) return;

    await processAutoPayments();
    _checkDueSubscriptions();
    notifyListeners();
  }

  Future<void> processAutoPayments() async {
    if (_catProv == null || _txProv == null || _settingsProv == null) return;

    DateTime now = DateTime.now();
    DateTime today = DateTime(now.year, now.month, now.day);
    bool processedAny = false;

    // Кешуємо транзакції, щоб додати їх усі разом
    List<Transaction> pendingTransactions = [];

    for (var sub in subscriptions) {
      if (!sub.isAutoPay) continue;

      final all = _catProv!.allCategoriesList;
      final account = all.where((c) => c.id == sub.accountId).firstOrNull;
      final expense = all.where((c) => c.id == sub.categoryId).firstOrNull;

      if (account == null ||
          expense == null ||
          account.isArchived ||
          expense.isArchived) {
        continue; // Акаунт або категорія відсутні/архівовані
      }

      double subRate = _settingsProv!.exchangeRates[sub.currency] ?? 1.0;
      double accRate = _settingsProv!.exchangeRates[account.currency] ?? 1.0;
      double expRate = _settingsProv!.exchangeRates[expense.currency] ?? 1.0;

      if (accRate == 0) accRate = 1.0;
      if (expRate == 0) expRate = 1.0;

      double accountDeduction = sub.amount;
      if (account.currency != sub.currency) {
        double exactAmount = sub.amount * (accRate / subRate);
        accountDeduction = double.parse(exactAmount.toStringAsFixed(2));
      }

      double expenseAddition = sub.amount;
      if (expense.currency != sub.currency) {
        double exactAmount = sub.amount * (expRate / subRate);
        expenseAddition = double.parse(exactAmount.toStringAsFixed(2));
      }

      bool isMultiCurrency = account.currency != expense.currency;

      // 👇 ЛОКАЛЬНА змінна для відстеження балансу (ВИПРАВЛЕНО БАГ!)
      double currentBalance = account.amount;
      bool subUpdated = false;

      while (true) {
        DateTime pDate = DateTime(
          sub.nextPaymentDate.year,
          sub.nextPaymentDate.month,
          sub.nextPaymentDate.day,
        );

        if (pDate.isAfter(today)) break;

        // Перевіряємо, чи вистачає поточного балансу
        if (currentBalance >= accountDeduction) {
          final newTx = Transaction(
            id: "${DateTime.now().millisecondsSinceEpoch}_${sub.id}_${pDate.millisecondsSinceEpoch}",
            fromId: account.id,
            toId: expense.id,
            title: 'auto_payment_marker'.tr(args: [sub.name]),
            amount: accountDeduction,
            date: sub.nextPaymentDate,
            currency: account.currency,
            targetAmount: isMultiCurrency ? expenseAddition : null,
            targetCurrency: isMultiCurrency ? expense.currency : null,
            baseAmount: 0.0, // Делегуємо провайдеру транзакцій
            baseCurrency: '',
          );

          pendingTransactions.add(newTx);
          currentBalance -=
              accountDeduction; // Віднімаємо гроші локально, щоб цикл був чесним

          // Оновлюємо реальні баланси в провайдері категорій
          _catProv!.updateCategoryAmount(account.id, -accountDeduction);
          _catProv!.updateCategoryAmount(expense.id, expenseAddition);

          // 👇 Обчислюємо нову дату платежу ЛОКАЛЬНО в пам'яті (БЕЗ Hive)
          if (sub.periodicity == 'monthly') {
            int nextMonth = pDate.month == 12 ? 1 : pDate.month + 1;
            int nextYear = pDate.month == 12 ? pDate.year + 1 : pDate.year;
            int nextDay = sub.nextPaymentDate.day;
            final lastDayOfNextMonth = DateTime(nextYear, nextMonth + 1, 0).day;
            if (nextDay > lastDayOfNextMonth) nextDay = lastDayOfNextMonth;
            sub.nextPaymentDate = DateTime(nextYear, nextMonth, nextDay);
          } else if (sub.periodicity == 'yearly') {
            sub.nextPaymentDate = DateTime(
              pDate.year + 1,
              pDate.month,
              pDate.day,
            );
          } else if (sub.periodicity == 'weekly') {
            sub.nextPaymentDate = pDate.add(const Duration(days: 7));
          }

          subUpdated = true;
          processedAny = true;
        } else {
          break; // Гроші закінчилися — зупиняємось
        }
      }

      // 👇 ЗБЕРІГАЄМО ПІДПИСКУ В БАЗУ ЛИШЕ 1 РАЗ ПІСЛЯ ЦИКЛУ
      if (subUpdated) {
        await StorageService.saveSubscription(sub);
      }
    }

    // 👇 ЗБЕРІГАЄМО ВСІ СТВОРЕНІ ТРАНЗАКЦІЇ
    for (var tx in pendingTransactions) {
      _txProv!.addTransactionDirectly(tx);
    }

    if (processedAny) notifyListeners();
  }

  Future<void> skipSubscriptionPayment(Subscription sub) async {
    await SubscriptionService.advanceOnePeriod(sub);
    _checkDueSubscriptions();
    notifyListeners();
  }

  void ignoreSubscriptionForSession(String subId) {
    _ignoredSubIds.add(subId);
    _checkDueSubscriptions();
    notifyListeners();
  }

  Future<void> clearAllSubscriptions() async {
    for (var sub in subscriptions) {
      await StorageService.deleteSubscription(sub.id);
    }
    subscriptions.clear();
    dueSubscriptions.clear();
    _ignoredSubIds.clear();
    await StorageService.saveIgnoredSubscriptions([]);
    notifyListeners();
  }
}
