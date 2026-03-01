import 'package:flutter/material.dart';
import '../models/category_model.dart';
import '../models/transaction_model.dart';
import '../models/subscription_model.dart';
import '../services/storage_service.dart';
import '../services/subscription_service.dart';

class FinanceProvider extends ChangeNotifier {
  List<Category> incomes = [];
  List<Category> accounts = [];
  List<Category> expenses = [];
  List<Transaction> history = [];
  List<Category> archivedCategories =
      []; // ДОДАНО: Сховище для видалених категорій

  // ДОДАНО: Геттер, який об'єднує всі категорії. Потрібен, щоб історія не губила іконки видалених категорій.
  List<Category> get allCategoriesList => [
    ...incomes,
    ...accounts,
    ...expenses,
    ...archivedCategories,
  ];

  // --- ПІДПИСКИ ---
  List<Subscription> subscriptions = []; // Всі підписки
  List<Subscription> dueSubscriptions =
      []; // Ті, що потребують підтвердження САМЕ СЬОГОДНІ
  final Set<String> _ignoredSubIds = {}; // Підписки, які юзер закрив хрестиком

  DateTime selectedMonth = DateTime(
    DateTime.now().year,
    DateTime.now().month,
    1,
  );
  bool isLoading = true;

  bool get isCurrentMonth {
    final now = DateTime.now();
    return selectedMonth.year == now.year && selectedMonth.month == now.month;
  }

  FinanceProvider() {
    loadData();
  }

  Future<void> loadData() async {
    final savedCats = await StorageService.loadCategories();

    if (savedCats.isNotEmpty) {
      // Завантажуємо тільки АКТИВНІ категорії в основні списки UI
      incomes = savedCats
          .where((c) => c.type == CategoryType.income && !c.isArchived)
          .toList();
      accounts = savedCats
          .where((c) => c.type == CategoryType.account && !c.isArchived)
          .toList();
      expenses = savedCats
          .where((c) => c.type == CategoryType.expense && !c.isArchived)
          .toList();

      // Завантажуємо видалені категорії в архів
      archivedCategories = savedCats.where((c) => c.isArchived).toList();
    }

    final loadedHistory = await StorageService.loadHistory();
    history = loadedHistory;
    history.sort((a, b) => b.date.compareTo(a.date));

    // ДОДАНО: Завантажуємо підписки і одразу перевіряємо, чи є прострочені/актуальні
    subscriptions = StorageService.getSubscriptions();
    await processAutoPayments(); // Спершу тихо списуємо автоматичні
    _checkDueSubscriptions(); // Потім шукаємо борги для ручних

    _recalculateMonthTotals();
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

  void _recalculateMonthTotals() {
    final now = DateTime.now(); // Жорстко фіксуємо поточний час

    for (var inc in incomes) {
      inc.amount = 0.0;
    }
    for (var exp in expenses) {
      exp.amount = 0.0;
    }

    final currentMonthHistory = history
        .where((t) => t.date.year == now.year && t.date.month == now.month)
        .toList();

    // ВИПРАВЛЕНО: Використовуємо загальний геттер (щоб бачити і архівні)
    final allCategories = allCategoriesList;

    for (var t in currentMonthHistory) {
      // Шукаємо категорію безпечним методом (без try-catch)
      // firstOrNull поверне null, якщо категорію не знайдено, і не зламає додаток
      final fromCat = allCategories.where((c) => c.id == t.fromId).firstOrNull;
      final toCat = allCategories.where((c) => c.id == t.toId).firstOrNull;

      if (fromCat != null &&
          fromCat.type == CategoryType.income &&
          !fromCat.isArchived) {
        // Знаходимо саме ту категорію в списку доходів, щоб оновити її суму
        final targetIncome = incomes.where((c) => c.id == t.fromId).firstOrNull;
        if (targetIncome != null) {
          targetIncome.amount += t.amount;
        }
      } else if (fromCat == null) {
        debugPrint(
          "Увага: Знайдено осиротілу транзакцію доходу ${t.id}. Категорія ${t.fromId} відсутня.",
        );
      }

      if (toCat != null &&
          toCat.type == CategoryType.expense &&
          !toCat.isArchived) {
        // Знаходимо саме ту категорію в списку витрат
        final targetExpense = expenses.where((c) => c.id == t.toId).firstOrNull;
        if (targetExpense != null) {
          targetExpense.amount += t.amount;
        }
      } else if (toCat == null) {
        debugPrint(
          "Увага: Знайдено осиротілу транзакцію витрати ${t.id}. Категорія ${t.toId} відсутня.",
        );
      }
    }
  }

  void addTransfer(
    Category source,
    Category target,
    double amount,
    DateTime date,
  ) {
    if (source.type == CategoryType.account) source.amount -= amount;
    if (target.type == CategoryType.account) target.amount += amount;

    final newTx = Transaction(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      fromId: source.id,
      toId: target.id,
      title: target.name,
      amount: amount,
      date: date,
    );

    history.insert(0, newTx);
    history.sort((a, b) => b.date.compareTo(a.date));

    _recalculateMonthTotals();
    StorageService.saveTransaction(newTx);
    StorageService.saveCategory(source);
    StorageService.saveCategory(target);
    notifyListeners();
  }

  void editTransaction(Transaction oldT, double newAmount, DateTime newDate) {
    final all = allCategoriesList;

    // Шукаємо безпечно
    final src = all.where((c) => c.id == oldT.fromId).firstOrNull;
    final dst = all.where((c) => c.id == oldT.toId).firstOrNull;

    // 1. Повертаємо старі гроші на баланс (відміна старої операції)
    if (src != null && src.type == CategoryType.account) {
      src.amount += oldT.amount;
    }
    if (dst != null && dst.type == CategoryType.account) {
      dst.amount -= oldT.amount;
    }

    // 2. Оновлюємо дані транзакції
    oldT.amount = newAmount;
    oldT.date = newDate;

    // 3. Віднімаємо нові гроші з балансу (застосування нової операції)
    if (src != null && src.type == CategoryType.account) {
      src.amount -= oldT.amount;
    }
    if (dst != null && dst.type == CategoryType.account) {
      dst.amount += oldT.amount;
    }

    history.sort((a, b) => b.date.compareTo(a.date));
    _recalculateMonthTotals();

    StorageService.saveTransaction(oldT);
    if (src != null) StorageService.saveCategory(src);
    if (dst != null) StorageService.saveCategory(dst);
    notifyListeners();
  }

  void deleteTransaction(Transaction t) {
    final all = allCategoriesList;

    // Шукаємо безпечно
    final src = all.where((c) => c.id == t.fromId).firstOrNull;
    final dst = all.where((c) => c.id == t.toId).firstOrNull;

    // Відкочуємо баланси тільки якщо рахунки існують
    if (src != null && src.type == CategoryType.account) src.amount += t.amount;
    if (dst != null && dst.type == CategoryType.account) dst.amount -= t.amount;

    if (src != null) StorageService.saveCategory(src);
    if (dst != null) StorageService.saveCategory(dst);

    history.removeWhere((item) => item.id == t.id);
    _recalculateMonthTotals();
    StorageService.removeTransaction(t.id);
    notifyListeners();
  }

  void addOrUpdateCategory(Category cat) {
    List<Category> targetList;

    if (cat.type == CategoryType.income) {
      targetList = incomes;
    } else if (cat.type == CategoryType.account) {
      targetList = accounts;
    } else {
      targetList = expenses;
    }

    int index = targetList.indexWhere((c) => c.id == cat.id);

    if (index == -1) {
      targetList.add(cat);
    } else {
      targetList[index] = cat;
    }

    StorageService.saveCategory(cat);
    notifyListeners();
  }

  void deleteCategory(Category cat) {
    // 1. Ставимо мітку "Архівовано" і зберігаємо в базу
    cat.isArchived = true;
    StorageService.saveCategory(cat);

    // 2. Прибираємо категорію з екрана (видаляємо з активних списків)
    if (cat.type == CategoryType.income) {
      incomes.remove(cat);
    } else if (cat.type == CategoryType.account) {
      accounts.remove(cat);
    } else {
      expenses.remove(cat);
    }

    // 3. Відправляємо в архів (щоб транзакції в історії все ще мали іконку та ім'я)
    archivedCategories.add(cat);

    notifyListeners();
  }

  void reorderCategories(Category dragged, Category target) {
    if (dragged.type != target.type) return;

    List<Category> targetList;
    if (dragged.type == CategoryType.income) {
      targetList = incomes;
    } else if (dragged.type == CategoryType.account) {
      targetList = accounts;
    } else {
      targetList = expenses;
    }

    int oldIndex = targetList.indexWhere((c) => c.id == dragged.id);
    int newIndex = targetList.indexWhere((c) => c.id == target.id);

    if (oldIndex != -1 && newIndex != -1 && oldIndex != newIndex) {
      final item = targetList.removeAt(oldIndex);
      targetList.insert(newIndex, item);

      StorageService.saveCategories([
        ...incomes,
        ...accounts,
        ...expenses,
        ...archivedCategories,
      ]);
      notifyListeners();
    }
  }

  // ==========================================
  // ЛОГІКА РЕГУЛЯРНИХ ПЛАТЕЖІВ (ПІДПИСОК)
  // ==========================================

  void _checkDueSubscriptions() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    dueSubscriptions = subscriptions.where((sub) {
      // ФІКС: Якщо юзер натиснув хрестик, ми ігноруємо цю підписку до перезапуску додатка
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

  // --- ОНОВЛЕНИЙ МЕТОД ОПЛАТИ ---
  // Тепер він повертає bool (успіх/помилка) та String (повідомлення для SnackBar)
  Future<(bool, String)> confirmSubscriptionPayment(
    Subscription sub,
    double finalAmount,
  ) async {
    // ВИПРАВЛЕНО: Використовуємо загальний геттер
    final allCategories = allCategoriesList;
    Category? sourceAccount;
    Category? targetExpense;

    try {
      sourceAccount = allCategories.firstWhere((c) => c.id == sub.accountId);
      targetExpense = allCategories.firstWhere((c) => c.id == sub.categoryId);

      // --- ДОДАЄМО ЦЕЙ БЛОК: Захист від оплати у видалену категорію ---
      if (sourceAccount.isArchived || targetExpense.isArchived) {
        return (
          false,
          "Помилка: Рахунок або категорію для цієї підписки видалено. Відредагуйте підписку.",
        );
      }
    } catch (e) {
      // Якщо юзер випадково повністю видалив рахунок з бази (хоча у нас є архів)
      return (
        false,
        "Помилка: Рахунок або категорію для цієї підписки не знайдено.",
      );
    }

    // Перевірка на від'ємний баланс (опціонально, але корисно для UX)
    if (sourceAccount.amount < finalAmount) {
      return (
        false,
        "Недостатньо коштів на рахунку '${sourceAccount.name}' 😔",
      );
    }

    // Віднімаємо гроші
    sourceAccount.amount -= finalAmount;

    final newTx = Transaction(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      fromId: sourceAccount.id,
      toId: targetExpense.id,
      title: sub.name,
      amount: finalAmount,
      date: sub.nextPaymentDate,
    );

    history.insert(0, newTx);
    history.sort((a, b) => b.date.compareTo(a.date));

    _recalculateMonthTotals();

    await StorageService.saveTransaction(newTx);
    await StorageService.saveCategory(sourceAccount);
    await StorageService.saveCategory(targetExpense);

    await SubscriptionService.shiftSubscriptionDate(sub);
    _checkDueSubscriptions(); // Перераховуємо, чи лишилися ще борги
    notifyListeners(); // Даємо команду UI оновитися

    return (true, "Оплачено: ${sub.name} 🎉");
  }

  // Викликається, коли користувач вирішив пропустити платіж
  Future<void> skipSubscriptionPayment(Subscription sub) async {
    await SubscriptionService.shiftSubscriptionDate(sub);
    _checkDueSubscriptions(); // Додаємо оновлення UI
    notifyListeners();
  }

  Future<void> processAutoPayments() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    bool processedAny = false;

    for (var sub in subscriptions) {
      if (!sub.isAutoPay) continue; // Ігноруємо ті, де автосписання вимкнено

      final paymentDate = DateTime(
        sub.nextPaymentDate.year,
        sub.nextPaymentDate.month,
        sub.nextPaymentDate.day,
      );

      // Якщо час платити настав
      if (paymentDate.isBefore(today) || paymentDate.isAtSameMomentAs(today)) {
        final account = allCategoriesList
            .where((c) => c.id == sub.accountId)
            .firstOrNull;
        final expense = allCategoriesList
            .where((c) => c.id == sub.categoryId)
            .firstOrNull;

        // ПЕРЕВІРКА: Рахунки існують, не видалені, і ГРОШЕЙ ДОСТАТНЬО
        if (account != null &&
            expense != null &&
            account.amount >= sub.amount &&
            !account.isArchived &&
            !expense.isArchived) {
          account.amount -= sub.amount; // Тихо списуємо гроші

          final newTx = Transaction(
            id: "${DateTime.now().millisecondsSinceEpoch}_${sub.id}", // Унікальний ID
            fromId: account.id,
            toId: expense.id,
            title: "${sub.name} (Авто)", // Додаємо маркер, що це автосписання
            amount: sub.amount,
            date: sub.nextPaymentDate,
          );

          history.insert(0, newTx);
          await StorageService.saveTransaction(newTx);
          await StorageService.saveCategory(account);
          await StorageService.saveCategory(expense);

          await SubscriptionService.shiftSubscriptionDate(
            sub,
          ); // Переносимо дату
          processedAny = true;
        }
        // Якщо грошей мало — ми просто пропускаємо її.
        // Вона потрапить у _checkDueSubscriptions() і покаже вікно ручної оплати!
      }
    }

    if (processedAny) {
      history.sort((a, b) => b.date.compareTo(a.date));
      _recalculateMonthTotals();
      notifyListeners();
    }
  }

  // Метод для тимчасового приховування вікна оплати
  void ignoreSubscriptionForSession(String subId) {
    _ignoredSubIds.add(subId);
    _checkDueSubscriptions();
  }
}
