import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../models/subscription_model.dart';
import '../../providers/subscription_provider.dart';
import '../../providers/category_provider.dart'; // ДОДАНО: Для перевірки балансу
import '../../theme/app_colors_extension.dart';
import '../../utils/currency_formatter.dart';

class DueSubscriptionDialog extends StatelessWidget {
  final Subscription subscription;

  const DueSubscriptionDialog({super.key, required this.subscription});

  String _getFormattedDate(BuildContext context) {
    final languageCode = context.locale.languageCode;
    return DateFormat.yMMMMd(languageCode).format(subscription.nextPaymentDate);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColorsExtension>()!;

    // ДОДАНО: Отримуємо доступ до категорій, щоб перевірити баланс
    final catProv = context.watch<CategoryProvider>();
    final account = catProv.allCategoriesList
        .where((c) => c.id == subscription.accountId)
        .firstOrNull;

    // ДОДАНО: Логіка перевірки: чи можемо ми оплатити?
    final bool canPay =
        account != null &&
        !account.isArchived &&
        account.amount >= subscription.amount;

    return Dialog(
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ЗМІНЕНО: Динамічна іконка залежно від наявності грошей
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: (canPay ? colors.income : colors.expense).withValues(
                      alpha: 0.1,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    canPay
                        ? Icons.account_balance_wallet_rounded
                        : Icons.money_off_rounded,
                    color: canPay ? colors.income : colors.expense,
                    size: 36,
                  ),
                ),
                const SizedBox(height: 20),

                // Заголовок
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

                // Опис підписки
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
                const SizedBox(height: 12),

                // Візуальна плашка з ДАТОЮ ПЛАТЕЖУ
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: colors.iconBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: colors.textSecondary.withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.calendar_today_rounded,
                        size: 16,
                        color: colors.textSecondary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _getFormattedDate(context),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: colors.textMain,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // ЗМІНЕНО: Сума підсвічується червоним, якщо грошей немає
                Text(
                  '${CurrencyFormatter.format(subscription.amount)} ₴',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -1,
                    color: canPay ? colors.textMain : colors.expense,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),

                // ДОДАНО: Текст попередження про нестачу коштів
                if (!canPay) ...[
                  const SizedBox(height: 8),
                  Text(
                    account == null || account.isArchived
                        ? 'error_category_deleted'.tr()
                        : 'not_enough_funds'.tr(args: [account.name]),
                    style: TextStyle(
                      fontSize: 12,
                      color: colors.expense,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],

                const SizedBox(height: 32),

                // Кнопки Пропустити / Сплатити
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () async {
                          await context
                              .read<SubscriptionProvider>()
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
                        // ЗМІНЕНО: Фарбуємо кнопку в червоний, якщо немає грошей
                        style: canPay
                            ? null
                            : ElevatedButton.styleFrom(
                                backgroundColor: colors.expense,
                                foregroundColor: Colors.white,
                              ),
                        onPressed: () async {
                          // ДОДАНО: Логіка для кнопки "Сплатити пізніше"
                          if (!canPay) {
                            context
                                .read<SubscriptionProvider>()
                                .ignoreSubscriptionPermanently(subscription.id);
                            Navigator.pop(context);
                            return;
                          }

                          final scaffoldMessenger = ScaffoldMessenger.of(
                            context,
                          );
                          final navigator = Navigator.of(context);

                          final (success, message) = await context
                              .read<SubscriptionProvider>()
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
                              backgroundColor: colors.cardBg,
                              elevation: 4,
                              margin: const EdgeInsets.all(20),
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
                          // ЗМІНЕНО: Змінюємо текст кнопки залежно від балансу
                          canPay ? 'pay'.tr() : 'pay_later'.tr(),
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

          // Хрестик закриття (він просто ігнорує для цієї сесії)
          Positioned(
            right: 16,
            top: 16,
            child: GestureDetector(
              onTap: () {
                context
                    .read<SubscriptionProvider>()
                    .ignoreSubscriptionForSession(subscription.id);
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
