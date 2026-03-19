import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_colors_extension.dart';

class AppTextField extends StatelessWidget {
  final String label;
  final String? suffixText;
  final TextEditingController controller;
  final TextInputType keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String>? onChanged;
  final String? errorText;
  final bool autofocus;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final bool isLarge; // Для поля "Сума" робимо більший шрифт

  const AppTextField({
    super.key,
    required this.label,
    required this.controller,
    this.suffixText,
    this.keyboardType = TextInputType.text,
    this.inputFormatters,
    this.onChanged,
    this.errorText,
    this.autofocus = false,
    this.prefixIcon,
    this.suffixIcon,
    this.isLarge = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColorsExtension>()!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label.isNotEmpty) ...[
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: errorText != null ? colors.expense : colors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
        ],
        Container(
          decoration: BoxDecoration(
            color: colors.iconBg.withValues(
              alpha: 0.5,
            ), // Легкий фон замість рамок
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: errorText != null
                  ? colors.expense.withValues(alpha: 0.5)
                  : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            inputFormatters: inputFormatters,
            onChanged: onChanged,
            autofocus: autofocus,
            maxLines: 1,
            textAlignVertical: TextAlignVertical.center,
            style: TextStyle(
              fontSize: isLarge ? 28 : 16, // Величезні цифри для суми
              fontWeight: isLarge ? FontWeight.w800 : FontWeight.w600,
              color: colors.textMain,
            ),
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 20,
                vertical: isLarge ? 16 : 14,
              ),
              prefixIcon: prefixIcon,
              suffixIcon: suffixIcon,
              suffixText: suffixText,
              suffixStyle: TextStyle(
                fontSize: isLarge ? 20 : 16,
                fontWeight: FontWeight.bold,
                color: colors.textSecondary,
              ),
            ),
          ),
        ),
        if (errorText != null) ...[
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 12),
            child: Text(
              errorText!,
              style: TextStyle(fontSize: 12, color: colors.expense),
            ),
          ),
        ],
      ],
    );
  }
}
