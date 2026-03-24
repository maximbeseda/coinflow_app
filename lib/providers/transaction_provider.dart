import 'package:flutter/material.dart';
import '../models/category_model.dart';
import '../models/transaction_model.dart';
import '../services/storage_service.dart';
import 'category_provider.dart';
import 'settings_provider.dart';

class TransactionProvider extends ChangeNotifier {
  CategoryProvider? _catProv;
  SettingsProvider? _settingsProv;
  String? _lastKnownBaseCurrency;

  List<Transaction> history = [];
  DateTime selectedMonth = DateTime(
    DateTime.now().year,
    DateTime.now().month,
    1,
  );
  bool isLoading = true;

  DateTime? _cachedMonth;
  List<Transaction> _cachedMonthHistory = [];

  List<Transaction> _getHistoryForMonth(DateTime month) {
    if (_cachedMonth != null &&
        _cachedMonth!.year == month.year &&
        _cachedMonth!.month == month.month) {
      return _cachedMonthHistory;
    }
    _cachedMonth = month;
    _cachedMonthHistory = history
        .where((t) => t.date.year == month.year && t.date.month == month.month)
        .toList();
    return _cachedMonthHistory;
  }

  void _invalidateCache() {
    _cachedMonth = null;
  }

  TransactionProvider() {
    loadHistory();
  }

  void updateDependencies(
    CategoryProvider catProv,
    SettingsProvider settingsProv,
  ) {
    _catProv = catProv;
    _settingsProv = settingsProv;

    if (_settingsProv != null) {
      final currentBase = _settingsProv!.baseCurrency;

      // 👇 МАГІЯ ТУТ: Якщо валюта змінилася (і це не перша ініціалізація)
      if (_lastKnownBaseCurrency != null &&
          _lastKnownBaseCurrency != currentBase) {
        debugPrint(
          "🔄 Виявлено зміну базової валюти з $_lastKnownBaseCurrency на $currentBase. Запуск фонової міграції...",
        );

        // Запускаємо міграцію без await, щоб не блокувати UI!
        runExchangeRateMigration();
      }

      _lastKnownBaseCurrency = currentBase;
    }

    if (!isLoading && !catProv.isLoading && _settingsProv != null) {
      notifyListeners();
    }
  }

  bool get isCurrentMonth {
    final now = DateTime.now();
    return selectedMonth.year == now.year && selectedMonth.month == now.month;
  }

  Future<void> loadHistory() async {
    final loadedHistory = await StorageService.loadHistory();
    loadedHistory.sort((a, b) => b.date.compareTo(a.date));
    history = loadedHistory;
    _invalidateCache();
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

  // =======================================================
  // ЛОГІКА ФІКСАЦІЇ ІСТОРИЧНОГО КУРСУ
  // =======================================================
  Future<void> _fetchAndSetExactRate(Transaction tx) async {
    if (_settingsProv == null) return;

    final currentBase = _settingsProv!.baseCurrency;

    // 1. ЗАХИСТ КАСТОМНОГО КУРСУ:
    // Якщо користувач ввів суми вручну і одна з них - базова валюта, курс ВЖЕ відомий з ідеальною точністю!
    if (tx.targetAmount != null &&
        tx.targetCurrency != null &&
        tx.currency != tx.targetCurrency) {
      if (tx.targetCurrency == currentBase) {
        double customRate = tx.targetAmount! / tx.amount;
        // Оновлюємо і зберігаємо, тільки якщо база змінилася або була помилка збереження
        if ((tx.exchangeRate - customRate).abs() > 0.0001 ||
            tx.rateBaseCurrency != currentBase) {
          tx.exchangeRate = customRate;
          tx.rateBaseCurrency = currentBase;
          StorageService.saveTransaction(tx);
          _invalidateCache();
          notifyListeners();
        }
        return; // ВИХОДИМО! Забороняємо API змінювати цей курс
      }
      if (tx.currency == currentBase) {
        if (tx.exchangeRate != 1.0 || tx.rateBaseCurrency != currentBase) {
          tx.exchangeRate = 1.0;
          tx.rateBaseCurrency = currentBase;
          StorageService.saveTransaction(tx);
          _invalidateCache();
          notifyListeners();
        }
        return; // ВИХОДИМО!
      }
    }

    // 2. Якщо валюта базова
    if (tx.currency == currentBase) {
      if (tx.exchangeRate != 1.0 || tx.rateBaseCurrency != currentBase) {
        tx.exchangeRate = 1.0;
        tx.rateBaseCurrency = currentBase;
        StorageService.saveTransaction(tx);
      }
      return;
    }

    // 3. Лише для всіх інших (звичайних валютних) випадків - йдемо в API за офіційним історичним курсом
    double? historicalRate = await _settingsProv!.getRateForDate(
      tx.currency,
      tx.date,
    );
    double? historicalBase = await _settingsProv!.getRateForDate(
      currentBase,
      tx.date,
    );

    if (historicalRate != null) {
      double bRate = historicalBase ?? 1.0;
      double newRate = bRate / historicalRate;

      if ((tx.exchangeRate - newRate).abs() > 0.0001 ||
          tx.rateBaseCurrency != currentBase) {
        tx.exchangeRate = newRate;
        tx.rateBaseCurrency = currentBase;
        StorageService.saveTransaction(tx);
        _invalidateCache();
        notifyListeners();
      }
    }
  }

  Map<String, double> calculateTotalsForMonth(DateTime month) {
    double totalExpenses = 0.0;
    double totalIncomes = 0.0;

    if (_catProv == null || _settingsProv == null) {
      return {'expenses': 0.0, 'incomes': 0.0};
    }

    final baseCurrency = _settingsProv!.baseCurrency;
    final rates = _settingsProv!.exchangeRates;

    // ДОПОМІЖНА ФУНКЦІЯ: Читає зафіксований курс З УРАХУВАННЯМ БАЗОВОЇ ВАЛЮТИ
    double getRate(Transaction tx) {
      if (tx.currency == baseCurrency) return 1.0;

      // Бронебійний захист: Використовуємо курс, ТІЛЬКИ якщо він був збережений для поточної бази
      // 👇 ВИПРАВЛЕННЯ: Дозволяємо null для транзакцій, збережених до додавання поля rateBaseCurrency
      if ((tx.rateBaseCurrency == baseCurrency ||
              tx.rateBaseCurrency == null) &&
          tx.exchangeRate != 1.0) {
        return tx.exchangeRate;
      }

      // Фолбек, якщо валюту змінили і мігратор ще не відпрацював
      double txRate = rates[tx.currency] ?? 1.0;
      double baseRate = rates[baseCurrency] ?? 1.0;
      return baseRate / txRate;
    }

    final monthHistory = _getHistoryForMonth(month);

    for (var tx in monthHistory) {
      bool isExpense = _catProv!.expenses.any((c) => c.id == tx.toId);
      bool isIncome = _catProv!.incomes.any((c) => c.id == tx.fromId);

      if (isExpense) totalExpenses += tx.amount * getRate(tx);
      if (isIncome) totalIncomes += tx.amount * getRate(tx);
    }

    return {'expenses': totalExpenses, 'incomes': totalIncomes};
  }

  Map<String, double> calculateCategoryTotalsForMonth(
    DateTime month,
    bool isExpenses, {
    bool inBaseCurrency = true,
  }) {
    Map<String, double> totals = {};

    if (_catProv == null || _settingsProv == null) return totals;

    final baseCurrency = _settingsProv!.baseCurrency;
    final rates = _settingsProv!.exchangeRates;

    // ДОПОМІЖНА ФУНКЦІЯ: Читає зафіксований курс З УРАХУВАННЯМ БАЗОВОЇ ВАЛЮТИ
    double getRate(Transaction tx) {
      if (tx.currency == baseCurrency) return 1.0;

      // Бронебійний захист: Використовуємо курс, ТІЛЬКИ якщо він був збережений для поточної бази
      // 👇 ВИПРАВЛЕННЯ: Дозволяємо null для транзакцій, збережених до додавання поля rateBaseCurrency
      if ((tx.rateBaseCurrency == baseCurrency ||
              tx.rateBaseCurrency == null) &&
          tx.exchangeRate != 1.0) {
        return tx.exchangeRate;
      }

      // Фолбек, якщо валюту змінили і мігратор ще не відпрацював
      double txRate = rates[tx.currency] ?? 1.0;
      double baseRate = rates[baseCurrency] ?? 1.0;
      return baseRate / txRate;
    }

    final monthHistory = _getHistoryForMonth(month);

    for (var tx in monthHistory) {
      if (isExpenses) {
        bool isExpenseCat = _catProv!.expenses.any((c) => c.id == tx.toId);
        if (isExpenseCat) {
          double value;
          if (inBaseCurrency) {
            value = tx.amount * getRate(tx);
          } else {
            value = tx.targetAmount ?? tx.amount;
          }
          totals[tx.toId] = (totals[tx.toId] ?? 0.0) + value;
        }
      } else {
        bool isIncomeCat = _catProv!.incomes.any((c) => c.id == tx.fromId);
        if (isIncomeCat) {
          double value;
          if (inBaseCurrency) {
            value = tx.amount * getRate(tx);
          } else {
            value = tx.amount;
          }
          totals[tx.fromId] = (totals[tx.fromId] ?? 0.0) + value;
        }
      }
    }
    return totals;
  }

  void _updateAccountBalance(String categoryId, double delta) {
    if (_catProv == null) return;
    final category = _catProv!.allCategoriesList
        .where((c) => c.id == categoryId)
        .firstOrNull;

    if (category != null && category.type == CategoryType.account) {
      _catProv!.updateCategoryAmount(categoryId, delta);
    }
  }

  void addTransfer(
    Category source,
    Category target,
    double amount,
    DateTime date, {
    double? targetAmount,
  }) {
    if (source.type == CategoryType.account) {
      _catProv?.updateCategoryAmount(source.id, -amount);
    }
    if (target.type == CategoryType.account) {
      _catProv?.updateCategoryAmount(target.id, targetAmount ?? amount);
    }

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
    );

    addTransactionDirectly(newTx);
  }

  void editTransaction(
    Transaction oldT,
    double newAmount,
    DateTime newDate, {
    double? newTargetAmount,
  }) {
    _updateAccountBalance(oldT.fromId, oldT.amount);
    _updateAccountBalance(oldT.toId, -(oldT.targetAmount ?? oldT.amount));

    final double previousAmount = oldT.amount;

    oldT.amount = newAmount;
    oldT.date = newDate;

    if (newTargetAmount != null) {
      oldT.targetAmount = newTargetAmount;
    } else if (oldT.targetAmount != null && previousAmount > 0) {
      oldT.targetAmount = oldT.targetAmount! * (newAmount / previousAmount);
    } else {
      oldT.targetAmount = newAmount;
    }

    _updateAccountBalance(oldT.fromId, -oldT.amount);
    _updateAccountBalance(oldT.toId, oldT.targetAmount ?? oldT.amount);

    // Асинхронно оновлюємо курс, оскільки дата могла змінитися
    _fetchAndSetExactRate(oldT);

    StorageService.saveTransaction(oldT);
    history.sort((a, b) => b.date.compareTo(a.date));
    _invalidateCache();
    notifyListeners();
  }

  void deleteTransaction(Transaction t) {
    _updateAccountBalance(t.fromId, t.amount);
    _updateAccountBalance(t.toId, -(t.targetAmount ?? t.amount));

    history.removeWhere((item) => item.id == t.id);
    StorageService.removeTransaction(t.id);
    _invalidateCache();
    notifyListeners();
  }

  void addTransactionDirectly(Transaction tx) {
    // 👇 НОВА ЛОГІКА: Миттєве обчислення кастомного курсу
    if (_settingsProv != null) {
      final currentBase = _settingsProv!.baseCurrency;

      // Якщо це мультивалютна транзакція (користувач ввів обидві суми)
      if (tx.targetAmount != null &&
          tx.targetCurrency != null &&
          tx.currency != tx.targetCurrency) {
        if (tx.targetCurrency == currentBase) {
          tx.exchangeRate =
              tx.targetAmount! / tx.amount; // Вираховуємо точний кастомний курс
          tx.rateBaseCurrency = currentBase;
        } else if (tx.currency == currentBase) {
          tx.exchangeRate = 1.0;
          tx.rateBaseCurrency = currentBase;
        } else {
          // Якщо обидві валюти іноземні - беремо тимчасовий живий курс
          double txRate = _settingsProv!.exchangeRates[tx.currency] ?? 1.0;
          double baseRate = _settingsProv!.exchangeRates[currentBase] ?? 1.0;
          tx.exchangeRate = baseRate / txRate;
          tx.rateBaseCurrency = currentBase;
        }
      } else {
        // Звичайна одновалютна транзакція
        if (tx.currency == currentBase) {
          tx.exchangeRate = 1.0;
          tx.rateBaseCurrency = currentBase;
        } else {
          double txRate = _settingsProv!.exchangeRates[tx.currency] ?? 1.0;
          double baseRate = _settingsProv!.exchangeRates[currentBase] ?? 1.0;
          tx.exchangeRate = baseRate / txRate;
          tx.rateBaseCurrency = currentBase;
        }
      }
    }

    _updateAccountBalance(tx.fromId, -tx.amount);
    _updateAccountBalance(tx.toId, tx.targetAmount ?? tx.amount);

    int insertIndex = 0;
    for (int i = 0; i < history.length; i++) {
      if (tx.date.isAfter(history[i].date) ||
          tx.date.isAtSameMomentAs(history[i].date)) {
        insertIndex = i;
        break;
      }
      if (i == history.length - 1) insertIndex = history.length;
    }

    history.insert(insertIndex, tx);
    StorageService.saveTransaction(tx);

    // Асинхронно підтягуємо точний історичний курс через API, якщо транзакція в минулому
    _fetchAndSetExactRate(tx);

    _invalidateCache();
    notifyListeners();
  }

  // =======================================================
  // СКРИПТ МІГРАЦІЇ: Оновлення старих транзакцій
  // =======================================================
  Future<int> runExchangeRateMigration() async {
    if (_settingsProv == null) return 0;

    final baseCurrency = _settingsProv!.baseCurrency;
    int migratedCount = 0;

    // 1. Знаходимо транзакції, де курс не зафіксовано, АБО де базова валюта курсу не збігається з поточною базою додатка!
    final transactionsToMigrate = history
        .where(
          (tx) =>
              tx.currency != baseCurrency &&
              (tx.exchangeRate == 1.0 || tx.rateBaseCurrency != baseCurrency),
        )
        .toList();

    if (transactionsToMigrate.isEmpty) {
      return 0; // Міграція не потрібна
    }

    // 2. Проходимося по кожній і підтягуємо історичний курс
    for (var tx in transactionsToMigrate) {
      try {
        double? historicalRate = await _settingsProv!.getRateForDate(
          tx.currency,
          tx.date,
        );
        double? historicalBase = await _settingsProv!.getRateForDate(
          baseCurrency,
          tx.date,
        );

        if (historicalRate != null) {
          double bRate = historicalBase ?? 1.0;
          double newRate = bRate / historicalRate;

          // Оновлюємо і зберігаємо
          tx.exchangeRate = newRate;
          StorageService.saveTransaction(tx);
          migratedCount++;

          // ВАЖЛИВО: Робимо маленьку паузу (200 мілісекунд).
          // Якщо старих транзакцій багато (наприклад 100+), ми не хочемо
          // "заспамити" безкоштовне API курсів валют, щоб воно нас не заблокувало.
          await Future.delayed(const Duration(milliseconds: 200));
        }
      } catch (e) {
        debugPrint("Помилка міграції для транзакції ${tx.id}: $e");
      }
    }

    // 3. Очищаємо кеш і оновлюємо UI після масових змін
    if (migratedCount > 0) {
      _invalidateCache();
      notifyListeners();
    }

    return migratedCount;
  }
  // =======================================================

  Future<void> clearAllTransactions() async {
    history.clear();
    await StorageService.saveHistory([]);
    _invalidateCache();
    notifyListeners();
  }
}
