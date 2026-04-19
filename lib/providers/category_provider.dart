import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../database/app_database.dart';
import '../services/storage_service.dart';
// 👇 Додали імпорт хабу, де лежить databaseProvider
import 'all_providers.dart';

part 'category_provider.g.dart';

// 1. СТАН (State)
class CategoryState {
  final List<Category> incomes;
  final List<Category> accounts;
  final List<Category> expenses;
  final List<Category> archivedCategories;
  final bool isLoading;

  CategoryState({
    required this.incomes,
    required this.accounts,
    required this.expenses,
    required this.archivedCategories,
    required this.isLoading,
  });

  CategoryState copyWith({
    List<Category>? incomes,
    List<Category>? accounts,
    List<Category>? expenses,
    List<Category>? archivedCategories,
    bool? isLoading,
  }) {
    return CategoryState(
      incomes: incomes ?? this.incomes,
      accounts: accounts ?? this.accounts,
      expenses: expenses ?? this.expenses,
      archivedCategories: archivedCategories ?? this.archivedCategories,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  List<Category> get allCategoriesList => [
    ...incomes,
    ...accounts,
    ...expenses,
    ...archivedCategories,
  ];
}

// 2. СУЧАСНИЙ NOTIFIER
@Riverpod(keepAlive: true)
class CategoryNotifier extends _$CategoryNotifier {
  @override
  CategoryState build() {
    final initialState = CategoryState(
      incomes: [],
      accounts: [],
      expenses: [],
      archivedCategories: [],
      isLoading: true,
    );

    Future.microtask(() => loadCategories());

    return initialState;
  }

  Future<void> loadCategories() async {
    // 👇 Отримуємо базу з провайдера
    final db = ref.read(databaseProvider);
    final savedCats = await StorageService.loadCategories(db);

    List<Category> newIncomes = [];
    List<Category> newAccounts = [];
    List<Category> newExpenses = [];
    List<Category> newArchived = [];

    if (savedCats.isNotEmpty) {
      final sorted = List<Category>.from(savedCats)
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

      newIncomes = sorted
          .where((c) => c.type == CategoryType.income && !c.isArchived)
          .toList();
      newAccounts = sorted
          .where((c) => c.type == CategoryType.account && !c.isArchived)
          .toList();
      newExpenses = sorted
          .where((c) => c.type == CategoryType.expense && !c.isArchived)
          .toList();
      newArchived = sorted.where((c) => c.isArchived).toList();
    }

    state = state.copyWith(
      incomes: newIncomes,
      accounts: newAccounts,
      expenses: newExpenses,
      archivedCategories: newArchived,
      isLoading: false,
    );
  }

  void updateCategoryAmount(String id, int delta) {
    final db = ref.read(databaseProvider);
    final all = state.allCategoriesList;
    final index = all.indexWhere((c) => c.id == id);
    if (index == -1) return;

    final category = all[index];
    final updatedCategory = category.copyWith(amount: category.amount + delta);

    if (updatedCategory.type == CategoryType.income) {
      final newList = List<Category>.from(state.incomes);
      int idx = newList.indexWhere((c) => c.id == id);
      if (idx != -1) newList[idx] = updatedCategory;
      state = state.copyWith(incomes: newList);
    } else if (updatedCategory.type == CategoryType.account) {
      final newList = List<Category>.from(state.accounts);
      int idx = newList.indexWhere((c) => c.id == id);
      if (idx != -1) newList[idx] = updatedCategory;
      state = state.copyWith(accounts: newList);
    } else {
      final newList = List<Category>.from(state.expenses);
      int idx = newList.indexWhere((c) => c.id == id);
      if (idx != -1) newList[idx] = updatedCategory;
      state = state.copyWith(expenses: newList);
    }

    StorageService.saveCategory(db, updatedCategory);
  }

  // 👇 ВИПРАВЛЕНО: Тепер метод асинхронний і повертає Future
  Future<void> addOrUpdateCategory(Category cat) async {
    final db = ref.read(databaseProvider);
    List<Category> targetList;

    if (cat.type == CategoryType.income) {
      targetList = List<Category>.from(state.incomes);
    } else if (cat.type == CategoryType.account) {
      targetList = List<Category>.from(state.accounts);
    } else {
      targetList = List<Category>.from(state.expenses);
    }

    int index = targetList.indexWhere((c) => c.id == cat.id);
    if (index == -1) {
      final newCat = cat.copyWith(sortOrder: targetList.length);
      targetList.add(newCat);
      // 👇 ДОДАНО: await для гарантованого запису в БД
      await StorageService.saveCategory(db, newCat);
    } else {
      targetList[index] = cat;
      // 👇 ДОДАНО: await
      await StorageService.saveCategory(db, cat);
    }

    if (cat.type == CategoryType.income) {
      state = state.copyWith(incomes: targetList);
    } else if (cat.type == CategoryType.account) {
      state = state.copyWith(accounts: targetList);
    } else {
      state = state.copyWith(expenses: targetList);
    }
  }

  void deleteCategory(Category cat) {
    final db = ref.read(databaseProvider);
    final archived = cat.copyWith(isArchived: true);
    StorageService.saveCategory(db, archived);

    final newArchived = List<Category>.from(state.archivedCategories)
      ..add(archived);

    if (cat.type == CategoryType.income) {
      final newList = List<Category>.from(state.incomes)
        ..removeWhere((c) => c.id == cat.id);
      state = state.copyWith(incomes: newList, archivedCategories: newArchived);
    } else if (cat.type == CategoryType.account) {
      final newList = List<Category>.from(state.accounts)
        ..removeWhere((c) => c.id == cat.id);
      state = state.copyWith(
        accounts: newList,
        archivedCategories: newArchived,
      );
    } else {
      final newList = List<Category>.from(state.expenses)
        ..removeWhere((c) => c.id == cat.id);
      state = state.copyWith(
        expenses: newList,
        archivedCategories: newArchived,
      );
    }
  }

  void reorderCategories(Category dragged, Category target) {
    final db = ref.read(databaseProvider);
    if (dragged.type != target.type) return;

    List<Category> targetList = List<Category>.from(
      dragged.type == CategoryType.income
          ? state.incomes
          : dragged.type == CategoryType.account
          ? state.accounts
          : state.expenses,
    );

    int oldIndex = targetList.indexWhere((c) => c.id == dragged.id);
    int newIndex = targetList.indexWhere((c) => c.id == target.id);

    if (oldIndex != -1 && newIndex != -1 && oldIndex != newIndex) {
      final item = targetList.removeAt(oldIndex);
      targetList.insert(newIndex, item);

      for (int i = 0; i < targetList.length; i++) {
        targetList[i] = targetList[i].copyWith(sortOrder: i);
      }

      StorageService.saveCategories(db, targetList);

      if (dragged.type == CategoryType.income) {
        state = state.copyWith(incomes: targetList);
      } else if (dragged.type == CategoryType.account) {
        state = state.copyWith(accounts: targetList);
      } else {
        state = state.copyWith(expenses: targetList);
      }
    }
  }

  // 👇 НОВИЙ МЕТОД: "Розумне" оновлення валюти для категорій при зміні базової валюти
  Future<void> updateBaseCurrencyForCategories(
    String oldBase,
    String newBase,
  ) async {
    final db = ref.read(databaseProvider);

    // Оновлюємо доходи: якщо валюта була oldBase, ставимо newBase. Інакше - не чіпаємо.
    final newIncomes = state.incomes.map((c) {
      if (c.currency == oldBase) return c.copyWith(currency: newBase);
      return c;
    }).toList();

    // Аналогічно для витрат
    final newExpenses = state.expenses.map((c) {
      if (c.currency == oldBase) return c.copyWith(currency: newBase);
      return c;
    }).toList();

    // УВАГА: Ми НЕ чіпаємо state.accounts, тому що рахунки це фізичні гроші, їх валюта незмінна!

    // Зберігаємо всі категорії в базу даних одним списком
    await StorageService.saveCategories(db, [
      ...newIncomes,
      ...state.accounts,
      ...newExpenses,
      ...state.archivedCategories,
    ]);

    // Оновлюємо стан провайдера
    state = state.copyWith(incomes: newIncomes, expenses: newExpenses);
  }

  Future<void> resetAllBalances() async {
    final db = ref.read(databaseProvider);

    final newIncomes = state.incomes.map((c) => c.copyWith(amount: 0)).toList();
    final newAccounts = state.accounts
        .map((c) => c.copyWith(amount: 0))
        .toList();
    final newExpenses = state.expenses
        .map((c) => c.copyWith(amount: 0))
        .toList();
    final newArchived = state.archivedCategories
        .map((c) => c.copyWith(amount: 0))
        .toList();

    state = state.copyWith(
      incomes: newIncomes,
      accounts: newAccounts,
      expenses: newExpenses,
      archivedCategories: newArchived,
    );

    await StorageService.saveCategories(db, state.allCategoriesList);
  }
}
