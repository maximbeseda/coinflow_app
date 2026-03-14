import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';
import '../../models/category_model.dart';
import '../../models/app_currency.dart';
import '../../providers/settings_provider.dart';
import 'custom_calendar_dialog.dart';
import '../../theme/app_colors_extension.dart';

class TransferDialog extends StatefulWidget {
  final Category source;
  final Category target;

  const TransferDialog({super.key, required this.source, required this.target});

  @override
  State<TransferDialog> createState() => _TransferDialogState();
}

class _TransferDialogState extends State<TransferDialog> {
  final TextEditingController _sourceAmountCtrl = TextEditingController();
  final TextEditingController _targetAmountCtrl = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  bool _hasError = false;
  bool _isLoadingRate = false; // Оновлення курсу

  late bool _isMultiCurrency;
  late double _crossRate;

  bool _isLinked = true;
  String? _activeField;
  bool _isProgrammaticUpdate = false;

  @override
  void initState() {
    super.initState();
    _isMultiCurrency = widget.source.currency != widget.target.currency;
    if (_isMultiCurrency) {
      _crossRate = 1.0; // Тимчасове значення до завантаження
      WidgetsBinding.instance.addPostFrameCallback((_) => _updateCrossRate());
    }
  }

  // ЗАВАНТАЖЕННЯ КУРСУ НА ОБРАНУ ДАТУ
  Future<void> _updateCrossRate() async {
    if (!_isMultiCurrency) return;
    setState(() => _isLoadingRate = true);

    final settings = context.read<SettingsProvider>();
    double? sRate = await settings.getRateForDate(
      widget.source.currency,
      _selectedDate,
    );
    double? tRate = await settings.getRateForDate(
      widget.target.currency,
      _selectedDate,
    );

    if (mounted) {
      setState(() {
        _isLoadingRate = false;

        // Якщо API не має даних за цей старий день
        if (sRate == null || tRate == null) {
          _crossRate = 0.0;
          _isLinked = false;
        } else {
          // ДОДАНО: Якщо курс щойно з'явився (а до цього був 0.0), автоматично склеюємо поля назад!
          if (_crossRate == 0.0) {
            _isLinked = true;
          }

          // Якщо все ок, рахуємо як зазвичай
          _crossRate = tRate / sRate;
          if (_isLinked && _sourceAmountCtrl.text.isNotEmpty) {
            _isProgrammaticUpdate = true;
            double sVal =
                double.tryParse(_sourceAmountCtrl.text.replaceAll(',', '.')) ??
                0;
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
    _sourceAmountCtrl.dispose();
    _targetAmountCtrl.dispose();
    super.dispose();
  }

  void _onSourceChanged(String val) {
    if (_hasError) setState(() => _hasError = false);
    if (!_isMultiCurrency || _isProgrammaticUpdate) return;
    if (_sourceAmountCtrl.text.isEmpty && _targetAmountCtrl.text.isEmpty) {
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
    if (_sourceAmountCtrl.text.isEmpty && _targetAmountCtrl.text.isEmpty) {
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
        _sourceAmountCtrl.text = sVal > 0
            ? sVal.toStringAsFixed(2).replaceAll(RegExp(r'\.00$'), '')
            : "";
        _isProgrammaticUpdate = false;
      } else {
        setState(() => _isLinked = false);
      }
    }
  }

  void _submit() {
    double? sourceVal = double.tryParse(
      _sourceAmountCtrl.text.replaceAll(',', '.'),
    );
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
        'date': _selectedDate,
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
    final sourceSymbol = AppCurrency.fromCode(widget.source.currency).symbol;
    final targetSymbol = AppCurrency.fromCode(widget.target.currency).symbol;
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
                'amount_and_date'.tr(),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: colors.textMain,
                ),
              ),
              const SizedBox(height: 24),

              // ПОЛЕ 1 (Джерело)
              TextField(
                controller: _sourceAmountCtrl,
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
                  // Лаконічна назва
                  labelText: _isMultiCurrency
                      ? widget.source.name
                      : 'amount'.tr(),
                  labelStyle: TextStyle(
                    color: showBlueLink ? Colors.blue : colors.textSecondary,
                  ),
                  suffixText: sourceSymbol,
                  errorText:
                      _hasError &&
                          (double.tryParse(
                                    _sourceAmountCtrl.text.replaceAll(',', '.'),
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
                // Блок з курсом або спінером завантаження
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
                      Icon(
                        _isLinked ? Icons.link : Icons.link_off,
                        color: showBlueLink && _crossRate > 0
                            ? Colors.blue
                            : colors.textSecondary,
                        size: 18,
                      ),

                    const SizedBox(width: 8),
                    // ДОДАНО: Flexible для захисту від переповнення (Overflow)
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
                        // ДОДАНО: Якщо текст все одно не влазить, він закінчиться трьома крапками (...)
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
                    // Лаконічна назва
                    labelText: widget.target.name,
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
              // КАЛЕНДАР (тепер тригерить оновлення курсу)
              GestureDetector(
                onTap: () async {
                  FocusScope.of(context).unfocus();
                  DateTime? picked = await showDialog<DateTime>(
                    context: context,
                    builder: (context) =>
                        CustomCalendarDialog(initialDate: _selectedDate),
                  );
                  if (picked != null && picked != _selectedDate) {
                    setState(() => _selectedDate = picked);
                    await _updateCrossRate(); // ЗАПУСКАЄМО ОНОВЛЕННЯ
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
                        DateFormat('dd.MM.yyyy').format(_selectedDate),
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
                        'done'.tr(),
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
