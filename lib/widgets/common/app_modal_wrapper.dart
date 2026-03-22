import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../theme/app_colors_extension.dart';

class AppModalWrapper extends StatelessWidget {
  final String title;
  final Widget child;
  final Widget? bottomButton;
  final VoidCallback? onClose;

  const AppModalWrapper({
    super.key,
    required this.title,
    required this.child,
    this.bottomButton,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColorsExtension>()!;

    return Container(
      height: MediaQuery.of(context).size.height,
      decoration: BoxDecoration(
        color: colors.cardBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // --- ШАПКА ВІКНА ---
          Padding(
            // ВИПРАВЛЕНО: Жорсткий відступ зверху, щоб точно опустити під статус-бар
            padding: EdgeInsets.only(
              left: 24,
              right: 16,
              top: math.max(MediaQuery.of(context).padding.top, 32.0),
              bottom: 8,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: colors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close_rounded, color: colors.textSecondary),
                  onPressed: onClose ?? () => Navigator.pop(context),
                  style: IconButton.styleFrom(
                    backgroundColor: colors.iconBg,
                    padding: const EdgeInsets.all(8),
                  ),
                ),
              ],
            ),
          ),

          // --- РОЗУМНИЙ КОНТЕНТ ---
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: IntrinsicHeight(child: child),
                  ),
                );
              },
            ),
          ),

          // --- КНОПКА ЗНИЗУ ---
          if (bottomButton != null)
            Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom > 0
                    ? MediaQuery.of(context).viewInsets.bottom + 16
                    : 16,
              ),
              child: bottomButton,
            ),
        ],
      ),
    );
  }
}
