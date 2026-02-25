import 'package:flutter/material.dart';
import '../utils/currency_formatter.dart';
import 'rolling_digit.dart';

class SummaryHeader extends StatelessWidget {
  final double totalBalance;
  final double totalExpenses;
  final VoidCallback onBalanceTap;
  final VoidCallback onExpensesTap;

  const SummaryHeader({
    super.key,
    required this.totalBalance,
    required this.totalExpenses,
    required this.onBalanceTap,
    required this.onExpensesTap,
  });

  @override
  Widget build(BuildContext context) {
    // 1. ДОДАНО: Обгортка MediaQuery
    return MediaQuery(
      // 2. ДОДАНО: Жорстко вимикаємо масштабування тексту для цього блоку
      data: MediaQuery.of(context).copyWith(textScaler: TextScaler.noScaling),
      // 3. ТВІЙ ОРИГІНАЛЬНИЙ КОД ПОЧИНАЄТЬСЯ ТУТ (я просто посунув його вправо)
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
              onTap: () {
                // Відкрити налаштування
                debugPrint("Settings tapped!");
              },
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
          // ЗМІНЕНО: Вирівнюємо текст і суму чітко по центру вертикалі!
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Щоб текст "не стрибав", якщо у шрифта є специфічні відступи,
            // ми обгортаємо його в Padding і трошки "підтягуємо" візуально, якщо потрібно.
            // Але зазвичай CrossAxisAlignment.center робить усе ідеально.
            Padding(
              padding: const EdgeInsets.only(
                bottom: 1,
              ), // Мікро-корекція по висоті
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
                  // Цифри і значок "₴" залишаються вирівняними по нижній базовій лінії
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
