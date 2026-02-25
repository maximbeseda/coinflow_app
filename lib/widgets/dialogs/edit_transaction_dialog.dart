import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/transaction_model.dart';
import 'custom_calendar_dialog.dart';

class EditTransactionDialog extends StatefulWidget {
  final Transaction transaction;

  const EditTransactionDialog({super.key, required this.transaction});

  @override
  State<EditTransactionDialog> createState() => _EditTransactionDialogState();
}

class _EditTransactionDialogState extends State<EditTransactionDialog> {
  late TextEditingController _amountCtrl;
  late DateTime _newDate;

  @override
  void initState() {
    super.initState();
    _amountCtrl = TextEditingController(
      text: widget.transaction.amount.toString(),
    );
    _newDate = widget.transaction.date;
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    // 1. Даємо команду сховати клавіатуру (вона почне ховатися асинхронно)
    FocusScope.of(context).unfocus();

    // 2. Одразу малюємо діалог. Завдяки SingleChildScrollView всередині нього,
    // конфлікту розмірів не буде, навіть поки клавіатура ще їде вниз.
    DateTime? picked = await showDialog<DateTime>(
      context: context,
      builder: (context) => CustomCalendarDialog(initialDate: _newDate),
    );

    if (picked != null) {
      setState(() => _newDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        // ДОДАНО ТУТ: Обгортаємо Column у SingleChildScrollView
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Редагувати операцію",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),

              TextField(
                controller: _amountCtrl,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(
                    RegExp(r'^\d*[.,]?\d{0,2}'),
                  ),
                ],
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                decoration: InputDecoration(
                  labelText: "Сума",
                  suffixText: "₴",
                  suffixStyle: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.black54,
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Colors.blue, width: 2),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              GestureDetector(
                onTap: _pickDate,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.calendar_today,
                        size: 20,
                        color: Colors.black54,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        "${_newDate.day.toString().padLeft(2, '0')}.${_newDate.month.toString().padLeft(2, '0')}.${_newDate.year}",
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        backgroundColor: Colors.grey.shade100,
                        foregroundColor: Colors.black87,
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        "Скасувати",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: () {
                        double? val = double.tryParse(
                          _amountCtrl.text.replaceAll(',', '.'),
                        );
                        if (val != null && val > 0) {
                          Navigator.pop(context, {
                            'amount': val,
                            'date': _newDate,
                          });
                        }
                      },
                      child: const Text(
                        "Зберегти",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
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
}
