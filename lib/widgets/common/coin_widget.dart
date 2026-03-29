import 'package:flutter/material.dart';
import '../../utils/currency_formatter.dart';
import '../../models/category_model.dart';
import '../../models/app_currency.dart'; // ДОДАНО: Для отримання символу валюти
import '../../theme/app_colors_extension.dart';

class CoinWidget extends StatelessWidget {
  final Category category;
  final bool isFeedback;
  final bool isHovered;
  final Widget Function(Widget normalCoin, Widget placeholderCoin)? coinWrapper;

  const CoinWidget({
    super.key,
    required this.category,
    this.isFeedback = false,
    this.isHovered = false,
    this.coinWrapper,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColorsExtension>()!;

    String displayAmount = CurrencyFormatter.format(category.amount);

    // ДОДАНО: Отримуємо символ валюти для цієї конкретної категорії
    String currencySymbol = AppCurrency.fromCode(category.currency).symbol;

    bool isIncome = category.type == CategoryType.income;
    bool isExpense = category.type == CategoryType.expense;

    double progress = 0.0;
    Color ringColor = Colors.blueAccent;
    bool hasBudget = category.budget != null && category.budget! > 0;

    if (hasBudget) {
      // 👇 Приводимо до double для правильного розрахунку відсотка
      double amountAbs = category.amount.abs().toDouble();
      progress = (amountAbs / category.budget!.toDouble()).clamp(0.0, 1.0);

      if (isIncome) {
        ringColor = progress >= 1.0 ? colors.income : Colors.blueAccent;
      } else if (isExpense) {
        DateTime now = DateTime.now();
        int daysInMonth = DateTime(now.year, now.month + 1, 0).day;
        int currentDay = now.day;

        // 👇 Тут також використовуємо toDouble() для бюджету
        double expectedPace =
            (category.budget!.toDouble() / daysInMonth) * currentDay;

        if (amountAbs >= category.budget!.toDouble()) {
          ringColor = colors.expense;
        } else if (amountAbs > expectedPace) {
          ringColor = Colors.orange;
        } else {
          ringColor = Colors.blueAccent;
        }
      }
    }

    Color shadowColor = colors.textMain.withValues(alpha: 0.1);

    Widget basicCoin = Container(
      width: 55,
      height: 55,
      decoration: BoxDecoration(
        color: category.bgColor,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            blurRadius: 8,
            spreadRadius: 1,
            offset: const Offset(0, 0),
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
      decoration: BoxDecoration(color: colors.iconBg, shape: BoxShape.circle),
      child: Icon(
        category.icon,
        color: colors.textSecondary.withValues(alpha: 0.3),
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
                backgroundColor: colors.textMain.withValues(alpha: 0.1),
                valueColor: AlwaysStoppedAnimation<Color>(ringColor),
              ),
            ),
          interactiveCoin,
        ],
      ),
    );

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
              color: colors.textSecondary,
            ),
          ),
        ),
        const SizedBox(height: 2),
        scaledCoin,
        const SizedBox(height: 2),
        SizedBox(
          width: 75,
          height: 16,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.center,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (Widget child, Animation<double> animation) {
                return FadeTransition(
                  opacity: animation,
                  child: ScaleTransition(scale: animation, child: child),
                );
              },
              child: Text(
                "$displayAmount $currencySymbol", // ЗМІНЕНО: Динамічна валюта замість ₴
                key: ValueKey<String>("$displayAmount $currencySymbol"),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: colors.textMain,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
