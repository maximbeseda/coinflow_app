import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../models/transaction_model.dart';
import 'custom_calendar_dialog.dart';
import '../../theme/app_colors_extension.dart'; // ДОДАНО: Імпорт теми

class EditTransactionDialog extends StatefulWidget {
  final Transaction transaction;

  const EditTransactionDialog({super.key, required this.transaction});

  @override
  State<EditTransactionDialog> createState() => _EditTransactionDialogState();
}

class _EditTransactionDialogState extends State<EditTransactionDialog> {
  late TextEditingController _amountCtrl;
  late DateTime _newDate;
  bool _hasError = false;

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
    FocusScope.of(context).unfocus();
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
    // ДОДАНО: Отримуємо кольори теми
    final colors = Theme.of(context).extension<AppColorsExtension>()!;

    // Прибрали shape, backgroundColor тощо — все береться з Theme!
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'edit_transaction'.tr(),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: colors.textMain, // ЗМІНЕНО
                ),
              ),
              const SizedBox(height: 24),

              TextField(
                controller: _amountCtrl,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                onChanged: (value) {
                  if (_hasError) setState(() => _hasError = false);
                },
                inputFormatters: [
                  FilteringTextInputFormatter.allow(
                    RegExp(r'^\d*[.,]?\d{0,2}'),
                  ),
                ],
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: colors.textMain, // ЗМІНЕНО
                ),
                decoration: InputDecoration(
                  labelText: 'amount'.tr(),
                  suffixText: "₴",
                  suffixStyle: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: colors.textSecondary, // ЗМІНЕНО: Був Colors.black54
                  ),
                  errorText: _hasError
                      ? 'invalid_amount'.tr()
                      : null, // Заміни 'invalid_amount' на свій ключ, якщо він інакший, або залиш 'enter_amount'
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
                    color: colors.iconBg, // ЗМІНЕНО: Був Colors.grey.shade100
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 20,
                        color: colors.textSecondary, // ЗМІНЕНО
                      ),
                      const SizedBox(width: 12),
                      Text(
                        "${_newDate.day.toString().padLeft(2, '0')}.${_newDate.month.toString().padLeft(2, '0')}.${_newDate.year}",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: colors.textMain, // ЗМІНЕНО
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
                    // Прибрали гігантські налаштування style
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'cancel'.tr(),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    // Прибрали гігантські налаштування style
                    child: ElevatedButton(
                      onPressed: () {
                        double? val = double.tryParse(
                          _amountCtrl.text.replaceAll(',', '.'),
                        );
                        if (val != null && val > 0) {
                          Navigator.pop(context, {
                            'amount': val,
                            'date': _newDate,
                          });
                        } else {
                          setState(() => _hasError = true);
                        }
                      },
                      child: Text(
                        'save'.tr(),
                        style: const TextStyle(
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
