import 'dart:async';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../models/category_model.dart';
import '../models/app_currency.dart';
import '../theme/app_colors_extension.dart';
import '../widgets/common/custom_numpad.dart';
import '../utils/calculator_helper.dart';
import '../widgets/common/date_strip_selector.dart';
import '../widgets/dialogs/premium_date_picker.dart';

class TransactionScreen extends StatefulWidget {
  final Category source;
  final Category target;

  final double? initialAmount;
  final double? initialTargetAmount;
  final DateTime? initialDate;
  final String? initialNote;

  const TransactionScreen({
    super.key,
    required this.source,
    required this.target,
    this.initialAmount,
    this.initialTargetAmount,
    this.initialDate,
    this.initialNote,
  });

  @override
  State<TransactionScreen> createState() => _TransactionScreenState();
}

class _TransactionScreenState extends State<TransactionScreen> {
  String _sourceExpression = "";
  String _sourceAmount = "0";

  String _targetExpression = "";
  String _targetAmount = "0";

  bool _isEditingTarget = false;

  bool _isRateLinked = true;
  String _lastEdited = 'source';

  double _currentExchangeRate = 1.0;
  bool _isRateInitialized = false;

  late DateTime _selectedDate;
  bool _isCommentActive = false;
  final TextEditingController _commentCtrl = TextEditingController();
  final FocusNode _commentFocusNode = FocusNode();

  Timer? _rateDebounceTimer;

  @override
  void initState() {
    super.initState();

    _selectedDate = widget.initialDate ?? DateTime.now();

    if (widget.initialAmount != null && widget.initialAmount! > 0) {
      _sourceAmount = _formatAmount(widget.initialAmount!);
      _sourceExpression = _sourceAmount;
    }

    if (widget.initialTargetAmount != null && widget.initialTargetAmount! > 0) {
      _targetAmount = _formatAmount(widget.initialTargetAmount!);
      _targetExpression = _targetAmount;
      _isRateLinked = false;
    }

    if (widget.initialNote != null && widget.initialNote!.isNotEmpty) {
      _commentCtrl.text = widget.initialNote!;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isRateInitialized) {
      _isRateInitialized = true;
      _fetchRateForDate(_selectedDate);
    }
  }

  Future<void> _fetchRateForDate(DateTime date) async {
    if (widget.source.currency == widget.target.currency) return;

    final settings = context.read<SettingsProvider>();

    double sourceRate =
        await settings.getRateForDate(widget.source.currency, date) ??
        (settings.exchangeRates[widget.source.currency] ?? 1.0);

    double targetRate =
        await settings.getRateForDate(widget.target.currency, date) ??
        (settings.exchangeRates[widget.target.currency] ?? 1.0);

    if (mounted) {
      setState(() {
        if (sourceRate == 0 || targetRate == 0) {
          _currentExchangeRate = 1.0;
        } else {
          // 👇 ЖОРСТКЕ ОКРУГЛЕННЯ ДО 4 ЗНАКІВ (Банківська точність)
          double rawRate = targetRate / sourceRate;
          if (rawRate >= 1.0) {
            _currentExchangeRate = double.parse(rawRate.toStringAsFixed(4));
          } else {
            double inverted = sourceRate / targetRate;
            double invertedRounded = double.parse(inverted.toStringAsFixed(4));
            _currentExchangeRate = 1.0 / invertedRounded;
          }
        }

        _recalculateLinkedAmounts();
      });
    }
  }

  void _recalculateLinkedAmounts() {
    if (!_isRateLinked) return;

    double currentVal =
        double.tryParse(_isEditingTarget ? _targetAmount : _sourceAmount) ??
        0.0;

    if (!_isEditingTarget) {
      double targetVal = currentVal * _currentExchangeRate;
      _targetAmount = _formatAmount(targetVal);
      _targetExpression = _targetAmount;
    } else {
      double sourceVal = currentVal / _currentExchangeRate;
      _sourceAmount = _formatAmount(sourceVal);
      _sourceExpression = _sourceAmount;
    }
  }

  String get _activeExpression =>
      _isEditingTarget ? _targetExpression : _sourceExpression;
  set _activeExpression(String val) {
    if (_isEditingTarget) {
      _targetExpression = val;
    } else {
      _sourceExpression = val;
    }
  }

  void _setActiveAmount(String val) {
    if (_isEditingTarget) {
      _targetAmount = val;
    } else {
      _sourceAmount = val;
    }
  }

  String _formatAmount(double val) {
    if (val == 0) return "0";
    String formatted = val.toStringAsFixed(2);
    if (formatted.endsWith('.00')) {
      return formatted.substring(0, formatted.length - 3);
    } else if (formatted.endsWith('0')) {
      return formatted.substring(0, formatted.length - 1);
    }
    return formatted;
  }

  // 👇 ДОДАНО: Спеціальний форматер для курсу валют (до 4 знаків)
  String _formatRate(double val) {
    if (val == 0) return "0";
    String formatted = val.toStringAsFixed(4);
    if (formatted.contains('.')) {
      formatted = formatted.replaceAll(
        RegExp(r'0*$'),
        '',
      ); // Прибираємо зайві нулі в кінці
      if (formatted.endsWith('.')) {
        formatted = formatted.substring(0, formatted.length - 1);
      }
    }
    return formatted;
  }

  @override
  void dispose() {
    _rateDebounceTimer?.cancel();
    _commentCtrl.dispose();
    _commentFocusNode.dispose();
    super.dispose();
  }

  void _onNumpadPressed(String key) {
    setState(() {
      if (_isRateLinked) {
        if (_isEditingTarget && _lastEdited == 'source') {
          _isRateLinked = false;
        } else if (!_isEditingTarget && _lastEdited == 'target') {
          _isRateLinked = false;
        }
      }
      _lastEdited = _isEditingTarget ? 'target' : 'source';

      if (key == 'C') {
        _activeExpression = "";
        _setActiveAmount("0");
      } else if (key == '⌫') {
        if (_activeExpression.isNotEmpty) {
          _activeExpression = _activeExpression.substring(
            0,
            _activeExpression.length - 1,
          );
        }
      } else if (key == '=') {
        _activeExpression = CalculatorHelper.calculate(_activeExpression);
      } else if (key == '%') {
        if (_activeExpression.isEmpty ||
            CalculatorHelper.endsWithOperator(_activeExpression)) {
          return;
        }

        String currentNumber = _activeExpression.split(RegExp(r'[+\-×÷]')).last;
        if (currentNumber.isEmpty) return;

        double percentValue = double.tryParse(currentNumber) ?? 0.0;
        String baseExpression = _activeExpression.substring(
          0,
          _activeExpression.length - currentNumber.length,
        );

        if (baseExpression.isNotEmpty) {
          String operator = baseExpression.substring(baseExpression.length - 1);
          if (operator == '+' || operator == '-') {
            String exprWithoutOp = baseExpression.substring(
              0,
              baseExpression.length - 1,
            );
            double baseAmount =
                double.tryParse(CalculatorHelper.calculate(exprWithoutOp)) ??
                0.0;
            double calculatedPercent = baseAmount * (percentValue / 100);

            String formattedPercent =
                calculatedPercent == calculatedPercent.toInt()
                ? calculatedPercent.toInt().toString()
                : calculatedPercent.toStringAsFixed(2);
            _activeExpression = baseExpression + formattedPercent;
          } else if (operator == '×' || operator == '÷') {
            double calc = percentValue / 100;
            String formatted = calc == calc.toInt()
                ? calc.toInt().toString()
                : calc.toString();
            _activeExpression = baseExpression + formatted;
          }
        } else {
          double calc = percentValue / 100;
          String formatted = calc == calc.toInt()
              ? calc.toInt().toString()
              : calc.toString();
          _activeExpression = formatted;
        }
      } else if (['+', '-', '×', '÷'].contains(key)) {
        if (_activeExpression.isEmpty) {
          if (key == '-') _activeExpression = '-';
        } else if (CalculatorHelper.endsWithOperator(_activeExpression)) {
          _activeExpression =
              _activeExpression.substring(0, _activeExpression.length - 1) +
              key;
        } else {
          _activeExpression += key;
        }
      } else {
        String currentNumber = _activeExpression.split(RegExp(r'[+\-×÷]')).last;

        if (key == '.') {
          if (currentNumber.contains('.')) return; // Вже є крапка
          if (currentNumber.isEmpty) {
            _activeExpression += '0.';
          } else {
            _activeExpression += '.';
          }
        } else {
          // Якщо натиснуто цифру або '00'
          if (currentNumber.contains('.')) {
            // МИ ПІСЛЯ КРАПКИ
            int decimalPlaces = currentNumber.split('.').last.length;

            if (decimalPlaces >= 2) return;

            if (key == '00') {
              if (decimalPlaces == 0) {
                _activeExpression += '00';
              } else if (decimalPlaces == 1) {
                _activeExpression += '0';
              }
            } else {
              _activeExpression += key;
            }
          } else {
            // МИ ДО КРАПКИ

            // 👇 ДОДАНО: Захист від зайвих нулів на початку
            if (currentNumber == "0") {
              if (key == '0' || key == '00') {
                return; // Ігноруємо натискання, клавіатура просто не відреагує
              } else {
                // Якщо натиснули цифру (1-9), замінюємо стартовий "0" на цю цифру
                _activeExpression =
                    _activeExpression.substring(
                      0,
                      _activeExpression.length - 1,
                    ) +
                    key;
              }
            } else {
              // Стандартна логіка введення
              if (currentNumber.length >= 12) return;

              if (key == '00') {
                if (currentNumber.length == 11) {
                  _activeExpression += '0';
                } else {
                  _activeExpression += '00';
                }
              } else {
                _activeExpression += key;
              }
            }
          }
        }
      }

      // Оновлення суми
      if (_activeExpression.isEmpty) {
        _setActiveAmount("0");
      } else if (_activeExpression == '-') {
        _setActiveAmount("-0");
      } else {
        String result = CalculatorHelper.calculate(_activeExpression);
        if (!CalculatorHelper.endsWithOperator(_activeExpression)) {
          _setActiveAmount(result);
        }
      }

      _recalculateLinkedAmounts();
    });
  }

  void _saveTransaction() {
    Navigator.pop(context, {
      'amount': double.tryParse(_sourceAmount) ?? 0.0,
      'targetAmount': widget.source.currency != widget.target.currency
          ? (double.tryParse(_targetAmount) ?? 0.0)
          : null,
      'date': _selectedDate,
      'comment': _commentCtrl.text,
    });
  }

  void _handleDateChanged(DateTime newDate) {
    if (_selectedDate.year == newDate.year &&
        _selectedDate.month == newDate.month &&
        _selectedDate.day == newDate.day) {
      return;
    }

    setState(() => _selectedDate = newDate);

    _rateDebounceTimer?.cancel();
    _rateDebounceTimer = Timer(const Duration(milliseconds: 250), () {
      if (mounted) {
        _fetchRateForDate(newDate);
      }
    });
  }

  Future<void> _handleCalendarTap() async {
    final DateTime? picked = await PremiumDatePicker.show(
      context: context,
      initialDate: _selectedDate,
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
      _fetchRateForDate(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColorsExtension>()!;

    return Scaffold(
      backgroundColor: colors.cardBg,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: CustomScrollView(
          physics: const ClampingScrollPhysics(),
          slivers: [
            SliverFillRemaining(
              hasScrollBody: false,
              child: Column(
                children: [
                  _buildHeader(colors),
                  Expanded(child: _buildAmountArea(colors)),
                  _buildToolbar(colors),
                  _buildSaveButton(),
                  _buildKeyboardArea(colors),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(AppColorsExtension colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            icon: Icon(Icons.close, color: colors.textSecondary, size: 22),
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  Expanded(child: _buildMiniCategory(widget.source, colors)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Icon(
                      Icons.arrow_forward_ios,
                      size: 10,
                      color: colors.textSecondary,
                    ),
                  ),
                  Expanded(child: _buildMiniCategory(widget.target, colors)),
                ],
              ),
            ),
          ),
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            icon: Icon(Icons.check, color: colors.textMain, size: 26),
            onPressed: _saveTransaction,
          ),
        ],
      ),
    );
  }

  Widget _buildMiniCategory(Category cat, AppColorsExtension colors) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      decoration: BoxDecoration(
        color: cat.bgColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(cat.icon, color: cat.iconColor, size: 14),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              cat.name,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              style: TextStyle(
                color: cat.iconColor,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSingleAmountBox({
    required String amount,
    required String expression,
    required String symbol,
    required bool isActive,
    required VoidCallback onTap,
    required AppColorsExtension colors,
  }) {
    bool hasMathOperators =
        expression.contains('+') ||
        expression.contains('×') ||
        expression.contains('÷') ||
        (expression.contains('-') && expression.lastIndexOf('-') > 0);

    String displayMainAmount = hasMathOperators
        ? amount
        : (expression.isEmpty ? "0" : expression);

    // 👇 ФУНКЦІЯ ФОРМАТУВАННЯ ТІЛЬКИ ДЛЯ ВІЗУАЛУ
    String formatWithSpaces(String text) {
      return text.replaceAllMapped(RegExp(r'\d+(\.\d+)?'), (match) {
        var parts = match[0]!.split('.');
        String intPart = parts[0].replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]} ',
        );
        return parts.length > 1 ? '$intPart.${parts[1]}' : intPart;
      });
    }

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text.rich(
                TextSpan(
                  children: [
                    // 👇 Застосовуємо форматування
                    TextSpan(text: formatWithSpaces(displayMainAmount)),
                    TextSpan(
                      text: " $symbol",
                      style: TextStyle(
                        fontSize: isActive ? 36 : 28,
                        color: colors.textSecondary.withValues(
                          alpha: isActive ? 1.0 : 0.4,
                        ),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                softWrap: false,
                overflow: TextOverflow.visible,
                style: TextStyle(
                  fontSize: isActive ? 56 : 42,
                  fontWeight: FontWeight.w800,
                  color: colors.textMain.withValues(
                    alpha: isActive ? 1.0 : 0.4,
                  ),
                  letterSpacing: -1,
                ),
              ),
            ),
          ),
          if (expression != amount &&
              expression.isNotEmpty &&
              hasMathOperators &&
              isActive)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  // 👇 Застосовуємо форматування для формули
                  formatWithSpaces(expression),
                  softWrap: false,
                  overflow: TextOverflow.visible,
                  style: TextStyle(
                    fontSize: 22,
                    color: colors.textSecondary.withValues(
                      alpha: isActive ? 1.0 : 0.4,
                    ),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMiddleExchangeRow(
    AppColorsExtension colors,
    String sourceSymbol,
    String targetSymbol,
  ) {
    final settings = context.read<SettingsProvider>();
    String rateText = "";

    // 👇 ЗМІНЕНО: Використовуємо _formatRate для відображення до 4 знаків
    if (widget.source.currency == settings.baseCurrency &&
        widget.target.currency != settings.baseCurrency) {
      double invertedRate = _currentExchangeRate > 0
          ? (1.0 / _currentExchangeRate)
          : 1.0;
      rateText = "1 $targetSymbol = ${_formatRate(invertedRate)} $sourceSymbol";
    } else {
      rateText =
          "1 $sourceSymbol = ${_formatRate(_currentExchangeRate)} $targetSymbol";
    }

    Color activeColor = Colors.blueAccent;
    Color inactiveColor = colors.textSecondary.withValues(alpha: 0.4);
    Color currentColor = _isRateLinked ? activeColor : inactiveColor;

    return GestureDetector(
      onTap: () {
        if (!_isRateLinked) {
          setState(() {
            _isRateLinked = true;
            _recalculateLinkedAmounts();
          });
        }
      },
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            const Expanded(child: SizedBox()),
            Icon(Icons.swap_vert, color: currentColor, size: 32),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(left: 12),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 200),
                    style: TextStyle(
                      color: currentColor,
                      fontSize: 14,
                      fontWeight: _isRateLinked
                          ? FontWeight.bold
                          : FontWeight.w500,
                    ),
                    child: Text(rateText),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAmountArea(AppColorsExtension colors) {
    bool isMultiCurrency = widget.source.currency != widget.target.currency;
    String sourceSymbol = AppCurrency.fromCode(widget.source.currency).symbol;
    String targetSymbol = AppCurrency.fromCode(widget.target.currency).symbol;

    if (!isMultiCurrency) {
      return Center(
        child: _buildSingleAmountBox(
          amount: _sourceAmount,
          expression: _sourceExpression,
          symbol: sourceSymbol,
          isActive: true,
          onTap: () {},
          colors: colors,
        ),
      );
    } else {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildSingleAmountBox(
            amount: _sourceAmount,
            expression: _sourceExpression,
            symbol: sourceSymbol,
            isActive: !_isEditingTarget,
            onTap: () => setState(() => _isEditingTarget = false),
            colors: colors,
          ),
          _buildMiddleExchangeRow(colors, sourceSymbol, targetSymbol),
          _buildSingleAmountBox(
            amount: _targetAmount,
            expression: _targetExpression,
            symbol: targetSymbol,
            isActive: _isEditingTarget,
            onTap: () => setState(() => _isEditingTarget = true),
            colors: colors,
          ),
        ],
      );
    }
  }

  Widget _buildToolbar(AppColorsExtension colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: RepaintBoundary(
              child: DateStripSelector(
                selectedDate: _selectedDate,
                onDateChanged: _handleDateChanged,
                onCalendarTap: _handleCalendarTap,
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () {
              setState(() {
                _isCommentActive = true;
              });
              _commentFocusNode.requestFocus();
            },
            child: Container(
              height: 48,
              width: 48,
              decoration: BoxDecoration(
                color: _isCommentActive || _commentCtrl.text.isNotEmpty
                    ? colors.iconBg
                    : colors.cardBg,
                shape: BoxShape.circle,
                border: Border.all(
                  color: colors.textSecondary.withValues(alpha: 0.2),
                ),
              ),
              child: Icon(Icons.notes, color: colors.textMain, size: 24),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _saveTransaction,
          child: Text(
            'done'.tr(),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  Widget _buildKeyboardArea(AppColorsExtension colors) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 150),
      child: _isCommentActive
          ? Padding(
              key: const ValueKey('text_field'),
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                focusNode: _commentFocusNode,
                controller: _commentCtrl,
                autofocus: true,
                maxLength: 100,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) {
                  _commentFocusNode.unfocus();
                  setState(() => _isCommentActive = false);
                },
                style: TextStyle(color: colors.textMain, fontSize: 16),
                decoration: InputDecoration(
                  hintText: 'add_note'.tr(),
                  border: InputBorder.none,
                  counterText: '',
                  suffixIcon: IconButton(
                    icon: Icon(
                      Icons.check_circle,
                      color: colors.textMain,
                      size: 28,
                    ),
                    onPressed: () {
                      _commentFocusNode.unfocus();
                      setState(() => _isCommentActive = false);
                    },
                  ),
                ),
              ),
            )
          : CustomNumpad(
              key: const ValueKey('numpad'),
              onKeyPressed: _onNumpadPressed,
            ),
    );
  }
}
