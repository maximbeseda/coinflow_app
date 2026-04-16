import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../database/app_database.dart';
import '../../models/app_currency.dart';
import '../../utils/currency_formatter.dart';
import '../../utils/date_formatter.dart';
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
  @override
  void initState() {
    super.initState();
    // 👇 Говоримо провайдеру, що ми відкрили історію конкретної категорії
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(filterProvider.notifier).initForCategory(widget.category.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColorsExtension>()!;

    final catState = ref.watch(categoryProvider);
    final filterState = ref.watch(filterProvider);

    // 👇 ВСЕ! Більше ніякої фільтрації. Ми просто беремо готові результати з SQL.
    final categoryHistory = filterState.results;
    final allCategories = catState.allCategoriesList;

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
                    physics: const BouncingScrollPhysics(),
                    itemCount: categoryHistory.length,
                    itemBuilder: (context, index) {
                      final t = categoryHistory[index];
                      bool isOut = t.fromId == widget.category.id;
                      String otherId = isOut ? t.toId : t.fromId;

                      final otherCat = allCategories.firstWhereOrNull(
                        (c) => c.id == otherId,
                      );

                      String customNote = t.title.trim();
                      bool isDefaultTitle =
                          customNote.isEmpty ||
                          customNote.contains('➡️') ||
                          customNote == otherCat?.name ||
                          customNote == widget.category.name ||
                          customNote == 'outgoing_transfer'.tr() ||
                          customNote == 'top_up'.tr();

                      if (isDefaultTitle) customNote = '';

                      int displayAmount = isOut
                          ? t.amount
                          : (t.targetAmount ?? t.amount);
                      String currencySymbol = AppCurrency.fromCode(
                        widget.category.currency,
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
                        onDismissed: (_) {
                          widget.onDelete(t);
                        },
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 4,
                          ),
                          onTap: () async {
                            await widget.onEdit(t);
                          },
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
                            otherCat?.name ??
                                (isOut
                                    ? 'outgoing_transfer'.tr()
                                    : 'top_up'.tr()),
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
                                  DateFormatter.formatFull(t.date),
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
