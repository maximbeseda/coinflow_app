import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
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

    bool isMultiCurrency = sourceAccount.currency != targetExpense.currency;
    double? targetAmount;

    if (isMultiCurrency) {
      double? sRate = await _settingsProv!.getRateForDate(
        sourceAccount.currency,
        sub.nextPaymentDate,
      );
      double? tRate = await _settingsProv!.getRateForDate(
        targetExpense.currency,
        sub.nextPaymentDate,
      );

      if (sRate != null && tRate != null && sRate > 0) {
        targetAmount = finalAmount * (tRate / sRate);
      } else {
        // ВИПРАВЛЕНО: Беремо останній відомий курс з кешу, якщо API не відповідає
        double fallbackSRate =
            _settingsProv!.exchangeRates[sourceAccount.currency] ?? 1.0;
        double fallbackTRate =
            _settingsProv!.exchangeRates[targetExpense.currency] ?? 1.0;
        targetAmount = finalAmount * (fallbackTRate / fallbackSRate);
      }
    }

    _catProv!.updateCategoryAmount(sourceAccount.id, -finalAmount);
    _catProv!.updateCategoryAmount(
      targetExpense.id,
      targetAmount ?? finalAmount,
    );

    final newTx = Transaction(
      id: "${DateTime.now().millisecondsSinceEpoch}_${sub.id}",
      fromId: sourceAccount.id,
      toId: targetExpense.id,
      title: sub.name,
      amount: finalAmount,
      date: sub.nextPaymentDate,
      currency: sourceAccount.currency,
      targetAmount: targetAmount,
      targetCurrency: isMultiCurrency ? targetExpense.currency : null,
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

    for (var sub in subscriptions) {
      if (!sub.isAutoPay) continue;

      while (true) {
        DateTime pDate = DateTime(
          sub.nextPaymentDate.year,
          sub.nextPaymentDate.month,
          sub.nextPaymentDate.day,
        );

        if (pDate.isAfter(today)) break;

        final all = _catProv!.allCategoriesList;
        final account = all.where((c) => c.id == sub.accountId).firstOrNull;
        final expense = all.where((c) => c.id == sub.categoryId).firstOrNull;

        if (account != null &&
            expense != null &&
            account.amount >= sub.amount &&
            !account.isArchived &&
            !expense.isArchived) {
          bool isMultiCurrency = account.currency != expense.currency;
          double? targetAmount;

          if (isMultiCurrency) {
            double? sRate = await _settingsProv!.getRateForDate(
              account.currency,
              pDate,
            );
            double? tRate = await _settingsProv!.getRateForDate(
              expense.currency,
              pDate,
            );

            if (sRate != null && tRate != null && sRate > 0) {
              targetAmount = sub.amount * (tRate / sRate);
            } else {
              // ВИПРАВЛЕНО: Беремо останній відомий курс з кешу, якщо API не відповідає
              double fallbackSRate =
                  _settingsProv!.exchangeRates[account.currency] ?? 1.0;
              double fallbackTRate =
                  _settingsProv!.exchangeRates[expense.currency] ?? 1.0;
              targetAmount = sub.amount * (fallbackTRate / fallbackSRate);
            }
          }

          _catProv!.updateCategoryAmount(account.id, -sub.amount);
          _catProv!.updateCategoryAmount(
            expense.id,
            targetAmount ?? sub.amount,
          );

          final newTx = Transaction(
            id: "${DateTime.now().millisecondsSinceEpoch}_${sub.id}_${pDate.millisecondsSinceEpoch}",
            fromId: account.id,
            toId: expense.id,
            title: 'auto_payment_marker'.tr(args: [sub.name]),
            amount: sub.amount,
            date: sub.nextPaymentDate,
            currency: account.currency,
            targetAmount: targetAmount,
            targetCurrency: isMultiCurrency ? expense.currency : null,
          );

          _txProv!.addTransactionDirectly(newTx);

          await SubscriptionService.advanceOnePeriod(sub);
          processedAny = true;
        } else {
          break;
        }
      }
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
}
