import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/finance_provider.dart';
import '../models/subscription_model.dart';
import '../models/category_model.dart';
import '../utils/currency_formatter.dart';
import '../widgets/dialogs/subscription_form_dialog.dart';

class SubscriptionsScreen extends StatelessWidget {
  const SubscriptionsScreen({super.key});

  void _showSubscriptionDialog(
    BuildContext context, {
    Subscription? subscription,
  }) {
    showDialog(
      context: context,
      builder: (context) => SubscriptionFormDialog(subscription: subscription),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<FinanceProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Регулярні платежі',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: ElevatedButton(
              onPressed: () => _showSubscriptionDialog(context),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 56),
                backgroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 4,
                shadowColor: Colors.black.withValues(alpha: 0.2),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_circle_outline, color: Colors.white),
                  SizedBox(width: 8),
                  Text(
                    'Додати підписку',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: provider.subscriptions.isEmpty
                ? const Center(
                    child: Text(
                      'У вас ще немає регулярних платежів',
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                  )
                : ListView.builder(
                    itemCount: provider.subscriptions.length,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 8,
                    ),
                    itemBuilder: (context, index) {
                      final sub = provider.subscriptions[index];

                      final category = provider.expenses.firstWhere(
                        (c) => c.id == sub.categoryId,
                        orElse: () => Category(
                          id: '',
                          type: CategoryType.expense,
                          name: 'Невідомо',
                          icon: Icons.help_outline,
                          bgColor: Colors.grey.shade200,
                          iconColor: Colors.black54,
                        ),
                      );

                      final displayIcon = sub.customIconCodePoint != null
                          ? IconData(
                              sub.customIconCodePoint!,
                              fontFamily: 'MaterialIcons',
                            )
                          : category.icon;

                      // --- Перевіряємо, чи підписка прострочена ---
                      final now = DateTime.now();
                      final today = DateTime(now.year, now.month, now.day);
                      final paymentDate = DateTime(
                        sub.nextPaymentDate.year,
                        sub.nextPaymentDate.month,
                        sub.nextPaymentDate.day,
                      );
                      final isDue =
                          paymentDate.isBefore(today) ||
                          paymentDate.isAtSameMomentAs(today);
                      // --------------------------------------------------------

                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(24),
                            onTap: () => _showSubscriptionDialog(
                              context,
                              subscription: sub,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        width: 50,
                                        height: 50,
                                        decoration: BoxDecoration(
                                          color: category.bgColor,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          displayIcon,
                                          color: category.iconColor,
                                          size: 24,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              sub.name,
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.black87,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 4),
                                            Row(
                                              children: [
                                                Icon(
                                                  Icons.event,
                                                  size: 14,
                                                  color: isDue
                                                      ? Colors.red
                                                      : Colors.grey,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  DateFormat(
                                                    'dd.MM.yyyy',
                                                  ).format(sub.nextPaymentDate),
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w500,
                                                    color: isDue
                                                        ? Colors.red
                                                        : Colors.grey.shade600,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            "-${CurrencyFormatter.format(sub.amount)} ₴",
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w900,
                                              color: Color(0xFFE05252),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),

                                  // --- Кнопка ручної оплати, якщо прострочено ---
                                  if (isDue) ...[
                                    const SizedBox(height: 12),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.red.withValues(
                                          alpha: 0.05,
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: Colors.red.withValues(
                                            alpha: 0.2,
                                          ),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          const Row(
                                            children: [
                                              Icon(
                                                Icons.warning_amber_rounded,
                                                color: Colors.red,
                                                size: 18,
                                              ),
                                              SizedBox(width: 6),
                                              Text(
                                                "Потребує оплати",
                                                style: TextStyle(
                                                  color: Colors.red,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 13,
                                                ),
                                              ),
                                            ],
                                          ),
                                          SizedBox(
                                            height: 32,
                                            child: ElevatedButton(
                                              style: ElevatedButton.styleFrom(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 16,
                                                    ),
                                                backgroundColor: Colors.red,
                                                foregroundColor: Colors.white,
                                                elevation: 0,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                              ),
                                              onPressed: () async {
                                                final (
                                                  success,
                                                  message,
                                                ) = await provider
                                                    .confirmSubscriptionPayment(
                                                      sub,
                                                      sub.amount,
                                                    );

                                                if (!context.mounted) return;

                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  SnackBar(
                                                    backgroundColor:
                                                        Colors.white,
                                                    behavior: SnackBarBehavior
                                                        .floating,
                                                    margin:
                                                        const EdgeInsets.only(
                                                          bottom: 30,
                                                          left: 20,
                                                          right: 20,
                                                        ),
                                                    elevation: 10,
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            16,
                                                          ),
                                                      side: BorderSide(
                                                        color: success
                                                            ? Colors.green
                                                                  .withValues(
                                                                    alpha: 0.5,
                                                                  )
                                                            : Colors.red
                                                                  .withValues(
                                                                    alpha: 0.5,
                                                                  ),
                                                      ),
                                                    ),
                                                    content: Row(
                                                      children: [
                                                        Container(
                                                          padding:
                                                              const EdgeInsets.all(
                                                                8,
                                                              ),
                                                          decoration: BoxDecoration(
                                                            color: success
                                                                ? Colors.green
                                                                      .withValues(
                                                                        alpha:
                                                                            0.1,
                                                                      )
                                                                : Colors.red
                                                                      .withValues(
                                                                        alpha:
                                                                            0.1,
                                                                      ),
                                                            shape:
                                                                BoxShape.circle,
                                                          ),
                                                          child: Icon(
                                                            success
                                                                ? Icons
                                                                      .check_circle_outline
                                                                : Icons
                                                                      .error_outline,
                                                            color: success
                                                                ? Colors.green
                                                                : Colors.red,
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                          width: 12,
                                                        ),
                                                        Expanded(
                                                          child: Text(
                                                            message,
                                                            style:
                                                                const TextStyle(
                                                                  color: Colors
                                                                      .black87,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w600,
                                                                ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                );
                                              },
                                              child: const Text(
                                                "Сплатити",
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                  // ---------------------------------------------------------
                                ],
                              ),
                            ),
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
