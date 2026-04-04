import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../database/app_database.dart';
import '../../providers/subscription_provider.dart';
import '../../providers/category_provider.dart';
import '../../providers/settings_provider.dart';
import '../../models/app_currency.dart';
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

    final catProv = context.watch<CategoryProvider>();
    final settings = context.watch<SettingsProvider>();

    final account = catProv.allCategoriesList
        .where((c) => c.id == subscription.accountId)
        .firstOrNull;

    bool canPay = false;
    if (account != null && !account.isArchived) {
      // Конвертуємо в базову валюту і округлюємо до цілих копійок
      int accountAmountBase = settings
          .convertToBase(account.amount, account.currency)
          .round();

      int subAmountBase = settings
          .convertToBase(subscription.amount, subscription.currency)
          .round();

      canPay = accountAmountBase >= subAmountBase;
    }

    final currencySymbol = AppCurrency.fromCode(subscription.currency).symbol;

    return Dialog(
      backgroundColor: colors.cardBg,
      surfaceTintColor: Colors.transparent,
      // Додаємо обмеження по ширині та скруглення
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Stack(
        children: [
          // 👇 Обгортаємо весь вміст у ScrollView, щоб уникнути Overflow по вертикалі
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 1. ІКОНКА
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: (canPay ? colors.income : colors.expense)
                          .withValues(alpha: 0.1),
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

                  // 2. ЗАГОЛОВОК З МОНОХРОМНОЮ ІКОНКОЮ
                  // Використовуємо Wrap, щоб текст + іконка безпечно переносились
                  Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        'regular_payment_title'.tr(),
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: colors.textMain,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.payments_outlined,
                        color: colors.textMain,
                        size: 22,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // 3. ПІДЗАГОЛОВОК
                  // Прибрав maxLines, щоб довгі назви підписок не обрізались
                  RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      style: TextStyle(
                        fontSize: 15,
                        color: colors.textSecondary,
                      ),
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

                  // 4. ДАТА (ЛЕГКА, БЕЗ РАМОК І ФОНУ)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.calendar_today_rounded,
                        size: 16,
                        color: colors.textSecondary,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          _getFormattedDate(context),
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: colors.textMain,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // 5. СУМА
                  // Обгорнув у FittedBox, щоб гігантські суми зменшували шрифт, а не падали з помилкою
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      '${CurrencyFormatter.format(subscription.amount)} $currencySymbol',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -1,
                        color: canPay ? colors.textMain : colors.expense,
                      ),
                    ),
                  ),

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
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],

                  const SizedBox(height: 32),

                  // 6. КНОПКИ
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          onPressed: () async {
                            await context
                                .read<SubscriptionProvider>()
                                .skipSubscriptionPayment(subscription);
                            if (context.mounted) {
                              Navigator.pop(context);
                            }
                          },
                          // FittedBox рятує довгі німецькі слова на кнопках
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              'skip'.tr(),
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: colors.textSecondary,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            backgroundColor: canPay
                                ? colors.textMain
                                : colors.expense,
                            foregroundColor: colors.cardBg,
                            elevation: 0,
                          ),
                          onPressed: () async {
                            if (!canPay) {
                              context
                                  .read<SubscriptionProvider>()
                                  .ignoreSubscriptionPermanently(
                                    subscription.id,
                                  );
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
                                  borderRadius: BorderRadius.circular(8),
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
                                        maxLines: 3,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                          // FittedBox тут теж
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              canPay ? 'pay'.tr() : 'pay_later'.tr(),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Хрестик закриття (залишається фіксованим зверху праворуч)
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
