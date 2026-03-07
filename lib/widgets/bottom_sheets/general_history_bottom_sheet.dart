import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../models/category_model.dart';
import '../../models/transaction_model.dart';
import '../../utils/currency_formatter.dart';
import '../../theme/app_colors_extension.dart'; // ДОДАНО: Імпорт теми

class GeneralHistoryBottomSheet extends StatefulWidget {
  final String title;
  final CategoryType filterType; // ЗМІНЕНО: Тепер використовуємо безпечний Enum
  final List<Transaction> transactions;
  final List<Category> allCategories;
  final Function(Transaction) onDelete;
  final Function(Transaction) onEdit;

  const GeneralHistoryBottomSheet({
    super.key,
    required this.title,
    required this.filterType, // ЗМІНЕНО
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
    // ДОДАНО: Отримуємо кольори поточної теми
    final colors = Theme.of(context).extension<AppColorsExtension>()!;

    // 1. Фільтруємо історію за реальним типом категорії
    final filteredHistory = widget.transactions.where((t) {
      Category? fromCat;
      Category? toCat;
      try {
        fromCat = widget.allCategories.firstWhere((c) => c.id == t.fromId);
      } catch (_) {}
      try {
        toCat = widget.allCategories.firstWhere((c) => c.id == t.toId);
      } catch (_) {}

      // Перевіряємо, чи хоча б одна сторона транзакції відповідає нашому фільтру
      return fromCat?.type == widget.filterType ||
          toCat?.type == widget.filterType;
    }).toList();

    // Сортуємо: найновіші зверху
    filteredHistory.sort((a, b) => b.date.compareTo(a.date));

    return Container(
      padding: const EdgeInsets.all(20),
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: colors.cardBg, // ЗМІНЕНО: Фон панелі
        borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
      ),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: colors.textSecondary.withValues(
                alpha: 0.2,
              ), // ЗМІНЕНО: Колір повзунка
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            widget.title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: colors.textMain, // ЗМІНЕНО
            ),
          ),
          const SizedBox(height: 15),
          Expanded(
            child: filteredHistory.isEmpty
                ? Center(
                    child: Text(
                      'no_transactions_yet'.tr(),
                      style: TextStyle(color: colors.textSecondary), // ЗМІНЕНО
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

                      // 2. Визначаємо тип операції через безпечний Enum
                      bool isIncome = fromCat?.type == CategoryType.income;
                      bool isTransfer =
                          fromCat?.type == CategoryType.account &&
                          toCat?.type == CategoryType.account;

                      // ЗМІНЕНО: Логіка визначення префіксів та кольорів сум
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
                          color: colors.expense, // ЗМІНЕНО: Фон при видаленні
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          child: const Icon(
                            Icons.delete,
                            color: Colors.white,
                          ), // Іконка біла
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
                            backgroundColor:
                                toCat?.bgColor ??
                                colors.iconBg, // ЗМІНЕНО: Запасний фон
                            child: Icon(
                              toCat?.icon ?? Icons.help_outline,
                              color:
                                  toCat?.iconColor ??
                                  colors.textSecondary, // ЗМІНЕНО
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
                                    color: colors.textMain, // ЗМІНЕНО
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
                                  color: colors.textSecondary, // ЗМІНЕНО
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
                                    color: colors.textMain, // ЗМІНЕНО
                                  ),
                                ),
                              ),
                            ],
                          ),
                          subtitle: Text(
                            "${t.date.day.toString().padLeft(2, '0')}.${t.date.month.toString().padLeft(2, '0')}.${t.date.year}",
                            style: TextStyle(
                              fontSize: 12,
                              color: colors.textSecondary, // ЗМІНЕНО
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
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                Icons.chevron_right,
                                size: 16,
                                color: colors.textSecondary, // ЗМІНЕНО
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
