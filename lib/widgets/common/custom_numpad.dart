import 'package:flutter/material.dart';
import 'package:vibration/vibration.dart';
import '../../theme/app_colors_extension.dart';
import '../../theme/category_defaults.dart';

class CustomNumpad extends StatelessWidget {
  final Function(String) onKeyPressed;

  const CustomNumpad({super.key, required this.onKeyPressed});

  void _handleKeyPress(String key) async {
    bool? hasVibrator = await Vibration.hasVibrator();
    if (hasVibrator == true) {
      Vibration.vibrate(duration: 15, amplitude: 30);
    }
    onKeyPressed(key);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColorsExtension>()!;

    // ЗМІНЕНО: Поміняли місцями '00' та '0' в останньому рядку
    final keys = [
      ['C', '⌫', '%', '÷'],
      ['1', '2', '3', '×'],
      ['4', '5', '6', '-'],
      ['7', '8', '9', '+'],
      ['00', '0', '.', '='],
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      color: Colors.transparent,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: keys.map((row) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: row.map((key) {
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: _buildButton(key, colors, context),
                  ),
                );
              }).toList(),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildButton(
    String text,
    AppColorsExtension colors,
    BuildContext context,
  ) {
    bool isOperator = ['÷', '×', '-', '+'].contains(text);
    bool isAction = ['C', '⌫', '%'].contains(text);
    bool isEqual = text == '=';

    Color textColor;
    Color bgColor;

    bool isDark = Theme.of(context).brightness == Brightness.dark;

    if (isEqual) {
      bgColor = CategoryDefaults.accountBg;
      textColor = Colors.white;
    } else if (isOperator) {
      bgColor = CategoryDefaults.accountBg.withValues(alpha: 0.15);
      textColor = isDark ? Colors.white : CategoryDefaults.accountBg;
    } else if (isAction) {
      bgColor = colors.iconBg;
      textColor = colors.textSecondary;
    } else {
      bgColor = colors.cardBg;
      textColor = colors.textMain;
    }

    return Material(
      color: bgColor,
      elevation: isDark ? 1 : 2,
      shadowColor: isDark
          ? Colors.white.withValues(alpha: 0.2)
          : Colors.black.withValues(alpha: 0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: (!isOperator && !isAction && !isEqual)
            ? BorderSide(
                color: colors.textSecondary.withValues(alpha: 0.1),
                width: 1,
              )
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: () => _handleKeyPress(text),
        borderRadius: BorderRadius.circular(8),
        splashColor: CategoryDefaults.accountBg.withValues(alpha: 0.2),
        highlightColor: CategoryDefaults.accountBg.withValues(alpha: 0.1),
        child: Container(
          height: 52,
          alignment: Alignment.center,
          child: text == '⌫'
              ? Icon(Icons.backspace_outlined, color: textColor, size: 20)
              : Text(
                  text,
                  style: TextStyle(
                    fontSize: isOperator || isEqual ? 24 : 20,
                    fontWeight: isOperator || isEqual
                        ? FontWeight.w600
                        : FontWeight.w500,
                    color: textColor,
                  ),
                ),
        ),
      ),
    );
  }
}
