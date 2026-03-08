import 'package:flutter/material.dart';
import '../models/category_model.dart';
import '../models/transaction_model.dart';
import '../services/storage_service.dart';
import 'category_provider.dart';

class TransactionProvider extends ChangeNotifier {
  CategoryProvider? _catProv; // Посилання на провайдер категорій

  List<Transaction> history = [];
  DateTime selectedMonth = DateTime(
    DateTime.now().year,
    DateTime.now().month,
    1,
  );
  bool isLoading = true;

  TransactionProvider() {
    loadHistory();
  }

  // Цей метод автоматично викликатиметься Proxy-провайдером
  void updateDependencies(CategoryProvider catProv) {
    _catProv = catProv;
  }

  bool get isCurrentMonth {
    final now = DateTime.now();
    return selectedMonth.year == now.year && selectedMonth.month == now.month;
  }

  Future<void> loadHistory() async {
    history = await StorageService.loadHistory();
    history.sort((a, b) => b.date.compareTo(a.date));
    isLoading = false;
    notifyListeners();
  }

  void changeMonth(int offset) {
    selectedMonth = DateTime(
      selectedMonth.year,
      selectedMonth.month + offset,
      1,
    );
    _catProv?.recalculateMonthTotals(history, selectedMonth);
    notifyListeners();
  }

  void setMonth(DateTime newMonth) {
    selectedMonth = DateTime(newMonth.year, newMonth.month, 1);
    _catProv?.recalculateMonthTotals(history, selectedMonth);
    notifyListeners();
  }

  void addTransfer(
    Category source,
    Category target,
    double amount,
    DateTime date,
  ) {
    if (source.type == CategoryType.account) {
      _catProv?.updateCategoryAmount(source.id, -amount);
    }
    if (target.type == CategoryType.account) {
      _catProv?.updateCategoryAmount(target.id, amount);
    }

    final newTx = Transaction(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      fromId: source.id,
      toId: target.id,
      title: target.name,
      amount: amount,
      date: date,
    );

    addTransactionDirectly(newTx);
  }

  void editTransaction(Transaction oldT, double newAmount, DateTime newDate) {
    _catProv?.updateCategoryAmount(oldT.fromId, oldT.amount);
    _catProv?.updateCategoryAmount(oldT.toId, -oldT.amount);

    oldT.amount = newAmount;
    oldT.date = newDate;

    _catProv?.updateCategoryAmount(oldT.fromId, -oldT.amount);
    _catProv?.updateCategoryAmount(oldT.toId, oldT.amount);

    StorageService.saveTransaction(oldT);
    history.sort((a, b) => b.date.compareTo(a.date));
    _catProv?.recalculateMonthTotals(history, selectedMonth);
    notifyListeners();
  }

  void deleteTransaction(Transaction t) {
    _catProv?.updateCategoryAmount(t.fromId, t.amount);
    _catProv?.updateCategoryAmount(t.toId, -t.amount);

    history.removeWhere((item) => item.id == t.id);
    StorageService.removeTransaction(t.id);

    _catProv?.recalculateMonthTotals(history, selectedMonth);
    notifyListeners();
  }

  // Допоміжний метод (також використовується для авто-платежів)
  void addTransactionDirectly(Transaction tx) {
    history.insert(0, tx);
    history.sort((a, b) => b.date.compareTo(a.date));
    StorageService.saveTransaction(tx);
    _catProv?.recalculateMonthTotals(history, selectedMonth);
    notifyListeners();
  }
}
