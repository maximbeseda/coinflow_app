import 'package:flutter/material.dart';

class RollingDigit extends StatelessWidget {
  final String char;
  final TextStyle style;

  const RollingDigit({super.key, required this.char, required this.style});

  @override
  Widget build(BuildContext context) {
    final int? digit = int.tryParse(char);

    // Якщо це не цифра (пробіл, кома, літера) — просто показуємо її
    if (digit == null) {
      return AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: Text(char, key: ValueKey(char), style: style),
      );
    }

    // Якщо це цифра — малюємо барабан ігрового автомата
    return _DigitSlotMachine(digit: digit, style: style);
  }
}

class _DigitSlotMachine extends StatelessWidget {
  final int digit;
  final TextStyle style;

  const _DigitSlotMachine({required this.digit, required this.style});

  @override
  Widget build(BuildContext context) {
    final textPainter = TextPainter(
      text: TextSpan(text: '0', style: style),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout();

    final height = textPainter.size.height;
    final width = textPainter.size.width;

    // МАГІЯ 1: Вираховуємо точну лінію, на якій "стоять" букви у цьому шрифті
    final baselineOffset = textPainter.computeDistanceToActualBaseline(
      TextBaseline.alphabetic,
    );

    // МАГІЯ 2: Обгортаємо наш барабан у віджет Baseline
    return Baseline(
      baseline: baselineOffset,
      baselineType: TextBaseline.alphabetic,
      child: SizedBox(
        width: width,
        height: height,
        child: ClipRect(
          child: OverflowBox(
            maxHeight: double.infinity,
            alignment: Alignment.topCenter,
            child: AnimatedSlide(
              offset: Offset(0, -digit / 10),
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOutCubic,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(
                  10,
                  (index) => SizedBox(
                    height: height,
                    child: Center(
                      child: Text(
                        index.toString(),
                        style: style,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
