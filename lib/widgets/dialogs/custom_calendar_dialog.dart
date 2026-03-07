import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../theme/app_colors_extension.dart'; // ДОДАНО: Імпорт теми

// Створюємо стани для нашого календаря
enum CalendarMode { date, month, year }

class CustomCalendarDialog extends StatefulWidget {
  final DateTime initialDate;

  const CustomCalendarDialog({super.key, required this.initialDate});

  @override
  State<CustomCalendarDialog> createState() => _CustomCalendarDialogState();
}

class _CustomCalendarDialogState extends State<CustomCalendarDialog> {
  late DateTime _selectedDay;
  late DateTime _focusedDay;
  CalendarMode _mode = CalendarMode.date;

  String _getMonthName(int month, BuildContext context) {
    // Формат LLLL дає назву місяця в називному відмінку (Січень, Лютий і т.д.)
    String m = DateFormat.LLLL(
      context.locale.languageCode,
    ).format(DateTime(2000, month));
    return m[0].toUpperCase() + m.substring(1); // Робимо першу літеру великою
  }

  final int _startYear = 2000;
  final int _endYear = DateTime.now().year + 100;

  @override
  void initState() {
    super.initState();
    _selectedDay = widget.initialDate;
    _focusedDay = widget.initialDate;
  }

  @override
  Widget build(BuildContext context) {
    // ДОДАНО: Отримуємо кольори теми
    final colors = Theme.of(context).extension<AppColorsExtension>()!;
    // ДОДАНО: Колір для інвертованого тексту (текст на активному тлі)
    final invertedTextColor = Theme.of(context).scaffoldBackgroundColor;

    // Стиль Dialog береться з AppTheme
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Padding(
        padding: const EdgeInsets.all(
          16.0,
        ), // Трішки зменшили відступи для економії місця
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'select_date'.tr(),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: colors.textMain, // ЗМІНЕНО
                ),
              ),
              const SizedBox(height: 16),

              // --- ШАПКА ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Кнопка Вліво
                  Opacity(
                    opacity: _mode == CalendarMode.date ? 1.0 : 0.0,
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 40,
                        minHeight: 40,
                      ),
                      icon: Icon(
                        Icons.chevron_left,
                        color: colors.textMain,
                      ), // ЗМІНЕНО
                      onPressed: _mode == CalendarMode.date
                          ? () => setState(
                              () => _focusedDay = DateTime(
                                _focusedDay.year,
                                _focusedDay.month - 1,
                                1,
                              ),
                            )
                          : null,
                    ),
                  ),

                  // Кнопки вибору Місяця та Року
                  Expanded(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _mode = _mode == CalendarMode.month
                                    ? CalendarMode.date
                                    : CalendarMode.month;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: _mode == CalendarMode.month
                                    ? colors
                                          .textMain // ЗМІНЕНО
                                    : colors.iconBg, // ЗМІНЕНО
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Text(
                                    _getMonthName(_focusedDay.month, context),
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: _mode == CalendarMode.month
                                          ? invertedTextColor // ЗМІНЕНО
                                          : colors.textMain, // ЗМІНЕНО
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(
                                    _mode == CalendarMode.month
                                        ? Icons.keyboard_arrow_up
                                        : Icons.keyboard_arrow_down,
                                    size: 16,
                                    color: _mode == CalendarMode.month
                                        ? invertedTextColor // ЗМІНЕНО
                                        : colors.textSecondary, // ЗМІНЕНО
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),

                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _mode = _mode == CalendarMode.year
                                    ? CalendarMode.date
                                    : CalendarMode.year;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: _mode == CalendarMode.year
                                    ? colors
                                          .textMain // ЗМІНЕНО
                                    : colors.iconBg, // ЗМІНЕНО
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Text(
                                    _focusedDay.year.toString(),
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: _mode == CalendarMode.year
                                          ? invertedTextColor // ЗМІНЕНО
                                          : colors.textMain, // ЗМІНЕНО
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(
                                    _mode == CalendarMode.year
                                        ? Icons.keyboard_arrow_up
                                        : Icons.keyboard_arrow_down,
                                    size: 16,
                                    color: _mode == CalendarMode.year
                                        ? invertedTextColor // ЗМІНЕНО
                                        : colors.textSecondary, // ЗМІНЕНО
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Кнопка Вправо
                  Opacity(
                    opacity: _mode == CalendarMode.date ? 1.0 : 0.0,
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 40,
                        minHeight: 40,
                      ),
                      icon: Icon(
                        Icons.chevron_right,
                        color: colors.textMain,
                      ), // ЗМІНЕНО
                      onPressed: _mode == CalendarMode.date
                          ? () => setState(
                              () => _focusedDay = DateTime(
                                _focusedDay.year,
                                _focusedDay.month + 1,
                                1,
                              ),
                            )
                          : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // --- КІНЕЦЬ ШАПКИ ---

              // --- АНІМОВАНИЙ БЛОК КОНТЕНТУ ---
              AnimatedSize(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                alignment: Alignment.topCenter,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder:
                      (Widget child, Animation<double> animation) {
                        return FadeTransition(
                          opacity: animation,
                          child: ScaleTransition(
                            scale: animation,
                            child: child,
                          ),
                        );
                      },
                  child: _buildContent(
                    colors,
                    invertedTextColor,
                  ), // Передаємо кольори
                ),
              ),

              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    // Стиль TextButton береться з AppTheme
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          'cancel'.tr(),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    // Стиль ElevatedButton береться з AppTheme
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, _selectedDay),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          'ok'.tr(),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(AppColorsExtension colors, Color invertedTextColor) {
    switch (_mode) {
      case CalendarMode.month:
        return _buildMonthGrid(colors, invertedTextColor);
      case CalendarMode.year:
        return _buildYearGrid(colors, invertedTextColor);
      case CalendarMode.date:
        return _buildCalendar(colors, invertedTextColor);
    }
  }

  // 1. Стандартний календар
  Widget _buildCalendar(AppColorsExtension colors, Color invertedTextColor) {
    return TableCalendar(
      key: const ValueKey('calendar'),
      locale: context.locale.languageCode,
      firstDay: DateTime.utc(_startYear, 1, 1),
      lastDay: DateTime.utc(_endYear, 12, 31),
      focusedDay: _focusedDay,
      rowHeight: 46,
      selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
      startingDayOfWeek: StartingDayOfWeek.monday,
      headerVisible: false,
      daysOfWeekStyle: DaysOfWeekStyle(
        weekdayStyle: TextStyle(color: colors.textSecondary),
        weekendStyle: TextStyle(
          color: colors.expense,
        ), // Вихідні кольором витрат
      ),
      calendarStyle: CalendarStyle(
        outsideDaysVisible: true,
        outsideTextStyle: TextStyle(
          color: colors.textSecondary.withValues(alpha: 0.5),
        ), // ЗМІНЕНО
        defaultTextStyle: TextStyle(
          color: colors.textMain, // ЗМІНЕНО
          fontWeight: FontWeight.w500,
        ),
        weekendTextStyle: TextStyle(
          color: colors.expense, // ЗМІНЕНО: червоний з теми
          fontWeight: FontWeight.w500,
        ),
        cellMargin: const EdgeInsets.all(2.0),
        selectedDecoration: BoxDecoration(
          color: colors.textMain, // ЗМІНЕНО
          shape: BoxShape.circle,
        ),
        selectedTextStyle: TextStyle(
          color: invertedTextColor, // ЗМІНЕНО: інвертований текст для вибраного
          fontWeight: FontWeight.bold,
        ),
        todayDecoration: BoxDecoration(
          color: colors.iconBg, // ЗМІНЕНО
          shape: BoxShape.circle,
        ),
        todayTextStyle: TextStyle(
          color: colors.textMain, // ЗМІНЕНО
          fontWeight: FontWeight.bold,
        ),
      ),
      onDaySelected: (selectedDay, focusedDay) {
        setState(() {
          _selectedDay = selectedDay;
          _focusedDay = focusedDay;
        });
      },
      onPageChanged: (focusedDay) {
        setState(() {
          _focusedDay = focusedDay;
        });
      },
    );
  }

  // 2. Сітка вибору місяця
  Widget _buildMonthGrid(AppColorsExtension colors, Color invertedTextColor) {
    return GridView.builder(
      key: const ValueKey('months'),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 1.8,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
      ),
      itemCount: 12,
      itemBuilder: (context, index) {
        bool isSelected = _focusedDay.month == index + 1;
        return GestureDetector(
          onTap: () {
            setState(() {
              _focusedDay = DateTime(_focusedDay.year, index + 1, 1);
              _mode = CalendarMode.date;
            });
          },
          child: Container(
            decoration: BoxDecoration(
              color: isSelected ? colors.textMain : colors.iconBg, // ЗМІНЕНО
              borderRadius: BorderRadius.circular(16),
            ),
            alignment: Alignment.center,
            child: Text(
              _getMonthName(index + 1, context),
              style: TextStyle(
                color: isSelected
                    ? invertedTextColor
                    : colors.textMain, // ЗМІНЕНО
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        );
      },
    );
  }

  // 3. Сітка вибору року
  Widget _buildYearGrid(AppColorsExtension colors, Color invertedTextColor) {
    return SizedBox(
      key: const ValueKey('years'),
      height: 300,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final double boxHeight = constraints.maxHeight;
          final double boxWidth = constraints.maxWidth;

          final double tileHeight = (boxWidth / 4) / 1.8;
          final double spacing = 12.0;

          double exactOffset =
              ((_focusedDay.year - _startYear) ~/ 4) * (tileHeight + spacing);
          double centeredOffset =
              exactOffset - (boxHeight / 2) + (tileHeight / 2);
          double initialOffset = centeredOffset < 0 ? 0 : centeredOffset;

          return GridView.builder(
            controller: ScrollController(initialScrollOffset: initialOffset),
            physics: const BouncingScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              childAspectRatio: 1.8,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
            ),
            itemCount: _endYear - _startYear + 1,
            itemBuilder: (context, index) {
              int year = _startYear + index;
              bool isSelected = _focusedDay.year == year;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _focusedDay = DateTime(year, _focusedDay.month, 1);
                    _mode = CalendarMode.date;
                  });
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected
                        ? colors.textMain
                        : colors.iconBg, // ЗМІНЕНО
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    year.toString(),
                    style: TextStyle(
                      color: isSelected
                          ? invertedTextColor
                          : colors.textMain, // ЗМІНЕНО
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
