import 'package:flutter/material.dart';

class MonthPickerDialog extends StatefulWidget {
  final DateTime initialDate;
  const MonthPickerDialog({super.key, required this.initialDate});

  @override
  State<MonthPickerDialog> createState() => _MonthPickerDialogState();
}

class _MonthPickerDialogState extends State<MonthPickerDialog> {
  late int _selectedYear;
  final List<String> _months = [
    'Січ',
    'Лют',
    'Бер',
    'Кві',
    'Тра',
    'Чер',
    'Лип',
    'Сер',
    'Вер',
    'Жов',
    'Лис',
    'Гру',
  ];

  @override
  void initState() {
    super.initState();
    _selectedYear = widget.initialDate.year;
  }

  @override
  Widget build(BuildContext context) {
    // Dialog автоматично візьме shape та backgroundColor з AppTheme
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
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () => setState(() => _selectedYear--),
                ),
                Text(
                  _selectedYear.toString(),
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
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
                      // Залишаємо чорний акцент для вибраного елемента,
                      // оскільки це логіка вибору, а не загальний стиль кнопки
                      color: isSelected ? Colors.black : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
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
            ),

            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              // TextButton тепер автоматично має чорний колір тексту з AppTheme
              child: TextButton(
                onPressed: () {
                  final now = DateTime.now();
                  Navigator.pop(context, DateTime(now.year, now.month, 1));
                },
                child: const Text(
                  "Поточний місяць",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
