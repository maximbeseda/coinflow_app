import 'package:flutter/material.dart';
import '../models/category_model.dart';
import '../models/transaction_model.dart';
import '../utils/currency_formatter.dart';

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
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            widget.title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 15),
          Expanded(
            child: filteredHistory.isEmpty
                ? const Center(child: Text("Операцій ще не було"))
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

                      String fromName = fromCat?.name ?? "Невідомо";
                      String toName = toCat?.name ?? "Невідомо";

                      // 2. Визначаємо тип операції через безпечний Enum
                      bool isIncome = fromCat?.type == CategoryType.income;
                      bool isTransfer =
                          fromCat?.type == CategoryType.account &&
                          toCat?.type == CategoryType.account;

                      String prefix = "-";
                      Color amountColor = Colors.red;

                      // Жорстко задаємо кольори для загальних списків
                      if (widget.filterType == CategoryType.income) {
                        prefix = "+";
                        amountColor = Colors.green;
                      } else if (widget.filterType == CategoryType.account) {
                        if (isIncome) {
                          prefix = "+";
                          amountColor = Colors.green;
                        } else if (isTransfer) {
                          prefix = "";
                          amountColor = Colors.grey;
                        }
                      }

                      return Dismissible(
                        key: Key(t.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          color: Colors.red,
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
                            backgroundColor:
                                toCat?.bgColor ?? Colors.grey.shade200,
                            child: Icon(
                              toCat?.icon ?? Icons.help_outline,
                              color: toCat?.iconColor ?? Colors.black54,
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
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 4.0),
                                child: Icon(
                                  Icons.arrow_forward,
                                  size: 14,
                                  color: Colors.grey,
                                ),
                              ),
                              Flexible(
                                child: Text(
                                  toName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          subtitle: Text(
                            "${t.date.day.toString().padLeft(2, '0')}.${t.date.month.toString().padLeft(2, '0')}.${t.date.year}",
                            style: const TextStyle(fontSize: 12),
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
                              const Icon(
                                Icons.chevron_right,
                                size: 16,
                                color: Colors.grey,
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
