import 'package:flutter/material.dart';
import '../models/category_model.dart';
import '../models/transaction_model.dart';
import '../utils/currency_formatter.dart';

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
    // Фільтруємо історію тільки для цієї категорії
    final categoryHistory = widget.transactions
        .where(
          (t) => t.fromId == widget.category.id || t.toId == widget.category.id,
        )
        .toList();

    // Сортування для гарантії порядку (найновіші зверху)
    categoryHistory.sort((a, b) => b.date.compareTo(a.date));

    return Container(
      padding: const EdgeInsets.all(20),
      height: MediaQuery.of(context).size.height * 0.7,
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
            "Історія: ${widget.category.name}",
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 15),
          Expanded(
            child: categoryHistory.isEmpty
                ? const Center(child: Text("Операцій ще не було"))
                : ListView.builder(
                    itemCount: categoryHistory.length,
                    itemBuilder: (context, index) {
                      final t = categoryHistory[index];
                      // Визначаємо, чи гроші пішли З цієї категорії
                      bool isOut = t.fromId == widget.category.id;

                      // Знаходимо ID "іншої" сторони транзакції
                      String otherId = isOut ? t.toId : t.fromId;

                      // Шукаємо цю категорію в загальному списку
                      Category? otherCat;
                      try {
                        otherCat = widget.allCategories.firstWhere(
                          (c) => c.id == otherId,
                        );
                      } catch (e) {
                        otherCat = null;
                      }

                      // --- НОВА ЛОГІКА КОЛЬОРІВ ---
                      String prefix = "";
                      Color amountColor = Colors.black;

                      if (widget.category.type == CategoryType.income) {
                        // Доходи завжди зелені з плюсом
                        prefix = "+";
                        amountColor = Colors.green;
                      } else if (widget.category.type == CategoryType.expense) {
                        // Витрати завжди червоні з мінусом
                        prefix = "-";
                        amountColor = Colors.red;
                      } else {
                        // Якщо це Рахунок (Account), дивимось куди йдуть гроші
                        if (otherCat?.type == CategoryType.account) {
                          prefix = isOut ? "-" : "+";
                          amountColor =
                              Colors.grey; // Перекази між своїми рахунками сірі
                        } else {
                          prefix = isOut ? "-" : "+";
                          amountColor = isOut ? Colors.red : Colors.green;
                        }
                      }
                      // ----------------------------

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
                            if (mounted) {
                              setState(() {});
                            }
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
                              : Icon(
                                  isOut
                                      ? Icons.arrow_outward
                                      : Icons.arrow_downward,
                                  color: isOut ? Colors.red : Colors.green,
                                ),
                          // ДОДАНО: maxLines та overflow для довгого тексту
                          title: Text(
                            otherCat?.name ??
                                (isOut ? "Вихідний переказ" : "Поповнення"),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          subtitle: Text(
                            "${t.date.day.toString().padLeft(2, '0')}.${t.date.month.toString().padLeft(2, '0')}.${t.date.year}",
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
