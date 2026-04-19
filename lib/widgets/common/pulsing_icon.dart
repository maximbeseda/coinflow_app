import 'package:flutter/material.dart';

class PulsingIcon extends StatefulWidget {
  final IconData icon;
  final Color color;
  final double size;

  const PulsingIcon({
    super.key,
    required this.icon,
    required this.color,
    this.size = 24.0,
  });

  @override
  State<PulsingIcon> createState() => _PulsingIconState();
}

class _PulsingIconState extends State<PulsingIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true); // Зациклюємо туди-сюди (ефект дихання)
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
        return Transform.scale(
          // Масштаб змінюється від 1.0 до 1.15
          scale: 1.0 + (_controller.value * 0.15),
          child: Opacity(
            // Прозорість змінюється від 1.0 до 0.7
            opacity: 1.0 - (_controller.value * 0.3),
            child: child,
          ),
        );
      },
      // Використовуємо child, щоб сам Icon не перемальовувався з нуля щокадру
      child: Icon(widget.icon, color: widget.color, size: widget.size),
    );
  }
}
