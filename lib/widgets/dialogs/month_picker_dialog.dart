import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../theme/app_colors_extension.dart';

class MonthPickerDialog extends StatefulWidget {
  final DateTime initialDate;
  const MonthPickerDialog({super.key, required this.initialDate});

  @override
  State<MonthPickerDialog> createState() => _MonthPickerDialogState();
}

class _MonthPickerDialogState extends State<MonthPickerDialog> {
  late int _selectedYear;

  String _getShortMonthName(int month, BuildContext context) {
    String m = DateFormat.MMM(
      context.locale.languageCode,
    ).format(DateTime(2000, month));
    return m[0].toUpperCase() + m.substring(1);
  }

  @override
  void initState() {
    super.initState();
    _selectedYear = widget.initialDate.year;
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColorsExtension>()!;

    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Перемикач років
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: Icon(Icons.chevron_left, color: colors.textMain),
                  onPressed: () => setState(() => _selectedYear--),
                ),
                Text(
                  _selectedYear.toString(),
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: colors.textMain,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.chevron_right, color: colors.textMain),
                  onPressed: () => setState(() => _selectedYear++),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Сітка місяців
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 2,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: 12,
              itemBuilder: (context, index) {
                bool isSelected =
                    widget.initialDate.year == _selectedYear &&
                    widget.initialDate.month == index + 1;

                return GestureDetector(
                  onTap: () {
                    Navigator.pop(
                      context,
                      DateTime(_selectedYear, index + 1, 1),
                    );
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected ? colors.textMain : colors.iconBg,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      _getShortMonthName(index + 1, context),
                      style: TextStyle(
                        color: isSelected
                            ? Theme.of(context).scaffoldBackgroundColor
                            : colors.textMain,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () {
                  final now = DateTime.now();
                  Navigator.pop(context, DateTime(now.year, now.month, 1));
                },
                child: Text(
                  'current_month'.tr(),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  // ВИПРАВЛЕНО: Текст обрізається, якщо не влазить
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
