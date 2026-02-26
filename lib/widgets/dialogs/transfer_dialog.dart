import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/category_model.dart';
import 'custom_calendar_dialog.dart';

class TransferDialog extends StatefulWidget {
  final Category source;
  final Category target;

  const TransferDialog({super.key, required this.source, required this.target});

  @override
  State<TransferDialog> createState() => _TransferDialogState();
}

class _TransferDialogState extends State<TransferDialog> {
  final TextEditingController _amountCtrl = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  bool _hasError = false;

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    FocusScope.of(context).unfocus();
    DateTime? picked = await showDialog<DateTime>(
      context: context,
      builder: (context) => CustomCalendarDialog(initialDate: _selectedDate),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    // ВАУ! Ми прибрали shape та backgroundColor, бо вони тепер у Theme
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Сума та дата",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),

              TextField(
                controller: _amountCtrl,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                autofocus: true,
                onChanged: (value) {
                  if (_hasError) setState(() => _hasError = false);
                },
                inputFormatters: [
                  FilteringTextInputFormatter.allow(
                    RegExp(r'^\d*[.,]?\d{0,2}'),
                  ),
                ],
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                // Ми залишаємо тут тільки специфічні для ЦЬОГО поля речі:
                // суфікс, лейбл і червону рамку для помилки. Усе інше тягнеться з Theme!
                decoration: InputDecoration(
                  labelText: "Сума",
                  suffixText: "₴",
                  suffixStyle: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.black54,
                  ),
                  enabledBorder: _hasError
                      ? OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(
                            color: Colors.red,
                            width: 1,
                          ),
                        )
                      : null,
                  focusedBorder: _hasError
                      ? OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(
                            color: Colors.red,
                            width: 2,
                          ),
                        )
                      : null,
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
                        "${_selectedDate.day.toString().padLeft(2, '0')}.${_selectedDate.month.toString().padLeft(2, '0')}.${_selectedDate.year}",
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
                    // Більше ніякого полотна з padding, shape та backgroundColor!
                    child: TextButton(
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
                    // Так само і тут — все підтягується з Theme
                    child: ElevatedButton(
                      onPressed: () {
                        double? val = double.tryParse(
                          _amountCtrl.text.replaceAll(',', '.'),
                        );
                        if (val != null && val > 0) {
                          Navigator.pop(context, {
                            'amount': val,
                            'date': _selectedDate,
                          });
                        } else {
                          setState(() => _hasError = true);
                        }
                      },
                      child: const Text(
                        "Готово",
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
