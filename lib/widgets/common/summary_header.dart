import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // ДОДАНО: Для доступу до провайдерів
import '../../utils/currency_formatter.dart';
import 'rolling_digit.dart';
import '../../theme/app_colors_extension.dart';
import '../../providers/subscription_provider.dart'; // ДОДАНО: Для перевірки підписок

class SummaryHeader extends StatelessWidget {
  final double totalBalance;
  final double totalIncomes;
  final double totalExpenses;
  final VoidCallback onBalanceTap;
  final VoidCallback onIncomesTap;
  final VoidCallback onExpensesTap;
  final VoidCallback onSettingsTap;

  const SummaryHeader({
    super.key,
    required this.totalBalance,
    required this.totalIncomes,
    required this.totalExpenses,
    required this.onBalanceTap,
    required this.onIncomesTap,
    required this.onExpensesTap,
    required this.onSettingsTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColorsExtension>()!;

    // ДОДАНО: Перевіряємо, чи є відкладені/прострочені платежі
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
            ),
            _item(
              Icons.north_east,
              totalIncomes,
              colors.income,
              onIncomesTap,
              colors,
            ),
            _item(
              Icons.south_east,
              totalExpenses,
              colors.expense,
              onExpensesTap,
              colors,
            ),

            // ЗМІНЕНО: Кнопка налаштувань тепер зі Stack для відображення індикатора
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
                    // ДОДАНО: Червона крапка (badge), якщо є борги
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
                      " ₴",
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: color.withValues(alpha: 0.6),
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
