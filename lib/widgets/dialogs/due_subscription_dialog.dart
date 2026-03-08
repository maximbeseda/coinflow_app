import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../models/subscription_model.dart';
import '../../providers/finance_provider.dart';
import '../../theme/app_colors_extension.dart'; // ДОДАНО: Імпорт теми

class DueSubscriptionDialog extends StatelessWidget {
  final Subscription subscription;

  const DueSubscriptionDialog({super.key, required this.subscription});

  @override
  Widget build(BuildContext context) {
    // ДОДАНО: Отримуємо кольори теми
    final colors = Theme.of(context).extension<AppColorsExtension>()!;

    // Всі стилі Dialog підтягуються з глобальної теми!
    return Dialog(
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colors.income.withValues(
                      alpha: 0.1,
                    ), // ЗМІНЕНО: зелений з теми
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.account_balance_wallet_rounded,
                    color: colors.income, // ЗМІНЕНО: зелений з теми
                    size: 36,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'regular_payment_title'.tr(),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: colors.textMain, // ЗМІНЕНО
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: TextStyle(
                      fontSize: 15,
                      color:
                          colors.textSecondary, // ЗМІНЕНО: Був Colors.black54
                    ),
                    children: [
                      TextSpan(text: 'time_to_pay'.tr()),
                      TextSpan(
                        text: subscription.name,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: colors.textMain, // ЗМІНЕНО: Був Colors.black
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  '${subscription.amount} ₴',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -1,
                    color: colors.textMain, // ЗМІНЕНО
                  ),
                ),
                const SizedBox(height: 32),

                Row(
                  children: [
                    Expanded(
                      // Глобальний стиль для TextButton (сіра кнопка)
                      child: TextButton(
                        onPressed: () async {
                          await context
                              .read<FinanceProvider>()
                              .skipSubscriptionPayment(subscription);
                          if (context.mounted) {
                            Navigator.pop(context);
                          }
                        },
                        child: Text(
                          'skip'.tr(),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    Expanded(
                      // Глобальний стиль для ElevatedButton (чорна кнопка)
                      child: ElevatedButton(
                        onPressed: () async {
                          final scaffoldMessenger = ScaffoldMessenger.of(
                            context,
                          );
                          final navigator = Navigator.of(context);

                          final (success, message) = await context
                              .read<FinanceProvider>()
                              .confirmSubscriptionPayment(
                                subscription,
                                subscription.amount,
                              );

                          if (success) {
                            navigator.pop();
                          }
                          scaffoldMessenger.clearSnackBars();

                          scaffoldMessenger.showSnackBar(
                            SnackBar(
                              backgroundColor: colors.cardBg, // ЗМІНЕНО
                              behavior: SnackBarBehavior.floating,
                              margin: const EdgeInsets.only(
                                bottom: 30,
                                left: 20,
                                right: 20,
                              ),
                              elevation: 10,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: BorderSide(
                                  color: success
                                      ? colors.income.withValues(
                                          alpha: 0.5,
                                        ) // ЗМІНЕНО
                                      : colors.expense.withValues(
                                          alpha: 0.5,
                                        ), // ЗМІНЕНО
                                ),
                              ),
                              content: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: success
                                          ? colors.income.withValues(
                                              alpha: 0.1,
                                            ) // ЗМІНЕНО
                                          : colors.expense.withValues(
                                              alpha: 0.1,
                                            ), // ЗМІНЕНО
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      success
                                          ? Icons.check_circle_outline
                                          : Icons.error_outline,
                                      color: success
                                          ? colors
                                                .income // ЗМІНЕНО
                                          : colors.expense, // ЗМІНЕНО
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      message,
                                      style: TextStyle(
                                        color: colors.textMain, // ЗМІНЕНО
                                        fontWeight: FontWeight.w600,
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
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // --- Хрестик закриття ---
          Positioned(
            right: 16,
            top: 16,
            child: GestureDetector(
              onTap: () {
                context.read<FinanceProvider>().ignoreSubscriptionForSession(
                  subscription.id,
                );
                Navigator.pop(context);
              },
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colors.iconBg, // ЗМІНЕНО: Був Colors.grey...
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.close,
                  color: colors.textMain, // ЗМІНЕНО
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
