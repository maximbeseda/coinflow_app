import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:collection/collection.dart';
// 👇 ДОДАНО: Riverpod для реактивності
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../database/app_database.dart';
import '../../models/app_currency.dart';
import '../../utils/currency_formatter.dart';
import '../../utils/date_formatter.dart';
import '../../theme/app_colors_extension.dart';
// 👇 ДОДАНО: Наш хаб провайдерів
import '../../providers/all_providers.dart';

// 👇 ЗМІНЕНО: Тепер це ConsumerStatefulWidget
class HistoryBottomSheet extends ConsumerStatefulWidget {
  final Category category;
  // Ми залишаємо ці змінні в конструкторі, щоб не ламати код в home_screen.dart,
  // але всередині панелі ми будемо брати найсвіжіші дані прямо з провайдерів!
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
  // ✂️ ВИДАЛЕНО: initState, didUpdateWidget та локальні списки. Вони більше не потрібні!

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColorsExtension>()!;

    // 👇 МАГІЯ RIVERPOD: Слухаємо провайдери безпосередньо!
    final txState = ref.watch(transactionProvider);
    final catState = ref.watch(categoryProvider);

    // Фільтруємо та сортуємо транзакції "на льоту" з найсвіжіших даних
    final categoryHistory = txState.history
        .where(
          (t) => t.fromId == widget.category.id || t.toId == widget.category.id,
        )
        .toList();
    categoryHistory.sort((a, b) => b.date.compareTo(a.date));

    // Найсвіжіший список категорій (на випадок, якщо ми змінили колір іншої категорії)
    final allCategories = catState.allCategoriesList;

    return Container(
      padding: const EdgeInsets.all(20),
      height: MediaQuery.of(context).size.height * 0.7,
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

                      final otherCat = allCategories.firstWhereOrNull(
                        (c) => c.id == otherId,
                      );

                      // --- ЛОГІКА КОМЕНТАРІВ ---
                      String customNote = t.title.trim();
                      bool isDefaultTitle =
                          customNote.isEmpty ||
                          customNote.contains('➡️') ||
                          customNote == otherCat?.name ||
                          customNote == widget.category.name ||
                          customNote == 'outgoing_transfer'.tr() ||
                          customNote == 'top_up'.tr();

                      if (isDefaultTitle) customNote = '';

                      // --- РОЗРАХУНОК СУМИ ТА ВАЛЮТИ (в копійках) ---
                      int displayAmount = isOut
                          ? t.amount
                          : (t.targetAmount ?? t.amount);

                      String currencySymbol = AppCurrency.fromCode(
                        widget.category.currency,
                      ).symbol;

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
                          // 👇 ЗМІНЕНО: Ми просто викликаємо метод видалення.
                          // Оскільки панель слухає Riverpod, вона автоматично перемалюється
                          // відразу після оновлення бази. Ніяких setState!
                          widget.onDelete(t);
                        },
                        child: ListTile(
                          onTap: () async {
                            await widget.onEdit(t);
                            // 👇 ЗМІНЕНО: setState більше не потрібен!
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
