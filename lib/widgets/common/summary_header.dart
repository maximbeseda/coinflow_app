import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../utils/currency_formatter.dart';
import 'rolling_digit.dart';
import '../../theme/app_colors_extension.dart';
import '../../providers/subscription_provider.dart';
import '../../providers/settings_provider.dart'; // ДОДАНО: Для доступу до базової валюти
import '../../models/app_currency.dart'; // ДОДАНО: Для отримання символу валюти
import 'animated_dots.dart';

class SummaryHeader extends StatelessWidget {
  final double totalBalance;
  final double totalIncomes;
  final double totalExpenses;
  final VoidCallback onBalanceTap;
  final VoidCallback onIncomesTap;
  final VoidCallback onExpensesTap;
  final VoidCallback onSettingsTap;
  final bool isMigrating;

  const SummaryHeader({
    super.key,
    required this.totalBalance,
    required this.totalIncomes,
    required this.totalExpenses,
    required this.onBalanceTap,
    required this.onIncomesTap,
    required this.onExpensesTap,
    required this.onSettingsTap,
    this.isMigrating = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColorsExtension>()!;

    // Отримуємо поточний символ базової валюти
    final settings = context.watch<SettingsProvider>();
    final baseCurrencySymbol = AppCurrency.fromCode(
      settings.baseCurrency,
    ).symbol;

    final hasPendingSubscriptions = context
        .watch<SubscriptionProvider>()
        .hasPendingPayments;

    return MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: TextScaler.noScaling),
      child: Padding(
        padding: const EdgeInsets.only(left: 15, right: 10, top: 15, bottom: 0),
        child: Row(
          children: [
            _item(
              Icons.account_balance_wallet_outlined,
              totalBalance,
              colors.textMain,
              onBalanceTap,
              colors,
              baseCurrencySymbol,
            ),
            _item(
              Icons.north_east,
              totalIncomes,
              colors.income,
              onIncomesTap,
              colors,
              baseCurrencySymbol,
            ),
            _item(
              Icons.south_east,
              totalExpenses,
              colors.expense,
              onExpensesTap,
              colors,
              baseCurrencySymbol,
            ),

            GestureDetector(
              onTap: onSettingsTap,
              behavior: HitTestBehavior.opaque,
              child: Container(
                width: 24,
                alignment: Alignment.center,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Icon(
                      Icons.settings_outlined,
                      size: 20,
                      color: colors.textSecondary,
                    ),
                    if (hasPendingSubscriptions)
                      Positioned(
                        top: -2,
                        right: -2,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: colors.expense,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: colors.expense.withValues(alpha: 0.4),
                                blurRadius: 3,
                                spreadRadius: 0.5,
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _item(
    IconData icon,
    double amount,
    Color color,
    VoidCallback onTap,
    AppColorsExtension colors,
    String currencySymbol,
  ) {
    String formattedAmount = CurrencyFormatter.format(amount, isHeader: true);

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Icon(icon, size: 14, color: colors.textSecondary),
            const SizedBox(width: 4),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                // 👇 МАГІЯ ТУТ: Використовуємо Stack для накладання
                child: Stack(
                  alignment: Alignment.centerLeft,
                  children: [
                    // 1. КАРКАС: Прозорі цифри, які тримають ширину під час міграції
                    Opacity(
                      opacity: isMigrating ? 0.0 : 1.0,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          for (int i = 0; i < formattedAmount.length; i++)
                            RollingDigit(
                              char: formattedAmount[i],
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: color,
                              ),
                            ),
                          Text(
                            " $currencySymbol",
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: color.withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // 2. КРАПКИ: З'являються рівно поверх зарезервованого місця
                    if (isMigrating)
                      Positioned.fill(
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: AnimatedDots(
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: color,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
