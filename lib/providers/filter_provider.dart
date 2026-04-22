import 'dart:async';
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

  // ДОДАНО ДЛЯ ПАГІНАЦІЇ
  final int currentPage;
  final bool hasMore;

  FilterState({
    this.searchQuery = '',
    this.startDate,
    this.endDate,
    this.selectedType,
    this.selectedCurrency,
    this.specificCategoryId,
    this.results = const [],
    this.isLoading = false,
    this.currentPage = 0,
    this.hasMore = true,
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
    int? currentPage,
    bool? hasMore,
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
      currentPage: currentPage ?? this.currentPage,
      hasMore: hasMore ?? this.hasMore,
    );
  }
}

@riverpod
class FilterNotifier extends _$FilterNotifier {
  static const int _pageSize = 30; // Скільки вантажимо за раз

  @override
  FilterState build() {
    // 👇 МАГІЯ: Якщо ти видалив або відредагував транзакцію в UI,
    // FilterProvider миттєво це помітить і оновить список!
    ref.listen(transactionProvider, (prevAsync, nextAsync) {
      // ВИПРАВЛЕНО: Використовуємо просто .value замість .valueOrNull
      final prev = prevAsync?.value;
      final next = nextAsync.value;

      if (prev != null && next != null && prev.history != next.history) {
        _applyFilters();
      }
    });

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

  // НОВИЙ МЕТОД ДЛЯ ПАГІНАЦІЇ (Викликається при скролі вниз)
  Future<void> loadNextPage() async {
    // Якщо йде пошук, або більше немає даних, або вже вантажимо — ігноруємо
    if (state.searchQuery.isNotEmpty || !state.hasMore || state.isLoading) {
      return;
    }
    await _applyFilters(loadMore: true);
  }

  Future<void> _applyFilters({bool loadMore = false}) async {
    if (!loadMore) {
      state = state.copyWith(
        isLoading: true,
        currentPage: 0,
        hasMore: true,
        results: [],
      );
    }

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

    // 2. ВИЗНАЧАЄМО ЛІМІТ ТА ОФСЕТ ДЛЯ SQL
    int? limit;
    int? offset;

    // Якщо пошуку немає, вмикаємо жорстку оптимізацію SQL
    if (state.searchQuery.isEmpty) {
      limit = _pageSize;
      offset = state.currentPage * _pageSize;
    }

    // 3. ОТРИМУЄМО ПОРЦІЮ З БАЗИ ДАНИХ (Блискавично)
    var newBatch = await db.getFilteredTransactions(
      startDate: state.startDate,
      endDate: state.endDate,
      filterCategoryIds: filterCategoryIds,
      currency: state.selectedCurrency,
      limit: limit,
      offset: offset,
    );

    // 4. РОЗУМНИЙ FUZZY-ПОШУК У ПАМ'ЯТІ
    if (state.searchQuery.isNotEmpty) {
      final query = state.searchQuery.toLowerCase().trim();
      final allCategories = catState.allCategoriesList;
      final queryAmount = query
          .replaceAll(RegExp(r'\s+'), '')
          .replaceAll(',', '.');

      final fuzzyResults = newBatch.where((t) {
        final sourceCat = allCategories.firstWhereOrNull(
          (c) => c.id == t.fromId,
        );
        final targetCat = allCategories.firstWhereOrNull((c) => c.id == t.toId);

        bool matchesTitle =
            t.title.toLowerCase().contains(query) ||
            (sourceCat != null &&
                sourceCat.name.toLowerCase().contains(query)) ||
            (targetCat != null && targetCat.name.toLowerCase().contains(query));

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

        String dateStrFull = DateFormat('dd.MM.yyyy').format(t.date);
        String dateStrShort = DateFormat('dd.MM').format(t.date);
        bool matchesDate =
            dateStrFull.contains(query) || dateStrShort.contains(query);

        return matchesTitle || matchesAmount || matchesDate;
      }).toList();

      // Вимикаємо пагінацію на час пошуку
      state = state.copyWith(
        results: fuzzyResults,
        isLoading: false,
        hasMore: false,
      );
    } else {
      // 5. ЗБЕРІГАЄМО ПАГІНОВАНІ ДАНІ
      state = state.copyWith(
        results: loadMore ? [...state.results, ...newBatch] : newBatch,
        isLoading: false,
        hasMore:
            newBatch.length ==
            _pageSize, // Якщо прийшло менше 30, значить це кінець бази
        currentPage: state.currentPage + 1,
      );
    }
  }
}
