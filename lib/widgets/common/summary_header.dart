import 'package:flutter/material.dart';
import '../../utils/currency_formatter.dart';
import 'rolling_digit.dart';

class SummaryHeader extends StatelessWidget {
  final double totalBalance;
  final double totalExpenses;
  final VoidCallback onBalanceTap;
  final VoidCallback onExpensesTap;
  final VoidCallback onSettingsTap; // ДОДАНО: Колбек для налаштувань

  const SummaryHeader({
    super.key,
    required this.totalBalance,
    required this.totalExpenses,
    required this.onBalanceTap,
    required this.onExpensesTap,
    required this.onSettingsTap, // ДОДАНО
  });

  @override
  Widget build(BuildContext context) {
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: TextScaler.noScaling),
      child: Padding(
        padding: const EdgeInsets.only(left: 15, right: 10, top: 15, bottom: 0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _item(
              "БАЛАНС  ",
              totalBalance,
              const Color(0xFF2D3748),
              onBalanceTap,
            ),
            _item(
              "ВИТРАТИ  ",
              totalExpenses,
              const Color(0xFFE05252),
              onExpensesTap,
            ),

            GestureDetector(
              onTap: onSettingsTap, // ЗМІНЕНО: Викликаємо передану функцію
              behavior: HitTestBehavior.opaque,
              child: const SizedBox(
                height: 16,
                width: 24,
                child: OverflowBox(
                  maxHeight: 30,
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.settings_outlined,
                    size: 20,
                    color: Colors.black38,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _item(String label, double amount, Color color, VoidCallback onTap) {
    String formattedAmount = CurrencyFormatter.format(amount, isHeader: true);

    TextStyle amountStyle = TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w900,
      letterSpacing: -0.2,
      color: color,
    );

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 1),
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  color: Colors.black45,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
            ),
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
                        style: amountStyle,
                      ),
                    Text(
                      " ₴",
                      style: amountStyle.copyWith(
                        fontSize: 11,
                        letterSpacing: 0,
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
