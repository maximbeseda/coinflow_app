import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../database/app_database.dart';
import '../../models/app_currency.dart';
import '../../providers/all_providers.dart';
import '../../theme/app_colors_extension.dart';
import '../../utils/currency_formatter.dart';
import '../../utils/date_formatter.dart';

class StatsCategoryBottomSheet extends ConsumerStatefulWidget {
  final Category category;
  final DateTime statsMonth;
  final String baseCurrencySymbol;
  final bool showExpenses;

  const StatsCategoryBottomSheet({
    super.key,
    required this.category,
    required this.statsMonth,
    required this.baseCurrencySymbol,
    required this.showExpenses,
  });

  @override
  ConsumerState<StatsCategoryBottomSheet> createState() =>
      _StatsCategoryBottomSheetState();
}

class _StatsCategoryBottomSheetState
    extends ConsumerState<StatsCategoryBottomSheet> {
  bool _isFetchingMore = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final filterNotifier = ref.read(filterProvider.notifier);
      filterNotifier.initForCategory(widget.category.id);

      final start = DateTime(
        widget.statsMonth.year,
        widget.statsMonth.month,
        1,
      );
      final end = DateTime(
        widget.statsMonth.year,
        widget.statsMonth.month + 1,
        0,
        23,
        59,
        59,
      );
      filterNotifier.setDateRange(start, end);
    });
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
    final filterState = ref.watch(filterProvider);
    final filteredTxs = filterState.results;
    final showLoader = filterState.hasMore;

    final allCategories = ref.watch(categoryProvider).allCategoriesList;
    final categoryMap = {for (var c in allCategories) c.id: c};

    final trUnknown = 'unknown'.tr();
    final trOutgoing = 'outgoing_transfer'.tr();
    final trTopUp = 'top_up'.tr();

    final Map<String, String> currencyCache = {};

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      builder: (_, controller) {
        return Container(
          decoration: BoxDecoration(
            color: colors.cardBg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.textSecondary.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: Color(widget.category.bgColor),
                      child: Icon(
                        IconData(
                          widget.category.icon,
                          fontFamily: 'MaterialIcons',
                        ),
                        color: Color(widget.category.iconColor),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.category.name,
                            style: TextStyle(
                              color: colors.textMain,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            DateFormatter.formatMonthYear(
                              widget.statsMonth,
                              context.locale.languageCode,
                            ),
                            style: TextStyle(
                              color: colors.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      "${CurrencyFormatter.format(widget.category.amount.abs())} ${widget.baseCurrencySymbol}",
                      style: TextStyle(
                        color: widget.showExpenses
                            ? colors.expense
                            : colors.income,
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Divider(
                height: 1,
                color: colors.textSecondary.withValues(alpha: 0.1),
              ),

              Expanded(
                child: filterState.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : filteredTxs.isEmpty
                    ? Center(
                        child: Text(
                          'no_data'.tr(),
                          style: TextStyle(color: colors.textSecondary),
                        ),
                      )
                    : NotificationListener<ScrollNotification>(
                        onNotification: (ScrollNotification scrollInfo) {
                          if (scrollInfo.metrics.pixels >=
                              scrollInfo.metrics.maxScrollExtent - 150) {
                            if (filterState.hasMore && !_isFetchingMore) {
                              _isFetchingMore = true;
                              ref
                                  .read(filterProvider.notifier)
                                  .loadNextPage()
                                  .then((_) {
                                    if (mounted) _isFetchingMore = false;
                                  });
                            }
                          }
                          return false;
                        },
                        child: ListView.builder(
                          controller: controller,
                          physics: const BouncingScrollPhysics(),
                          cacheExtent: 1000,
                          itemCount: filteredTxs.length + (showLoader ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index == filteredTxs.length) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 24.0,
                                ),
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

                            final tx = filteredTxs[index];

                            final fromCat = categoryMap[tx.fromId];
                            final toCat = categoryMap[tx.toId];

                            String fromName = fromCat?.name ?? trUnknown;
                            String toName = toCat?.name ?? trUnknown;

                            String customNote = tx.title.trim();

                            bool isDefaultTitle =
                                customNote.isEmpty ||
                                customNote.contains('➡️') ||
                                customNote == fromName ||
                                customNote == toName ||
                                customNote == trOutgoing ||
                                customNote == trTopUp;

                            if (isDefaultTitle) customNote = '';

                            final iconCat = widget.showExpenses
                                ? fromCat
                                : toCat;

                            // 👇 ЛОГІКА ПЕРСПЕКТИВИ ДЛЯ МУЛЬТИВАЛЮТНОСТІ
                            bool isOut = tx.fromId == widget.category.id;

                            int mainAmount = isOut
                                ? tx.amount
                                : (tx.targetAmount ?? tx.amount);
                            String mainCurrency = isOut
                                ? tx.currency
                                : (tx.targetCurrency ?? tx.currency);

                            int secondaryAmount = isOut
                                ? (tx.targetAmount ?? tx.amount)
                                : tx.amount;
                            String secondaryCurrency = isOut
                                ? (tx.targetCurrency ?? tx.currency)
                                : tx.currency;

                            bool isMultiCurrency =
                                mainCurrency != secondaryCurrency &&
                                tx.targetCurrency != null;

                            String mainSymbol = currencyCache.putIfAbsent(
                              mainCurrency,
                              () => AppCurrency.fromCode(mainCurrency).symbol,
                            );
                            String secondarySymbol = currencyCache.putIfAbsent(
                              secondaryCurrency,
                              () => AppCurrency.fromCode(
                                secondaryCurrency,
                              ).symbol,
                            );

                            String prefix = widget.showExpenses ? "-" : "+";
                            Color amountColor = widget.showExpenses
                                ? colors.expense
                                : colors.income;

                            return ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 4,
                              ),
                              leading: CircleAvatar(
                                backgroundColor: iconCat != null
                                    ? Color(iconCat.bgColor)
                                    : colors.iconBg,
                                child: Icon(
                                  iconCat != null
                                      ? IconData(
                                          iconCat.icon,
                                          fontFamily: 'MaterialIcons',
                                        )
                                      : Icons.help_outline,
                                  color: iconCat != null
                                      ? Color(iconCat.iconColor)
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
                                      _fastDateFormat(tx.date),
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
                                            color: colors.textSecondary
                                                .withValues(alpha: 0.7),
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
                              trailing: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    "$prefix${CurrencyFormatter.format(mainAmount.abs())} $mainSymbol",
                                    style: TextStyle(
                                      color: amountColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                  if (isMultiCurrency)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 2.0),
                                      child: Text(
                                        "~ ${CurrencyFormatter.format(secondaryAmount.abs())} $secondarySymbol",
                                        style: TextStyle(
                                          color: colors.textSecondary,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}
