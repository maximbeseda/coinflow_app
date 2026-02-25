import 'package:flutter/material.dart';
import '../models/category_model.dart';
import '../models/transaction_model.dart';
import '../utils/currency_formatter.dart';

class GeneralHistoryBottomSheet extends StatefulWidget {
  final String title;
  final String filterType; // Прийматиме "acc" (рахунки) або "exp" (витрати)
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
    // Фільтруємо історію залежно від того, на що натиснули (Баланс чи Витрати)
    final filteredHistory = widget.transactions.where((t) {
      return t.fromId.startsWith(widget.filterType) ||
          t.toId.startsWith(widget.filterType);
    }).toList();

    // Сортуємо: найновіші зверху
    filteredHistory.sort((a, b) => b.date.compareTo(a.date));

    return Container(
      padding: const EdgeInsets.all(20),
      height:
          MediaQuery.of(context).size.height * 0.85, // Зробимо його трохи вищим
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

                      // Шукаємо категорії "Звідки" і "Куди"
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

                      // Визначаємо знак і колір суми
                      bool isIncome =
                          t.fromId.startsWith("inc") &&
                          t.toId.startsWith("acc");
                      bool isTransfer =
                          t.fromId.startsWith("acc") &&
                          t.toId.startsWith("acc");

                      String prefix = "-";
                      Color amountColor = Colors.red;

                      if (widget.filterType == "acc") {
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
                              // Обгортаємо першу назву у Flexible
                              Flexible(
                                child: Text(
                                  fromName,
                                  maxLines: 1,
                                  overflow:
                                      TextOverflow.ellipsis, // Додає "..."
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
                              // Обгортаємо другу назву у Flexible
                              Flexible(
                                child: Text(
                                  toName,
                                  maxLines: 1,
                                  overflow:
                                      TextOverflow.ellipsis, // Додає "..."
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
