import 'package:flutter/material.dart';
import '../models/category_model.dart';
import '../models/transaction_model.dart';
import '../models/subscription_model.dart';
import '../services/storage_service.dart';

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
    _checkDueSubscriptions();

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
      try {
        final fromCat = allCategories.firstWhere((c) => c.id == t.fromId);
        // Додаємо суму тільки якщо категорія ще активна (не в архіві)
        if (fromCat.type == CategoryType.income && !fromCat.isArchived) {
          incomes.firstWhere((c) => c.id == t.fromId).amount += t.amount;
        }
      } catch (_) {}

      try {
        final toCat = allCategories.firstWhere((c) => c.id == t.toId);
        // Додаємо суму тільки якщо категорія ще активна (не в архіві)
        if (toCat.type == CategoryType.expense && !toCat.isArchived) {
          expenses.firstWhere((c) => c.id == t.toId).amount += t.amount;
        }
      } catch (_) {}
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
    // ВИПРАВЛЕНО: Використовуємо загальний геттер
    final all = allCategoriesList;
    try {
      final src = all.firstWhere((c) => c.id == oldT.fromId);
      final dst = all.firstWhere((c) => c.id == oldT.toId);

      if (src.type == CategoryType.account) src.amount += oldT.amount;
      if (dst.type == CategoryType.account) dst.amount -= oldT.amount;

      oldT.amount = newAmount;
      oldT.date = newDate;

      if (src.type == CategoryType.account) src.amount -= oldT.amount;
      if (dst.type == CategoryType.account) dst.amount += oldT.amount;

      history.sort((a, b) => b.date.compareTo(a.date));
      _recalculateMonthTotals();

      StorageService.saveTransaction(oldT);
      StorageService.saveCategory(src);
      StorageService.saveCategory(dst);
      notifyListeners();
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  void deleteTransaction(Transaction t) {
    // ВИПРАВЛЕНО: Використовуємо загальний геттер
    final all = allCategoriesList;
    try {
      final src = all.firstWhere((c) => c.id == t.fromId);
      final dst = all.firstWhere((c) => c.id == t.toId);

      if (src.type == CategoryType.account) src.amount += t.amount;
      if (dst.type == CategoryType.account) dst.amount -= t.amount;

      StorageService.saveCategory(src);
      StorageService.saveCategory(dst);
    } catch (e) {
      debugPrint(e.toString());
    }

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
    _checkDueSubscriptions();
    notifyListeners();
  }

  Future<void> updateSubscription(Subscription updatedSub) async {
    int index = subscriptions.indexWhere((s) => s.id == updatedSub.id);
    if (index != -1) {
      subscriptions[index] = updatedSub;
      await StorageService.saveSubscription(updatedSub);
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
    } catch (e) {
      // Якщо юзер випадково видалив рахунок або категорію, до якої прив'язана підписка
      return (
        false,
        "Помилка: Рахунок або категорію для цієї підписки було видалено.",
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

    await _shiftSubscriptionDate(sub);

    return (true, "Оплачено: ${sub.name} 🎉");
  }

  // --- ОНОВЛЕНИЙ МЕТОД ПЕРЕНЕСЕННЯ ДАТИ ---
  Future<void> _shiftSubscriptionDate(Subscription sub) async {
    DateTime now = DateTime.now();
    DateTime today = DateTime(now.year, now.month, now.day); // 00:00:00

    // ФІКС БАГУ: Очищаємо години і хвилини з дати підписки!
    // Тепер обидві дати будуть рівно на 00:00:00 і порівняння спрацює ідеально.
    DateTime nextDate = DateTime(
      sub.nextPaymentDate.year,
      sub.nextPaymentDate.month,
      sub.nextPaymentDate.day,
    );

    while (nextDate.isBefore(today) || nextDate.isAtSameMomentAs(today)) {
      if (sub.periodicity == 'monthly') {
        int nextMonth = nextDate.month == 12 ? 1 : nextDate.month + 1;
        int nextYear = nextDate.month == 12 ? nextDate.year + 1 : nextDate.year;

        int nextDay = sub.nextPaymentDate.day;
        final lastDayOfNextMonth = DateTime(nextYear, nextMonth + 1, 0).day;
        if (nextDay > lastDayOfNextMonth) nextDay = lastDayOfNextMonth;

        nextDate = DateTime(nextYear, nextMonth, nextDay);
      } else if (sub.periodicity == 'yearly') {
        nextDate = DateTime(nextDate.year + 1, nextDate.month, nextDate.day);
      } else if (sub.periodicity == 'weekly') {
        nextDate = nextDate.add(const Duration(days: 7));
      }
    }

    sub.nextPaymentDate = nextDate;

    await StorageService.saveSubscription(sub);
    _checkDueSubscriptions();
    notifyListeners();
  }

  // Викликається, коли користувач вирішив пропустити платіж
  Future<void> skipSubscriptionPayment(Subscription sub) async {
    await _shiftSubscriptionDate(sub);
  }

  // Метод для тимчасового приховування вікна оплати
  void ignoreSubscriptionForSession(String subId) {
    _ignoredSubIds.add(subId);
    _checkDueSubscriptions();
  }
}
