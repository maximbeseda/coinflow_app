import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import '../providers/finance_provider.dart';
import '../models/subscription_model.dart';
import '../models/category_model.dart';
import '../utils/currency_formatter.dart';
import '../widgets/dialogs/subscription_form_dialog.dart';
import '../theme/app_colors_extension.dart'; // ДОДАНО: Імпорт контракту кольорів

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
    // ДОДАНО: Отримуємо кольори поточної теми!
    final colors = Theme.of(context).extension<AppColorsExtension>()!;

    // ОБГОРТАЄМО SCAFFOLD У КОНТЕЙНЕР З ГРАДІЄНТОМ
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            colors.bgGradientStart, // ЗМІНЕНО: Градієнт теми
            colors.bgGradientEnd,
          ],
        ),
      ),
      child: Scaffold(
        backgroundColor:
            Colors.transparent, // Робимо фон прозорим, щоб бачити градієнт
        appBar: AppBar(
          iconTheme: IconThemeData(
            color: colors.textMain,
          ), // Колір кнопки "Назад"
          title: Text(
            'regular_payments'.tr(),
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: colors.textMain, // ЗМІНЕНО
            ),
          ),
          centerTitle: true,
          backgroundColor: Colors.transparent,
          elevation: 0, // Прибираємо тінь від шапки
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: ElevatedButton(
                onPressed: () => _showSubscriptionDialog(context),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 56),
                  // ЗМІНЕНО: Прибрали backgroundColor: Colors.black,
                  // Тепер кнопка бере колір з ThemeData.elevatedButtonTheme!
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 4,
                  shadowColor: Colors.black.withValues(
                    alpha: 0.2,
                  ), // Тінь можемо лишити чорною
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.add_circle_outline,
                    ), // ЗМІНЕНО: Прибрали жорсткий білий колір
                    const SizedBox(width: 8),
                    Text(
                      'add_subscription'.tr(),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: provider.subscriptions.isEmpty
                  ? Center(
                      child: Text(
                        'no_subscriptions'.tr(),
                        style: TextStyle(
                          color: colors.textSecondary, // ЗМІНЕНО
                          fontSize: 16,
                        ),
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
                        // --- ДОДАЄМО ПЕРЕВІРКУ НА "ЗЛАМАНІСТЬ" ---
                        final bool accountExists = provider.accounts.any(
                          (c) => c.id == sub.accountId,
                        );
                        final bool expenseExists = provider.expenses.any(
                          (c) => c.id == sub.categoryId,
                        );
                        final bool isBroken = !accountExists || !expenseExists;
                        // ------------------------------------------

                        final category = provider.expenses.firstWhere(
                          (c) => c.id == sub.categoryId,
                          orElse: () => Category(
                            id: '',
                            type: CategoryType.expense,
                            name: 'unknown'.tr(),
                            icon: Icons.help_outline,
                            bgColor: colors.iconBg, // ЗМІНЕНО
                            iconColor: colors.textSecondary, // ЗМІНЕНО
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
                            color: colors.cardBg, // ЗМІНЕНО
                            borderRadius: BorderRadius.circular(24),
                            // --- ДОДАЄМО РАМКУ З ТЕМИ, ЯКЩО ПІДПИСКА ЗЛАМАНА ---
                            border: isBroken
                                ? Border.all(
                                    color: colors.expense.withValues(
                                      alpha: 0.5,
                                    ), // ЗМІНЕНО
                                    width: 1.5,
                                  )
                                : null,
                            // ----------------------------------------------------
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
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  color: colors
                                                      .textMain, // ЗМІНЕНО
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
                                                        ? colors
                                                              .expense // ЗМІНЕНО
                                                        : colors
                                                              .textSecondary, // ЗМІНЕНО
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    DateFormat(
                                                      'dd.MM.yyyy',
                                                    ).format(
                                                      sub.nextPaymentDate,
                                                    ),
                                                    style: TextStyle(
                                                      fontSize: 13,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                      color: isDue
                                                          ? colors
                                                                .expense // ЗМІНЕНО
                                                          : colors
                                                                .textSecondary, // ЗМІНЕНО
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
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w900,
                                                color:
                                                    colors.expense, // ЗМІНЕНО
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
                                          color: colors.expense.withValues(
                                            alpha: 0.05,
                                          ), // ЗМІНЕНО
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          border: Border.all(
                                            color: colors.expense.withValues(
                                              alpha: 0.2,
                                            ), // ЗМІНЕНО
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Row(
                                              children: [
                                                Icon(
                                                  Icons.warning_amber_rounded,
                                                  color:
                                                      colors.expense, // ЗМІНЕНО
                                                  size: 18,
                                                ),
                                                const SizedBox(width: 6),
                                                Text(
                                                  'needs_payment'.tr(),
                                                  style: TextStyle(
                                                    color: colors
                                                        .expense, // ЗМІНЕНО
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
                                                  backgroundColor: colors
                                                      .expense, // ЗМІНЕНО: Залишаємо виділеним кольором витрати
                                                  foregroundColor: Colors.white,
                                                  elevation: 0,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          8,
                                                        ),
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
                                                  ).clearSnackBars();

                                                  ScaffoldMessenger.of(
                                                    context,
                                                  ).showSnackBar(
                                                    SnackBar(
                                                      backgroundColor: colors
                                                          .cardBg, // ЗМІНЕНО
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
                                                              ? colors
                                                                    .income // ЗМІНЕНО
                                                                    .withValues(
                                                                      alpha:
                                                                          0.5,
                                                                    )
                                                              : colors
                                                                    .expense // ЗМІНЕНО
                                                                    .withValues(
                                                                      alpha:
                                                                          0.5,
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
                                                                  ? colors
                                                                        .income // ЗМІНЕНО
                                                                        .withValues(
                                                                          alpha:
                                                                              0.1,
                                                                        )
                                                                  : colors
                                                                        .expense // ЗМІНЕНО
                                                                        .withValues(
                                                                          alpha:
                                                                              0.1,
                                                                        ),
                                                              shape: BoxShape
                                                                  .circle,
                                                            ),
                                                            child: Icon(
                                                              success
                                                                  ? Icons
                                                                        .check_circle_outline
                                                                  : Icons
                                                                        .error_outline,
                                                              color: success
                                                                  ? colors
                                                                        .income // ЗМІНЕНО
                                                                  : colors
                                                                        .expense, // ЗМІНЕНО
                                                            ),
                                                          ),
                                                          const SizedBox(
                                                            width: 12,
                                                          ),
                                                          Expanded(
                                                            child: Text(
                                                              message,
                                                              style: TextStyle(
                                                                color: colors
                                                                    .textMain, // ЗМІНЕНО
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
                                                child: Text(
                                                  'pay'.tr(),
                                                  style: const TextStyle(
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
      ),
    );
  }
}
