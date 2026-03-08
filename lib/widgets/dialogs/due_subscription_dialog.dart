import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../models/subscription_model.dart';
import '../../providers/finance_provider.dart';
import '../../theme/app_colors_extension.dart';

class DueSubscriptionDialog extends StatelessWidget {
  final Subscription subscription;

  const DueSubscriptionDialog({super.key, required this.subscription});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColorsExtension>()!;

    return Dialog(
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Верхня іконка гаманця
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colors.income.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.account_balance_wallet_rounded,
                    color: colors.income,
                    size: 36,
                  ),
                ),
                const SizedBox(height: 20),

                // ЗАХИСТ: Заголовок
                Text(
                  'regular_payment_title'.tr(),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: colors.textMain,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),

                // ЗАХИСТ: Опис підписки
                RichText(
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  text: TextSpan(
                    style: TextStyle(fontSize: 15, color: colors.textSecondary),
                    children: [
                      TextSpan(text: 'time_to_pay'.tr()),
                      TextSpan(
                        text: subscription.name,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: colors.textMain,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // ЗАХИСТ: Велика сума
                Text(
                  '${subscription.amount} ₴',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -1,
                    color: colors.textMain,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 32),

                Row(
                  children: [
                    Expanded(
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
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
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
                              behavior: SnackBarBehavior.floating,
                              backgroundColor: colors.cardBg, // Світлий фон
                              elevation: 4,
                              margin: const EdgeInsets.all(20),
                              // ВИПРАВЛЕНО: Тонка рамка (червона або зелена)
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(
                                  color: success
                                      ? colors.income
                                      : colors.expense,
                                  width: 1.0,
                                ),
                              ),
                              content: Row(
                                children: [
                                  Icon(
                                    success
                                        ? Icons.check_circle_outline
                                        : Icons.error_outline,
                                    color: success
                                        ? colors.income
                                        : colors.expense,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      message,
                                      style: TextStyle(
                                        color: colors.textMain,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
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
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Хрестик закриття
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
                  color: colors.iconBg,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.close, color: colors.textMain, size: 20),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
