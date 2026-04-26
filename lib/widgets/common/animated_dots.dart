import 'package:flutter/material.dart';

class AnimatedDots extends StatefulWidget {
  final TextStyle style;

  const AnimatedDots({super.key, required this.style});

  @override
  State<AnimatedDots> createState() => _AnimatedDotsState();
}

class _AnimatedDotsState extends State<AnimatedDots>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    // Крапки будуть оновлюватися кожні 800 мілісекунд
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        // Рахуємо від 0 до 3 крапок
        final int dotsCount = (_controller.value * 4).floor() % 4;
        final String text = List.generate(dotsCount, (index) => '.').join();

        return SizedBox(
          width: 24, // Жорстка ширина, щоб текст поруч не "смикався"
          child: Text(text, style: widget.style, textAlign: TextAlign.left),
        );
      },
    );
  }
}
