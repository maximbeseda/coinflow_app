import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';
import '../../models/transaction_model.dart';
import '../../models/app_currency.dart';
import '../../providers/settings_provider.dart';
import '../../providers/category_provider.dart';
import 'custom_calendar_dialog.dart';
import '../../theme/app_colors_extension.dart';

class EditTransactionDialog extends StatefulWidget {
  final Transaction transaction;

  const EditTransactionDialog({super.key, required this.transaction});

  @override
  State<EditTransactionDialog> createState() => _EditTransactionDialogState();
}

class _EditTransactionDialogState extends State<EditTransactionDialog> {
  late TextEditingController _amountCtrl;
  late TextEditingController _targetAmountCtrl;
  late DateTime _newDate;
  bool _hasError = false;
  bool _isLoadingRate = false;

  late bool _isMultiCurrency;
  double _crossRate = 0.0;

  // Починаємо незв'язаними, щоб не зламати оригінальні цифри користувача
  bool _isLinked = false;
  String? _activeField;
  bool _isProgrammaticUpdate = false;

  @override
  void initState() {
    super.initState();
    _amountCtrl = TextEditingController(
      text: widget.transaction.amount
          .toStringAsFixed(2)
          .replaceAll(RegExp(r'\.00$'), ''),
    );
    _newDate = widget.transaction.date;

    _isMultiCurrency =
        widget.transaction.targetCurrency != null &&
        widget.transaction.currency != widget.transaction.targetCurrency;

    if (_isMultiCurrency) {
      _targetAmountCtrl = TextEditingController(
        text:
            widget.transaction.targetAmount
                ?.toStringAsFixed(2)
                .replaceAll(RegExp(r'\.00$'), '') ??
            "",
      );

      // Витягуємо оригінальний курс, за яким була збережена транзакція
      if (widget.transaction.amount > 0 &&
          widget.transaction.targetAmount != null) {
        _crossRate =
            widget.transaction.targetAmount! / widget.transaction.amount;
      } else {
        WidgetsBinding.instance.addPostFrameCallback((_) => _updateCrossRate());
      }
    } else {
      _targetAmountCtrl = TextEditingController();
    }
  }

  Future<void> _updateCrossRate() async {
    if (!_isMultiCurrency) return;
    setState(() => _isLoadingRate = true);

    final settings = context.read<SettingsProvider>();
    double? sRate = await settings.getRateForDate(
      widget.transaction.currency,
      _newDate,
    );
    double? tRate = await settings.getRateForDate(
      widget.transaction.targetCurrency!,
      _newDate,
    );

    if (mounted) {
      setState(() {
        _isLoadingRate = false;
        if (sRate == null || tRate == null) {
          _crossRate = 0.0;
          _isLinked = false;
        } else {
          // ДОДАНО: Автоматичне відновлення зв'язку при поверненні нормальної дати
          if (_crossRate == 0.0) {
            _isLinked = true;
          }

          _crossRate = tRate / sRate;
          if (_isLinked && _amountCtrl.text.isNotEmpty) {
            _isProgrammaticUpdate = true;
            double sVal =
                double.tryParse(_amountCtrl.text.replaceAll(',', '.')) ?? 0;
            double tVal = sVal * _crossRate;
            _targetAmountCtrl.text = tVal > 0
                ? tVal.toStringAsFixed(2).replaceAll(RegExp(r'\.00$'), '')
                : "";
            _isProgrammaticUpdate = false;
          }
        }
      });
    }
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _targetAmountCtrl.dispose();
    super.dispose();
  }

  void _onSourceChanged(String val) {
    if (_hasError) setState(() => _hasError = false);
    if (!_isMultiCurrency || _isProgrammaticUpdate) return;
    if (_amountCtrl.text.isEmpty && _targetAmountCtrl.text.isEmpty) {
      setState(() {
        _isLinked = true;
        _activeField = null;
      });
      return;
    }
    if (_isLinked) {
      _activeField ??= 'source';
      if (_activeField == 'source') {
        _isProgrammaticUpdate = true;
        double sVal = double.tryParse(val.replaceAll(',', '.')) ?? 0;
        double tVal = sVal * _crossRate;
        _targetAmountCtrl.text = tVal > 0
            ? tVal.toStringAsFixed(2).replaceAll(RegExp(r'\.00$'), '')
            : "";
        _isProgrammaticUpdate = false;
      } else {
        setState(() => _isLinked = false);
      }
    }
  }

  void _onTargetChanged(String val) {
    if (_hasError) setState(() => _hasError = false);
    if (!_isMultiCurrency || _isProgrammaticUpdate) return;
    if (_amountCtrl.text.isEmpty && _targetAmountCtrl.text.isEmpty) {
      setState(() {
        _isLinked = true;
        _activeField = null;
      });
      return;
    }
    if (_isLinked) {
      _activeField ??= 'target';
      if (_activeField == 'target') {
        _isProgrammaticUpdate = true;
        double tVal = double.tryParse(val.replaceAll(',', '.')) ?? 0;
        double sVal = tVal / _crossRate;
        _amountCtrl.text = sVal > 0
            ? sVal.toStringAsFixed(2).replaceAll(RegExp(r'\.00$'), '')
            : "";
        _isProgrammaticUpdate = false;
      } else {
        setState(() => _isLinked = false);
      }
    }
  }

  void _toggleLink() {
    if (_crossRate == 0.0) return; // Не можна зв'язати, якщо курсу немає
    setState(() {
      _isLinked = !_isLinked;
      if (_isLinked && _amountCtrl.text.isNotEmpty) {
        _isProgrammaticUpdate = true;
        double sVal =
            double.tryParse(_amountCtrl.text.replaceAll(',', '.')) ?? 0;
        double tVal = sVal * _crossRate;
        _targetAmountCtrl.text = tVal > 0
            ? tVal.toStringAsFixed(2).replaceAll(RegExp(r'\.00$'), '')
            : "";
        _isProgrammaticUpdate = false;
      }
    });
  }

  void _submit() {
    double? sourceVal = double.tryParse(_amountCtrl.text.replaceAll(',', '.'));
    double? targetVal;
    if (_isMultiCurrency) {
      targetVal = double.tryParse(_targetAmountCtrl.text.replaceAll(',', '.'));
    }

    if (sourceVal != null &&
        sourceVal > 0 &&
        (!_isMultiCurrency || (targetVal != null && targetVal > 0))) {
      Navigator.pop(context, {
        'amount': sourceVal,
        'targetAmount': _isMultiCurrency ? targetVal : null,
        'date': _newDate,
      });
    } else {
      setState(() => _hasError = true);
    }
  }

  OutlineInputBorder _buildBorder(Color color, {double width = 1.0}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: color, width: width),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColorsExtension>()!;
    final sourceSymbol = AppCurrency.fromCode(
      widget.transaction.currency,
    ).symbol;
    final targetSymbol = _isMultiCurrency
        ? AppCurrency.fromCode(widget.transaction.targetCurrency!).symbol
        : "";

    // Витягуємо назви категорій для красивих підписів полів
    final allCats = context.read<CategoryProvider>().allCategoriesList;
    final sourceName =
        allCats
            .where((c) => c.id == widget.transaction.fromId)
            .firstOrNull
            ?.name ??
        'amount'.tr();
    final targetName =
        allCats
            .where((c) => c.id == widget.transaction.toId)
            .firstOrNull
            ?.name ??
        'amount'.tr();

    final bool showBlueLink =
        _isMultiCurrency && _isLinked && !_hasError && !_isLoadingRate;

    return Dialog(
      backgroundColor: colors.cardBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'edit'.tr(),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: colors.textMain,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 24),

              // ПОЛЕ 1 (Джерело)
              TextField(
                controller: _amountCtrl,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                autofocus: true,
                onChanged: _onSourceChanged,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(
                    RegExp(r'^\d*[.,]?\d{0,2}'),
                  ),
                ],
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: colors.textMain,
                ),
                decoration: InputDecoration(
                  labelText: _isMultiCurrency ? sourceName : 'amount'.tr(),
                  labelStyle: TextStyle(
                    color: showBlueLink ? Colors.blue : colors.textSecondary,
                  ),
                  suffixText: sourceSymbol,
                  errorText:
                      _hasError &&
                          (double.tryParse(
                                    _amountCtrl.text.replaceAll(',', '.'),
                                  ) ??
                                  0) <=
                              0
                      ? 'enter_amount'.tr()
                      : null,
                  enabledBorder: _buildBorder(
                    showBlueLink
                        ? Colors.blue
                        : colors.textSecondary.withValues(alpha: 0.3),
                  ),
                  focusedBorder: _buildBorder(
                    showBlueLink ? Colors.blue : colors.textMain,
                    width: 2.0,
                  ),
                  errorBorder: _buildBorder(colors.expense),
                  focusedErrorBorder: _buildBorder(colors.expense, width: 2.0),
                ),
              ),

              if (_isMultiCurrency) ...[
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_isLoadingRate)
                      SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: colors.textSecondary,
                        ),
                      )
                    else
                      GestureDetector(
                        onTap: _toggleLink,
                        child: Icon(
                          _isLinked ? Icons.link : Icons.link_off,
                          color: showBlueLink && _crossRate > 0
                              ? Colors.blue
                              : colors.textSecondary,
                          size: 18,
                        ),
                      ),

                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        _isLoadingRate
                            ? 'loading_rate'.tr()
                            : (_crossRate == 0.0
                                  ? 'rate_not_found'.tr()
                                  : "1 $sourceSymbol = ${_crossRate.toStringAsFixed(4)} $targetSymbol"),
                        style: TextStyle(
                          fontSize: 12,
                          color: _crossRate == 0.0 && !_isLoadingRate
                              ? colors.expense
                              : colors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // ПОЛЕ 2 (Ціль)
                TextField(
                  controller: _targetAmountCtrl,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  onChanged: _onTargetChanged,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                      RegExp(r'^\d*[.,]?\d{0,2}'),
                    ),
                  ],
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: colors.textMain,
                  ),
                  decoration: InputDecoration(
                    labelText: targetName,
                    labelStyle: TextStyle(
                      color: showBlueLink ? Colors.blue : colors.textSecondary,
                    ),
                    suffixText: targetSymbol,
                    errorText:
                        _hasError &&
                            (double.tryParse(
                                      _targetAmountCtrl.text.replaceAll(
                                        ',',
                                        '.',
                                      ),
                                    ) ??
                                    0) <=
                                0
                        ? 'enter_amount'.tr()
                        : null,
                    enabledBorder: _buildBorder(
                      showBlueLink
                          ? Colors.blue
                          : colors.textSecondary.withValues(alpha: 0.3),
                    ),
                    focusedBorder: _buildBorder(
                      showBlueLink ? Colors.blue : colors.textMain,
                      width: 2.0,
                    ),
                    errorBorder: _buildBorder(colors.expense),
                    focusedErrorBorder: _buildBorder(
                      colors.expense,
                      width: 2.0,
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 24),
              GestureDetector(
                onTap: () async {
                  FocusScope.of(context).unfocus();
                  DateTime? picked = await showDialog<DateTime>(
                    context: context,
                    builder: (context) =>
                        CustomCalendarDialog(initialDate: _newDate),
                  );
                  if (picked != null && picked != _newDate) {
                    setState(() => _newDate = picked);
                    await _updateCrossRate(); // ЗАПУСКАЄМО ОНОВЛЕННЯ КУРСУ ПРИ ЗМІНІ ДАТИ
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colors.iconBg,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 20,
                        color: colors.textSecondary,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        DateFormat('dd.MM.yyyy').format(_newDate),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: colors.textMain,
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
                    child: ElevatedButton(
                      onPressed: _submit,
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
