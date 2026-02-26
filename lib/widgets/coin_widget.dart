import 'package:coin_flow/utils/currency_formatter.dart';
import 'package:flutter/material.dart';
import '../models/category_model.dart';

class CoinWidget extends StatelessWidget {
  final Category category;
  final bool isFeedback;
  final bool isHovered; // ДОДАНО: стан наведення для збільшення
  final Widget Function(Widget normalCoin, Widget placeholderCoin)? coinWrapper;

  const CoinWidget({
    super.key,
    required this.category,
    this.isFeedback = false,
    this.isHovered = false, // За замовчуванням false
    this.coinWrapper,
  });

  @override
  Widget build(BuildContext context) {
    String displayAmount = CurrencyFormatter.format(category.amount);

    bool isIncome = category.type == CategoryType.income;
    bool isExpense = category.type == CategoryType.expense;

    double progress = 0.0;
    Color ringColor = Colors.blueAccent;
    bool hasBudget = category.budget != null && category.budget! > 0;

    if (hasBudget) {
      double amountAbs = category.amount.abs();
      progress = (amountAbs / category.budget!).clamp(0.0, 1.0);

      if (isIncome) {
        ringColor = progress >= 1.0 ? Colors.green : Colors.blueAccent;
      } else if (isExpense) {
        DateTime now = DateTime.now();
        int daysInMonth = DateTime(now.year, now.month + 1, 0).day;
        int currentDay = now.day;

        double expectedPace = (category.budget! / daysInMonth) * currentDay;

        if (amountAbs >= category.budget!) {
          ringColor = Colors.redAccent;
        } else if (amountAbs > expectedPace) {
          ringColor = Colors.orange;
        } else {
          ringColor = Colors.blueAccent;
        }
      }
    }

    Widget basicCoin = Container(
      width: 55,
      height: 55,
      decoration: BoxDecoration(
        color: category.bgColor,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(category.icon, color: category.iconColor, size: 24),
          if (hasBudget)
            Positioned(
              bottom: 6,
              child: Text(
                CurrencyFormatter.formatBudget(category.budget!),
                style: TextStyle(
                  fontSize: 8,
                  color: category.iconColor.withValues(alpha: 0.7),
                ),
              ),
            ),
        ],
      ),
    );

    Widget placeholderCoin = Container(
      width: 55,
      height: 55,
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.15),
        shape: BoxShape.circle,
      ),
      child: Icon(
        category.icon,
        color: Colors.grey.withValues(alpha: 0.3),
        size: 24,
      ),
    );

    if (isFeedback) {
      return basicCoin;
    }

    Widget interactiveCoin = coinWrapper != null
        ? coinWrapper!(basicCoin, placeholderCoin)
        : basicCoin;

    Widget coinWithBudget = SizedBox(
      width: 62,
      height: 62,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (hasBudget)
            SizedBox(
              width: 62,
              height: 62,
              child: CircularProgressIndicator(
                value: progress,
                strokeWidth: 3,
                backgroundColor: Colors.black.withValues(alpha: 0.05),
                valueColor: AlwaysStoppedAnimation<Color>(ringColor),
              ),
            ),
          interactiveCoin,
        ],
      ),
    );

    // ГОЛОВНА ЗМІНА: Анімація збільшення застосовується ТІЛЬКИ до монетки з бюджетом
    Widget scaledCoin = AnimatedScale(
      scale: isHovered ? 1.15 : 1.0,
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOutBack,
      child: coinWithBudget,
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 70,
          height: 14,
          child: Text(
            category.name,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Colors.black.withValues(alpha: 0.6),
            ),
          ),
        ),
        const SizedBox(height: 2),
        scaledCoin, // Вставляємо анімовану монетку
        const SizedBox(height: 2),
        SizedBox(
          width: 75,
          height: 16,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (Widget child, Animation<double> animation) {
              return FadeTransition(
                opacity: animation,
                child: ScaleTransition(scale: animation, child: child),
              );
            },
            child: Text(
              "$displayAmount₴",
              key: ValueKey<String>(displayAmount),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
