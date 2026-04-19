import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../database/app_database.dart';
import '../../models/app_currency.dart';
import '../../utils/currency_formatter.dart';
import '../../theme/app_colors_extension.dart';
import '../../providers/all_providers.dart';
import '../common/history_search_bar.dart';

class HistoryBottomSheet extends ConsumerStatefulWidget {
  final Category category;
  final List<Transaction> transactions;
  final List<Category> allCategories;
  final Function(Transaction) onDelete;
  final Function(Transaction) onEdit;

  const HistoryBottomSheet({
    super.key,
    required this.category,
    required this.transactions,
    required this.allCategories,
    required this.onDelete,
    required this.onEdit,
  });

  @override
  ConsumerState<HistoryBottomSheet> createState() => _HistoryBottomSheetState();
}

class _HistoryBottomSheetState extends ConsumerState<HistoryBottomSheet> {
  final ScrollController _scrollController = ScrollController();
  bool _isFetchingMore = false;

  // 👇 ДОДАНО: Локальний кеш видалених транзакцій для миттєвого приховування
  final Set<String> _localDeletedIds = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(filterProvider.notifier).initForCategory(widget.category.id);
    });

    _scrollController.addListener(_onScroll);
  }

  void _onScroll() async {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 150) {
      final filterState = ref.read(filterProvider);

      if (filterState.searchQuery.isNotEmpty) return;

      if (filterState.hasMore && !_isFetchingMore) {
        _isFetchingMore = true;
        await ref.read(filterProvider.notifier).loadNextPage();
        _isFetchingMore = false;
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  String _fastDateFormat(DateTime d) {
    final day = d.day.toString().padLeft(2, '0');
    final month = d.month.toString().padLeft(2, '0');
    final hour = d.hour.toString().padLeft(2, '0');
    final minute = d.minute.toString().padLeft(2, '0');
    return '$day.$month.${d.year} $hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColorsExtension>()!;

    final catState = ref.watch(categoryProvider);
    final filterState = ref.watch(filterProvider);

    final categoryHistory = filterState.results;
    final allCategories = catState.allCategoriesList;

    final showLoader = filterState.hasMore && filterState.searchQuery.isEmpty;

    final categoryMap = {for (var c in allCategories) c.id: c};

    final trOutgoing = 'outgoing_transfer'.tr();
    final trTopUp = 'top_up'.tr();

    return Container(
      padding: const EdgeInsets.only(top: 20, left: 16, right: 16),
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: BoxDecoration(
        color: colors.cardBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: colors.textSecondary.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'history_category'.tr(args: [widget.category.name]),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: colors.textMain,
            ),
          ),
          const SizedBox(height: 16),

          HistorySearchBar(specificType: widget.category.type),

          const SizedBox(height: 12),

          Expanded(
            child: filterState.isLoading
                ? const Center(child: CircularProgressIndicator())
                : categoryHistory.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off_rounded,
                          size: 48,
                          color: colors.textSecondary.withValues(alpha: 0.5),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          filterState.searchQuery.isNotEmpty
                              ? 'nothing_found'.tr()
                              : 'no_transactions_yet'.tr(),
                          style: TextStyle(color: colors.textSecondary),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    physics: const BouncingScrollPhysics(),
                    cacheExtent: 1000,
                    itemCount: categoryHistory.length + (showLoader ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == categoryHistory.length) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24.0),
                          child: Center(
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: colors.textSecondary.withValues(
                                  alpha: 0.5,
                                ),
                              ),
                            ),
                          ),
                        );
                      }

                      final t = categoryHistory[index];

                      // 👇 ДОДАНО: Перевірка на локально видалену транзакцію
                      if (_localDeletedIds.contains(t.id)) {
                        return const SizedBox.shrink();
                      }

                      // isOut = true, якщо гроші ПІШЛИ з поточної категорії (напр. витрата з рахунку)
                      bool isOut = t.fromId == widget.category.id;
                      String otherId = isOut ? t.toId : t.fromId;

                      final otherCat = categoryMap[otherId];

                      String customNote = t.title.trim();

                      bool isDefaultTitle =
                          customNote.isEmpty ||
                          customNote.contains('➡️') ||
                          customNote == otherCat?.name ||
                          customNote == widget.category.name ||
                          customNote == trOutgoing ||
                          customNote == trTopUp;

                      if (isDefaultTitle) customNote = '';

                      // ЛОГІКА "ПЕРСПЕКТИВИ" ВАЛЮТИ
                      // Головна сума — це сума з боку поточної категорії
                      int mainAmount = isOut
                          ? t.amount
                          : (t.targetAmount ?? t.amount);
                      String mainCurrency = isOut
                          ? t.currency
                          : (t.targetCurrency ?? t.currency);

                      // Другорядна сума — це сума з протилежного боку (напр. скільки списало з картки)
                      int secondaryAmount = isOut
                          ? (t.targetAmount ?? t.amount)
                          : t.amount;
                      String secondaryCurrency = isOut
                          ? (t.targetCurrency ?? t.currency)
                          : t.currency;

                      // Чи є транзакція мультивалютною?
                      bool isMultiCurrency =
                          mainCurrency != secondaryCurrency &&
                          t.targetCurrency != null;

                      String mainSymbol = AppCurrency.fromCode(
                        mainCurrency,
                      ).symbol;
                      String secondarySymbol = AppCurrency.fromCode(
                        secondaryCurrency,
                      ).symbol;

                      String prefix = "";
                      Color amountColor = colors.textMain;

                      if (widget.category.type == CategoryType.income) {
                        prefix = "+";
                        amountColor = colors.income;
                      } else if (widget.category.type == CategoryType.expense) {
                        prefix = "-";
                        amountColor = colors.expense;
                      } else {
                        prefix = isOut ? "-" : "+";
                        if (otherCat?.type == CategoryType.account) {
                          amountColor = colors.textSecondary;
                        } else {
                          amountColor = isOut ? colors.expense : colors.income;
                        }
                      }

                      return Dismissible(
                        key: Key(t.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          color: colors.expense,
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        // 👇 ОНОВЛЕНО: Миттєво приховуємо транзакцію перед тим, як викликати onDelete
                        onDismissed: (_) {
                          setState(() {
                            _localDeletedIds.add(t.id);
                          });
                          widget.onDelete(t);
                        },
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 4,
                          ),
                          onTap: () async => await widget.onEdit(t),
                          leading: otherCat != null
                              ? CircleAvatar(
                                  backgroundColor: Color(otherCat.bgColor),
                                  child: Icon(
                                    IconData(
                                      otherCat.icon,
                                      fontFamily: 'MaterialIcons',
                                    ),
                                    color: Color(otherCat.iconColor),
                                    size: 20,
                                  ),
                                )
                              : Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: colors.iconBg,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    isOut
                                        ? Icons.arrow_outward
                                        : Icons.arrow_downward,
                                    color: isOut
                                        ? colors.expense
                                        : colors.income,
                                    size: 20,
                                  ),
                                ),
                          title: Text(
                            otherCat?.name ?? (isOut ? trOutgoing : trTopUp),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: colors.textMain,
                              fontSize: 14,
                            ),
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _fastDateFormat(t.date),
                                  style: TextStyle(
                                    color: colors.textSecondary,
                                    fontSize: 12,
                                  ),
                                ),
                                if (customNote.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Icon(
                                        Icons.notes,
                                        size: 14,
                                        color: colors.textSecondary.withValues(
                                          alpha: 0.7,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          customNote,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontStyle: FontStyle.italic,
                                            color: colors.textSecondary,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  // Головна сума
                                  Text(
                                    "$prefix${CurrencyFormatter.format(mainAmount)} $mainSymbol",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: amountColor,
                                      fontSize: 14,
                                    ),
                                  ),
                                  // Додаткова сума дрібним шрифтом (тільки для мультивалютних)
                                  if (isMultiCurrency)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 2.0),
                                      child: Text(
                                        "~ ${CurrencyFormatter.format(secondaryAmount)} $secondarySymbol",
                                        style: TextStyle(
                                          color: colors.textSecondary,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                Icons.chevron_right,
                                size: 16,
                                color: colors.textSecondary,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
