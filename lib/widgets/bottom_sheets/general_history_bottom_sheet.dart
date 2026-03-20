import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../models/category_model.dart';
import '../../models/transaction_model.dart';
import '../../models/app_currency.dart';
import '../../utils/currency_formatter.dart';
import '../../theme/app_colors_extension.dart';

class GeneralHistoryBottomSheet extends StatefulWidget {
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
  State<GeneralHistoryBottomSheet> createState() =>
      _GeneralHistoryBottomSheetState();
}

class _GeneralHistoryBottomSheetState extends State<GeneralHistoryBottomSheet> {
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColorsExtension>()!;

    final filteredHistory = widget.transactions.where((t) {
      Category? fromCat;
      Category? toCat;
      try {
        fromCat = widget.allCategories.firstWhere((c) => c.id == t.fromId);
      } catch (_) {}
      try {
        toCat = widget.allCategories.firstWhere((c) => c.id == t.toId);
      } catch (_) {}

      return fromCat?.type == widget.filterType ||
          toCat?.type == widget.filterType;
    }).toList();

    filteredHistory.sort((a, b) => b.date.compareTo(a.date));

    return Container(
      padding: const EdgeInsets.all(20),
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: colors.cardBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
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
          const SizedBox(height: 15),
          Expanded(
            child: filteredHistory.isEmpty
                ? Center(
                    child: Text(
                      'no_transactions_yet'.tr(),
                      style: TextStyle(color: colors.textSecondary),
                    ),
                  )
                : ListView.builder(
                    itemCount: filteredHistory.length,
                    itemBuilder: (context, index) {
                      final t = filteredHistory[index];

                      Category? fromCat;
                      Category? toCat;
                      try {
                        fromCat = widget.allCategories.firstWhere(
                          (c) => c.id == t.fromId,
                        );
                      } catch (_) {}
                      try {
                        toCat = widget.allCategories.firstWhere(
                          (c) => c.id == t.toId,
                        );
                      } catch (_) {}

                      String fromName = fromCat?.name ?? 'unknown'.tr();
                      String toName = toCat?.name ?? 'unknown'.tr();

                      bool isIncome = fromCat?.type == CategoryType.income;
                      bool isTransfer =
                          fromCat?.type == CategoryType.account &&
                          toCat?.type == CategoryType.account;

                      // --- ЛОГІКА КОМЕНТАРІВ ---
                      String customNote = t.title.trim();
                      bool isDefaultTitle =
                          customNote.isEmpty ||
                          customNote.contains('➡️') ||
                          customNote == fromName ||
                          customNote == toName ||
                          customNote == 'outgoing_transfer'.tr() ||
                          customNote == 'top_up'.tr();

                      if (isDefaultTitle) customNote = '';

                      // --- РОЗРАХУНОК СУМИ ТА ВАЛЮТИ ---
                      double displayAmount = t.amount;
                      String currencyCode = t.currency;

                      if (widget.filterType == CategoryType.expense &&
                          toCat?.type == CategoryType.expense) {
                        displayAmount = t.targetAmount ?? t.amount;
                        currencyCode = t.targetCurrency ?? t.currency;
                      } else if (widget.filterType == CategoryType.income) {
                        displayAmount = t.amount;
                        currencyCode = t.currency;
                      } else if (widget.filterType == CategoryType.account) {
                        displayAmount = t.amount;
                        currencyCode = t.currency;
                      }

                      String currencySymbol = AppCurrency.fromCode(
                        currencyCode,
                      ).symbol;

                      // --- ЛОГІКА ПРЕФІКСІВ ТА КОЛЬОРІВ ---
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
                        onDismissed: (_) {
                          widget.onDelete(t);
                          setState(() {});
                        },
                        child: ListTile(
                          onTap: () async {
                            await widget.onEdit(t);
                            if (mounted) setState(() {});
                          },
                          leading: CircleAvatar(
                            backgroundColor: toCat?.bgColor ?? colors.iconBg,
                            child: Icon(
                              toCat?.icon ?? Icons.help_outline,
                              color: toCat?.iconColor ?? colors.textSecondary,
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
                          // ЗМІНЕНО: Відображення дати + коментаря (якщо є)
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "${t.date.day.toString().padLeft(2, '0')}.${t.date.month.toString().padLeft(2, '0')}.${t.date.year}",
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
