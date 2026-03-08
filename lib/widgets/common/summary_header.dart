import 'package:flutter/material.dart';
import '../../utils/currency_formatter.dart';
import 'rolling_digit.dart';
import '../../theme/app_colors_extension.dart';

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

            GestureDetector(
              onTap: onSettingsTap,
              behavior: HitTestBehavior.opaque,
              child: SizedBox(
                width: 24,
                child: Icon(
                  Icons.settings_outlined,
                  size: 20,
                  color: colors.textSecondary,
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
          mainAxisAlignment: MainAxisAlignment.start, // СТРОГО ПО ЛІВОМУ КРАЮ
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
