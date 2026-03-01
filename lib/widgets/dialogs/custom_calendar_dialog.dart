import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

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

  final List<String> _months = [
    'Січень',
    'Лютий',
    'Березень',
    'Квітень',
    'Травень',
    'Червень',
    'Липень',
    'Серпень',
    'Вересень',
    'Жовтень',
    'Листопад',
    'Грудень',
  ];

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
              const Text(
                "Вибрати дату",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                      icon: const Icon(Icons.chevron_left),
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
                                    ? Colors.black
                                    : Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Text(
                                    _months[_focusedDay.month - 1],
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: _mode == CalendarMode.month
                                          ? Colors.white
                                          : Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(
                                    _mode == CalendarMode.month
                                        ? Icons.keyboard_arrow_up
                                        : Icons.keyboard_arrow_down,
                                    size: 16,
                                    color: _mode == CalendarMode.month
                                        ? Colors.white
                                        : Colors.black54,
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
                                    ? Colors.black
                                    : Colors.grey.shade100,
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
                                          ? Colors.white
                                          : Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(
                                    _mode == CalendarMode.year
                                        ? Icons.keyboard_arrow_up
                                        : Icons.keyboard_arrow_down,
                                    size: 16,
                                    color: _mode == CalendarMode.year
                                        ? Colors.white
                                        : Colors.black54,
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
                      icon: const Icon(Icons.chevron_right),
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
                  child: _buildContent(),
                ),
              ),

              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    // Стиль TextButton береться з AppTheme
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          "Скасувати",
                          style: TextStyle(
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
                      child: const FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          "OK",
                          style: TextStyle(
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

  Widget _buildContent() {
    switch (_mode) {
      case CalendarMode.month:
        return _buildMonthGrid();
      case CalendarMode.year:
        return _buildYearGrid();
      case CalendarMode.date:
        return _buildCalendar();
    }
  }

  // 1. Стандартний календар
  Widget _buildCalendar() {
    return TableCalendar(
      key: const ValueKey('calendar'),
      locale: 'uk_UA',
      firstDay: DateTime.utc(_startYear, 1, 1),
      lastDay: DateTime.utc(_endYear, 12, 31),
      focusedDay: _focusedDay,
      rowHeight: 46,
      selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
      startingDayOfWeek: StartingDayOfWeek.monday,
      headerVisible: false,
      calendarStyle: CalendarStyle(
        outsideDaysVisible: true,
        outsideTextStyle: const TextStyle(color: Colors.black38),
        defaultTextStyle: const TextStyle(
          color: Colors.black87,
          fontWeight: FontWeight.w500,
        ),
        weekendTextStyle: const TextStyle(
          color: Colors.redAccent,
          fontWeight: FontWeight.w500,
        ),
        cellMargin: const EdgeInsets.all(2.0),
        selectedDecoration: const BoxDecoration(
          color: Colors.black,
          shape: BoxShape.circle,
        ),
        todayDecoration: BoxDecoration(
          color: Colors.grey.shade200,
          shape: BoxShape.circle,
        ),
        todayTextStyle: const TextStyle(
          color: Colors.black,
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
  Widget _buildMonthGrid() {
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
              color: isSelected ? Colors.black : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(16),
            ),
            alignment: Alignment.center,
            child: Text(
              _months[index],
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.black87,
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
  Widget _buildYearGrid() {
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
                    color: isSelected ? Colors.black : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    year.toString(),
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.black87,
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
