import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:collection/collection.dart';

import '../database/app_database.dart';
import '../utils/currency_formatter.dart';
import 'all_providers.dart';

part 'filter_provider.g.dart';

class FilterState {
  final String searchQuery;
  final DateTime? startDate;
  final DateTime? endDate;
  final CategoryType? selectedType;
  final String? selectedCurrency;
  final String? specificCategoryId;

  final List<Transaction> results;
  final bool isLoading;

  FilterState({
    this.searchQuery = '',
    this.startDate,
    this.endDate,
    this.selectedType,
    this.selectedCurrency,
    this.specificCategoryId,
    this.results = const [],
    this.isLoading = false,
  });

  FilterState copyWith({
    String? searchQuery,
    DateTime? startDate,
    DateTime? endDate,
    CategoryType? selectedType,
    String? selectedCurrency,
    String? specificCategoryId,
    List<Transaction>? results,
    bool? isLoading,
    bool clearDates = false,
    bool clearType = false,
    bool clearCurrency = false,
  }) {
    return FilterState(
      searchQuery: searchQuery ?? this.searchQuery,
      startDate: clearDates ? null : (startDate ?? this.startDate),
      endDate: clearDates ? null : (endDate ?? this.endDate),
      selectedType: clearType ? null : (selectedType ?? this.selectedType),
      selectedCurrency: clearCurrency
          ? null
          : (selectedCurrency ?? this.selectedCurrency),
      specificCategoryId: specificCategoryId ?? this.specificCategoryId,
      results: results ?? this.results,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

@riverpod
class FilterNotifier extends _$FilterNotifier {
  @override
  FilterState build() {
    return FilterState();
  }

  void initForCategory(String categoryId) {
    state = FilterState(specificCategoryId: categoryId);
    _applyFilters();
  }

  void initGeneral() {
    state = FilterState();
    _applyFilters();
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
    _applyFilters();
  }

  void setDateRange(DateTime? start, DateTime? end) {
    state = state.copyWith(
      startDate: start,
      endDate: end,
      clearDates: start == null && end == null,
    );
    _applyFilters();
  }

  void setCategoryType(CategoryType? type) {
    state = state.copyWith(selectedType: type, clearType: type == null);
    _applyFilters();
  }

  void setCurrency(String? currency) {
    state = state.copyWith(
      selectedCurrency: currency,
      clearCurrency: currency == null,
    );
    _applyFilters();
  }

  void clearAllFilters() {
    state = FilterState(specificCategoryId: state.specificCategoryId);
    _applyFilters();
  }

  Future<void> _applyFilters() async {
    state = state.copyWith(isLoading: true);

    final db = ref.read(databaseProvider);
    final catState = ref.read(categoryProvider);

    // 1. ГОТУЄМО СУВОРІ ФІЛЬТРИ ДЛЯ SQL
    List<String>? filterCategoryIds;
    if (state.specificCategoryId != null) {
      filterCategoryIds = [state.specificCategoryId!];
    } else if (state.selectedType != null) {
      filterCategoryIds = catState.allCategoriesList
          .where((c) => c.type == state.selectedType)
          .map((c) => c.id)
          .toList();
      if (filterCategoryIds.isEmpty) filterCategoryIds = ['__empty__'];
    }

    // 2. ОТРИМУЄМО БАЗОВУ ВИБІРКУ З БАЗИ ДАНИХ (Блискавично)
    var results = await db.getFilteredTransactions(
      startDate: state.startDate,
      endDate: state.endDate,
      filterCategoryIds: filterCategoryIds,
      currency: state.selectedCurrency,
    );

    // 3. РОЗУМНИЙ FUZZY-ПОШУК У ПАМ'ЯТІ (Магія Dart)
    if (state.searchQuery.isNotEmpty) {
      final query = state.searchQuery.toLowerCase().trim();
      final allCategories = catState.allCategoriesList;
      final queryAmount = query
          .replaceAll(RegExp(r'\s+'), '')
          .replaceAll(',', '.');

      results = results.where((t) {
        // --- Перевірка Назви та Коментаря ---
        final sourceCat = allCategories.firstWhereOrNull(
          (c) => c.id == t.fromId,
        );
        final targetCat = allCategories.firstWhereOrNull((c) => c.id == t.toId);

        bool matchesTitle =
            t.title.toLowerCase().contains(query) ||
            (sourceCat != null &&
                sourceCat.name.toLowerCase().contains(query)) ||
            (targetCat != null && targetCat.name.toLowerCase().contains(query));

        // --- Перевірка Суми (З урахуванням форматування) ---
        String formattedAmount1 = CurrencyFormatter.format(
          t.amount,
        ).replaceAll(RegExp(r'\s+'), '');
        String rawAmount1 = (t.amount / 100).toStringAsFixed(2);

        String formattedAmount2 = t.targetAmount != null
            ? CurrencyFormatter.format(
                t.targetAmount!,
              ).replaceAll(RegExp(r'\s+'), '')
            : '';
        String rawAmount2 = t.targetAmount != null
            ? (t.targetAmount! / 100).toStringAsFixed(2)
            : '';

        bool matchesAmount =
            formattedAmount1.contains(queryAmount) ||
            rawAmount1.contains(queryAmount) ||
            formattedAmount2.contains(queryAmount) ||
            rawAmount2.contains(queryAmount);

        // --- Перевірка Дати (Повне та коротке співпадіння) ---
        String dateStrFull = DateFormat('dd.MM.yyyy').format(t.date);
        String dateStrShort = DateFormat('dd.MM').format(t.date);
        bool matchesDate =
            dateStrFull.contains(query) || dateStrShort.contains(query);

        // Якщо хоча б щось збіглося — залишаємо транзакцію!
        return matchesTitle || matchesAmount || matchesDate;
      }).toList();
    }

    state = state.copyWith(results: results, isLoading: false);
  }
}
