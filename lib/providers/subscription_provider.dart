import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../models/category_model.dart';
import '../models/transaction_model.dart';
import '../models/subscription_model.dart';
import '../services/storage_service.dart';
import '../services/subscription_service.dart';
import 'category_provider.dart';
import 'transaction_provider.dart';

class SubscriptionProvider extends ChangeNotifier {
  CategoryProvider? _catProv;
  TransactionProvider? _txProv;

  List<Subscription> subscriptions = [];
  List<Subscription> dueSubscriptions = [];
  Set<String> _ignoredSubIds = {};

  bool _isLoaded = false;

  // ДОДАНО: Геттер, який повертає true, якщо є хоча б одна прострочена підписка
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
  ) {
    _catProv = catProv;
    _txProv = txProv;

    // Завантажуємо підписки тільки коли обидва залежні провайдери готові
    if (!_isLoaded && !catProv.isLoading && !txProv.isLoading) {
      _isLoaded = true;
      loadSubscriptions();
    }
  }

  Future<void> loadSubscriptions() async {
    subscriptions = StorageService.getSubscriptions();

    // ДОДАНО: Завантажуємо список підписок, які користувач попросив ігнорувати
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
    if (_catProv == null || _txProv == null) {
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

    _catProv!.updateCategoryAmount(sourceAccount.id, -finalAmount);
    _catProv!.updateCategoryAmount(targetExpense.id, finalAmount);

    final newTx = Transaction(
      // ВИПРАВЛЕНО: Додано sub.id для унікальності, щоб уникнути дублів
      id: "${DateTime.now().millisecondsSinceEpoch}_${sub.id}",
      fromId: sourceAccount.id,
      toId: targetExpense.id,
      title: sub.name,
      amount: finalAmount,
      date: sub.nextPaymentDate,
    );

    _txProv!.addTransactionDirectly(newTx);

    // ВИПРАВЛЕНО: Зсуваємо дату рівно на 1 платіжний період
    await SubscriptionService.advanceOnePeriod(sub);

    // ДОДАНО: Якщо ми сплатили борг, прибираємо його зі списку проігнорованих
    _ignoredSubIds.remove(sub.id);
    StorageService.saveIgnoredSubscriptions(_ignoredSubIds.toList());

    _checkDueSubscriptions();
    notifyListeners();
    return (true, 'paid_success'.tr(args: [sub.name]));
  }

  // ДОДАНО: Новий метод для перманентного ігнорування
  void ignoreSubscriptionPermanently(String subId) {
    _ignoredSubIds.add(subId);
    StorageService.saveIgnoredSubscriptions(_ignoredSubIds.toList());
    _checkDueSubscriptions();
    notifyListeners();
  }

  // ДОДАНО: Метод, який буде викликатися при поверненні додатку з фону
  Future<void> refreshOnAppResume() async {
    if (!_isLoaded) return; // Якщо ще не завантажились, нічого не робимо

    await processAutoPayments();
    _checkDueSubscriptions();
    notifyListeners();
  }

  Future<void> processAutoPayments() async {
    if (_catProv == null || _txProv == null) return;

    DateTime now = DateTime.now();
    DateTime today = DateTime(now.year, now.month, now.day);
    bool processedAny = false;

    for (var sub in subscriptions) {
      if (!sub.isAutoPay) continue;

      // ДОДАНО: Цикл, який покроково списує борги за всі пропущені періоди
      while (true) {
        DateTime pDate = DateTime(
          sub.nextPaymentDate.year,
          sub.nextPaymentDate.month,
          sub.nextPaymentDate.day,
        );

        // Якщо дата платежу в майбутньому — виходимо з циклу, боргів немає
        if (pDate.isAfter(today)) break;

        final all = _catProv!.allCategoriesList;
        final account = all.where((c) => c.id == sub.accountId).firstOrNull;
        final expense = all.where((c) => c.id == sub.categoryId).firstOrNull;

        if (account != null &&
            expense != null &&
            account.amount >= sub.amount &&
            !account.isArchived &&
            !expense.isArchived) {
          _catProv!.updateCategoryAmount(account.id, -sub.amount);
          _catProv!.updateCategoryAmount(expense.id, sub.amount);

          final newTx = Transaction(
            // ДОДАНО: Унікальний ID, щоб транзакції в одну мілісекунду не перезаписували одна одну
            id: "${DateTime.now().millisecondsSinceEpoch}_${sub.id}_${pDate.millisecondsSinceEpoch}",
            fromId: account.id,
            toId: expense.id,
            title: 'auto_payment_marker'.tr(args: [sub.name]),
            amount: sub.amount,
            // ДОДАНО: Транзакція створюється "заднім числом", саме в той день, коли мала бути оплата
            date: sub.nextPaymentDate,
          );

          _txProv!.addTransactionDirectly(newTx);

          // Зсуваємо дату рівно на 1 період вперед і йдемо на наступне коло циклу
          await SubscriptionService.advanceOnePeriod(sub);
          processedAny = true;
        } else {
          // Якщо грошей не вистачає або категорію видалено — зупиняємо автооплату.
          // Ця підписка залишиться простроченою і користувач побачить її у вікні DueSubscriptionsDialog.
          break;
        }
      }
    }
    if (processedAny) notifyListeners();
  }

  Future<void> skipSubscriptionPayment(Subscription sub) async {
    // ВИПРАВЛЕНО: Зсуваємо дату рівно на 1 платіжний період
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
