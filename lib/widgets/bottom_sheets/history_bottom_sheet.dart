import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../models/category_model.dart';
import '../../models/transaction_model.dart';
import '../../utils/currency_formatter.dart';
import '../../theme/app_colors_extension.dart';

class HistoryBottomSheet extends StatefulWidget {
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
  State<HistoryBottomSheet> createState() => _HistoryBottomSheetState();
}

class _HistoryBottomSheetState extends State<HistoryBottomSheet> {
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColorsExtension>()!;

    // Фільтруємо історію тільки для цієї конкретної категорії
    final categoryHistory = widget.transactions
        .where(
          (t) => t.fromId == widget.category.id || t.toId == widget.category.id,
        )
        .toList();

    categoryHistory.sort((a, b) => b.date.compareTo(a.date));

    return Container(
      padding: const EdgeInsets.all(20),
      height: MediaQuery.of(context).size.height * 0.7,
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
            'history_category'.tr(args: [widget.category.name]),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: colors.textMain,
            ),
          ),
          const SizedBox(height: 15),
          Expanded(
            child: categoryHistory.isEmpty
                ? Center(
                    child: Text(
                      'no_transactions_yet'.tr(),
                      style: TextStyle(color: colors.textSecondary),
                    ),
                  )
                : ListView.builder(
                    itemCount: categoryHistory.length,
                    itemBuilder: (context, index) {
                      final t = categoryHistory[index];
                      bool isOut = t.fromId == widget.category.id;
                      String otherId = isOut ? t.toId : t.fromId;

                      Category? otherCat;
                      try {
                        otherCat = widget.allCategories.firstWhere(
                          (c) => c.id == otherId,
                        );
                      } catch (e) {
                        otherCat = null;
                      }

                      // --- УНІФІКОВАНА ЛОГІКА КОЛЬОРІВ ТА ПРЕФІКСІВ ---
                      String prefix = "";
                      Color amountColor = colors.textMain;

                      if (widget.category.type == CategoryType.income) {
                        prefix = "+";
                        amountColor = colors.income;
                      } else if (widget.category.type == CategoryType.expense) {
                        prefix = "-";
                        amountColor = colors.expense;
                      } else {
                        // Для Рахунків (Account) логіка складніша
                        prefix = isOut ? "-" : "+";
                        if (otherCat?.type == CategoryType.account) {
                          // Переказ між своїми — нейтральний колір
                          amountColor = colors.textSecondary;
                        } else {
                          // Поповнення або витрата — відповідний колір
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
                          setState(() {});
                        },
                        child: ListTile(
                          onTap: () async {
                            await widget.onEdit(t);
                            if (mounted) setState(() {});
                          },
                          leading: otherCat != null
                              ? CircleAvatar(
                                  backgroundColor: otherCat.bgColor,
                                  child: Icon(
                                    otherCat.icon,
                                    color: otherCat.iconColor,
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
                              // ЗМІНЕНО: Уніфікований розмір шрифту
                              fontSize: 14,
                            ),
                          ),
                          subtitle: Text(
                            "${t.date.day.toString().padLeft(2, '0')}.${t.date.month.toString().padLeft(2, '0')}.${t.date.year}",
                            style: TextStyle(
                              color: colors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                "$prefix${CurrencyFormatter.format(t.amount)} ₴",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: amountColor,
                                  // ЗМІНЕНО: Уніфікований розмір шрифту сум
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
