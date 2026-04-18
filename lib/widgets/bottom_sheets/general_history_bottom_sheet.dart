import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../database/app_database.dart';
import '../../models/app_currency.dart';
import '../../utils/currency_formatter.dart';
import '../../theme/app_colors_extension.dart';
import '../../providers/all_providers.dart';
import '../common/history_search_bar.dart';

class GeneralHistoryBottomSheet extends ConsumerStatefulWidget {
  final String title;
  final CategoryType filterType;
  final List<Transaction> transactions;
  final List<Category> allCategories;
  final Function(Transaction) onDelete;
  final Function(Transaction) onEdit;

  const GeneralHistoryBottomSheet({
    super.key,
    required this.title,
    required this.filterType,
    required this.transactions,
    required this.allCategories,
    required this.onDelete,
    required this.onEdit,
  });

  @override
  ConsumerState<GeneralHistoryBottomSheet> createState() =>
      _GeneralHistoryBottomSheetState();
}

class _GeneralHistoryBottomSheetState
    extends ConsumerState<GeneralHistoryBottomSheet> {
  final ScrollController _scrollController = ScrollController();
  bool _isFetchingMore = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final notifier = ref.read(filterProvider.notifier);
      notifier.initGeneral();
      notifier.setCategoryType(widget.filterType);
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

    final allCategories = catState.allCategoriesList;
    final filteredHistory = filterState.results;

    final showLoader = filterState.hasMore && filterState.searchQuery.isEmpty;

    final categoryMap = {for (var c in allCategories) c.id: c};

    // КЕШУЄМО ЛОКАЛІЗАЦІЮ
    final trUnknown = 'unknown'.tr();
    final trOutgoing = 'outgoing_transfer'.tr();
    final trTopUp = 'top_up'.tr();

    final Map<String, String> currencyCache = {};

    return Container(
      padding: const EdgeInsets.only(top: 20, left: 16, right: 16),
      height: MediaQuery.of(context).size.height * 0.85,
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
            widget.title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: colors.textMain,
            ),
          ),
          const SizedBox(height: 16),

          HistorySearchBar(specificType: widget.filterType),

          const SizedBox(height: 12),

          Expanded(
            child: filterState.isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredHistory.isEmpty
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
                    itemCount: filteredHistory.length + (showLoader ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == filteredHistory.length) {
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

                      final t = filteredHistory[index];

                      final fromCat = categoryMap[t.fromId];
                      final toCat = categoryMap[t.toId];

                      // 👇 ВИПРАВЛЕНО: Використовуємо змінні з кешу
                      String fromName = fromCat?.name ?? trUnknown;
                      String toName = toCat?.name ?? trUnknown;

                      bool isIncome = fromCat?.type == CategoryType.income;
                      bool isTransfer =
                          fromCat?.type == CategoryType.account &&
                          toCat?.type == CategoryType.account;

                      String customNote = t.title.trim();

                      // 👇 ВИПРАВЛЕНО: Використовуємо змінні з кешу
                      bool isDefaultTitle =
                          customNote.isEmpty ||
                          customNote.contains('➡️') ||
                          customNote == fromName ||
                          customNote == toName ||
                          customNote == trOutgoing ||
                          customNote == trTopUp;

                      if (isDefaultTitle) customNote = '';

                      int displayAmount = t.amount;
                      String currencyCode = t.currency;

                      if (widget.filterType == CategoryType.expense &&
                          toCat?.type == CategoryType.expense) {
                        displayAmount = t.targetAmount ?? t.amount;
                        currencyCode = t.targetCurrency ?? t.currency;
                      } else if (widget.filterType == CategoryType.income ||
                          widget.filterType == CategoryType.account) {
                        displayAmount = t.amount;
                        currencyCode = t.currency;
                      }

                      String currencySymbol = currencyCache.putIfAbsent(
                        currencyCode,
                        () => AppCurrency.fromCode(currencyCode).symbol,
                      );

                      String prefix = "-";
                      Color amountColor = colors.expense;

                      if (widget.filterType == CategoryType.income) {
                        prefix = "+";
                        amountColor = colors.income;
                      } else if (widget.filterType == CategoryType.expense) {
                        prefix = "-";
                        amountColor = colors.expense;
                      } else if (widget.filterType == CategoryType.account) {
                        if (isIncome) {
                          prefix = "+";
                          amountColor = colors.income;
                        } else if (isTransfer) {
                          prefix = "";
                          amountColor = colors.textSecondary;
                        } else {
                          prefix = "-";
                          amountColor = colors.expense;
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
                        onDismissed: (_) => widget.onDelete(t),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 4,
                          ),
                          onTap: () async => await widget.onEdit(t),
                          leading: CircleAvatar(
                            backgroundColor: toCat != null
                                ? Color(toCat.bgColor)
                                : colors.iconBg,
                            child: Icon(
                              toCat != null
                                  ? IconData(
                                      toCat.icon,
                                      fontFamily: 'MaterialIcons',
                                    )
                                  : Icons.help_outline,
                              color: toCat != null
                                  ? Color(toCat.iconColor)
                                  : colors.textSecondary,
                              size: 20,
                            ),
                          ),
                          title: Row(
                            children: [
                              Flexible(
                                child: Text(
                                  fromName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: colors.textMain,
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4.0,
                                ),
                                child: Icon(
                                  Icons.arrow_forward,
                                  size: 14,
                                  color: colors.textSecondary,
                                ),
                              ),
                              Flexible(
                                child: Text(
                                  toName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: colors.textMain,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _fastDateFormat(t.date),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: colors.textSecondary,
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
                            children: [
                              Text(
                                "$prefix${CurrencyFormatter.format(displayAmount)} $currencySymbol",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: amountColor,
                                  fontSize: 14,
                                ),
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
