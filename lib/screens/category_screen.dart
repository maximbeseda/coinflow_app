import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';
import '../database/app_database.dart';
import '../utils/app_constants.dart';
import '../theme/app_colors_extension.dart';
import '../theme/category_defaults.dart';
import '../providers/settings_provider.dart';
import '../models/app_currency.dart';

class CategoryScreen extends StatefulWidget {
  final Category? category;
  final CategoryType type;

  const CategoryScreen({super.key, this.category, required this.type});

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  late TextEditingController _nameCtrl;
  late TextEditingController _amountCtrl;
  late TextEditingController _budgetCtrl;
  late TextEditingController _currencyCtrl;
  late IconData _selectedIcon;

  String? _selectedCurrency;
  bool _includeInTotal = true;

  // Стан для помилки порожнього імені
  bool _showNameError = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.category?.name ?? "");
    _currencyCtrl = TextEditingController();

    // Функція тепер приймає int (копійки)
    String formatInt(int val) {
      double displayVal =
          val / 100.0; // Перетворюємо в double лише для відображення
      String str = displayVal
          .toStringAsFixed(2)
          .replaceAll(RegExp(r'\.?0*$'), '');
      var parts = str.split('.');
      String intPart = parts[0].replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (Match m) => '${m[1]} ',
      );
      return parts.length > 1 ? '$intPart.${parts[1]}' : intPart;
    }

    _amountCtrl = TextEditingController(
      text: widget.category != null ? formatInt(widget.category!.amount) : "",
    );
    _budgetCtrl = TextEditingController(
      text: widget.category?.budget != null
          ? formatInt(widget.category!.budget!)
          : "",
    );

    // 1. Спершу створюємо тимчасову змінну з IconData, якщо категорія існує
    final IconData? iconFromDb = widget.category != null
        ? IconData(widget.category!.icon, fontFamily: 'MaterialIcons')
        : null;

    // 2. Тепер ініціалізуємо _selectedIcon з перевіркою
    _selectedIcon = (iconFromDb != null)
        ? iconFromDb
        : AppConstants.groupedIcons.values.first.first;

    _nameCtrl.addListener(() {
      // Якщо помилка активна і користувач почав вводити текст - прибираємо червоний колір
      if (_showNameError && _nameCtrl.text.trim().isNotEmpty) {
        setState(() => _showNameError = false);
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_selectedCurrency == null) {
      final settings = context.read<SettingsProvider>();
      _selectedCurrency = widget.category?.currency ?? settings.baseCurrency;
      _includeInTotal = widget.category?.includeInTotal ?? true;

      _updateCurrencyText(_selectedCurrency!);
    }
  }

  void _updateCurrencyText(String code) {
    final curr = AppCurrency.fromCode(code);
    _currencyCtrl.text = curr.code;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _amountCtrl.dispose();
    _budgetCtrl.dispose();
    _currencyCtrl.dispose();
    super.dispose();
  }

  void _openIconPicker() {
    FocusScope.of(context).unfocus();
    final colors = Theme.of(context).extension<AppColorsExtension>()!;

    showModalBottomSheet(
      context: context,
      backgroundColor: colors.cardBg,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.65,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (_, controller) => Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.textSecondary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'choose_icon'.tr(),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: colors.textMain,
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: CustomScrollView(
                  controller: controller,
                  slivers: [
                    for (var entry in AppConstants.groupedIcons.entries) ...[
                      SliverPadding(
                        padding: const EdgeInsets.only(bottom: 12),
                        sliver: SliverToBoxAdapter(
                          child: Text(
                            entry.key,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: colors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                      SliverGrid(
                        gridDelegate:
                            const SliverGridDelegateWithMaxCrossAxisExtent(
                              maxCrossAxisExtent: 60,
                              crossAxisSpacing: 10,
                              mainAxisSpacing: 10,
                            ),
                        delegate: SliverChildBuilderDelegate((context, i) {
                          IconData icon = entry.value[i];
                          bool isSelected = _selectedIcon == icon;
                          return GestureDetector(
                            onTap: () {
                              setState(() => _selectedIcon = icon);
                              Navigator.pop(ctx);
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Colors.blueAccent
                                    : colors.iconBg,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                icon,
                                color: isSelected
                                    ? Colors.white
                                    : colors.textMain,
                                size: 26,
                              ),
                            ),
                          );
                        }, childCount: entry.value.length),
                      ),
                      const SliverToBoxAdapter(child: SizedBox(height: 24)),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openCurrencyPicker() {
    FocusScope.of(context).unfocus();
    final colors = Theme.of(context).extension<AppColorsExtension>()!;
    List<String> availableCurrencies = AppCurrency.supportedCurrencies
        .map((c) => c.code)
        .toList();

    showModalBottomSheet(
      context: context,
      backgroundColor: colors.cardBg,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (_, controller) => Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.textSecondary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'currency'.tr(),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: colors.textMain,
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: ListView.builder(
                  controller: controller,
                  physics: const BouncingScrollPhysics(),
                  itemCount: availableCurrencies.length,
                  itemBuilder: (context, index) {
                    final code = availableCurrencies[index];
                    final curr = AppCurrency.fromCode(code);
                    bool isSelected = _selectedCurrency == code;

                    return ListTile(
                      onTap: () {
                        setState(() {
                          _selectedCurrency = code;
                          _updateCurrencyText(code);
                        });
                        Navigator.pop(ctx);
                      },
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      leading: CircleAvatar(
                        radius: 16,
                        backgroundColor: isSelected
                            ? Colors.blueAccent
                            : colors.iconBg,
                        child: Padding(
                          padding: const EdgeInsets.all(2.0),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.center,
                            child: Text(
                              curr.symbol.trim(),
                              maxLines: 1,
                              textAlign: TextAlign.center,
                              strutStyle: const StrutStyle(
                                fontSize: 14,
                                height: 1.0,
                                forceStrutHeight: true,
                              ),
                              textHeightBehavior: const TextHeightBehavior(
                                applyHeightToFirstAscent: false,
                                applyHeightToLastDescent: false,
                              ),
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : colors.textMain,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                height: 1.0,
                              ),
                            ),
                          ),
                        ),
                      ),
                      title: Text(
                        curr.code,
                        style: TextStyle(
                          color: isSelected
                              ? Colors.blueAccent
                              : colors.textMain,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.w500,
                          fontSize: 16,
                        ),
                      ),
                      trailing: isSelected
                          ? const Icon(Icons.check, color: Colors.blueAccent)
                          : null,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _saveCategory() {
    if (_nameCtrl.text.trim().isEmpty) {
      setState(() => _showNameError = true);
      return;
    }

    double parsedAmount =
        double.tryParse(
          _amountCtrl.text.replaceAll(',', '.').replaceAll(' ', ''),
        ) ??
        0.0;
    int finalAmount = (parsedAmount * 100).round();

    int? finalBudget;
    double? parsedBudget = double.tryParse(
      _budgetCtrl.text.replaceAll(',', '.').replaceAll(' ', ''),
    );
    if (parsedBudget != null) {
      finalBudget = (parsedBudget * 100).round();
    }

    Navigator.pop(context, {
      'name': _nameCtrl.text.trim(),
      'icon':
          _selectedIcon.codePoint, // <-- ЗМІНЕНО: передаємо код іконки (int)
      'amount': finalAmount,
      'budget': finalBudget,
      'currency': _selectedCurrency,
      'includeInTotal': _includeInTotal,
    });
  }

  Future<void> _deleteCategory() async {
    if (widget.category == null) return;
    final colors = Theme.of(context).extension<AppColorsExtension>()!;

    bool confirmed =
        await showDialog<bool>(
          context: context,
          builder: (ctx) => Dialog(
            backgroundColor: colors.cardBg,
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colors.expense.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.warning_amber_rounded,
                      color: colors.expense,
                      size: 36,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'delete_category_title'.tr(),
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: colors.textMain,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),

                  Builder(
                    builder: (context) {
                      final itemName = widget.category!.name;
                      final fullText = 'delete_category_message'.tr(
                        args: [itemName],
                      );
                      final nameIndex = fullText.indexOf(itemName);

                      return Text.rich(
                        TextSpan(
                          children: nameIndex != -1
                              ? [
                                  TextSpan(
                                    text: fullText.substring(0, nameIndex),
                                  ),
                                  TextSpan(
                                    text: itemName,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: colors.textMain,
                                    ),
                                  ),
                                  TextSpan(
                                    text: fullText.substring(
                                      nameIndex + itemName.length,
                                    ),
                                  ),
                                ]
                              : [TextSpan(text: fullText)],
                        ),
                        style: TextStyle(
                          fontSize: 14,
                          color: colors.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      );
                    },
                  ),

                  const SizedBox(height: 32),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
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
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colors.expense,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () => Navigator.pop(ctx, true),
                          child: Text(
                            'delete'.tr(),
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
        ) ??
        false;

    if (!mounted) return;

    if (confirmed) {
      Navigator.pop(context, 'delete');
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColorsExtension>()!;
    // ОПТИМІЗАЦІЯ: read замість watch для статичного читання налаштувань
    final settings = context.read<SettingsProvider>();

    Color previewBgColor = CategoryDefaults.getBgColor(widget.type);
    Color previewIconColor = CategoryDefaults.getIconColor(widget.type);
    final currencySymbol = AppCurrency.fromCode(
      _selectedCurrency ?? settings.baseCurrency,
    ).symbol;

    return Scaffold(
      backgroundColor: colors.cardBg,
      body: SafeArea(
        child: Column(
          children: [
            // ШАПКА
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.close,
                      color: colors.textSecondary,
                      size: 28,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Text(
                    widget.category == null ? 'new_category'.tr() : 'edit'.tr(),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: colors.textMain,
                    ),
                  ),
                  Row(
                    children: [
                      if (widget.category != null)
                        IconButton(
                          icon: Icon(
                            Icons.delete_outline,
                            color: colors.expense,
                            size: 26,
                          ),
                          onPressed: _deleteCategory,
                        ),
                      IconButton(
                        icon: const Icon(
                          Icons.check,
                          color: Colors.blueAccent,
                          size: 28,
                        ),
                        onPressed: _saveCategory,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    const SizedBox(height: 30),
                    // КОМПАКТНА МОНЕТКА ДЛЯ ПЕРЕГЛЯДУ
                    GestureDetector(
                      onTap: _openIconPicker,
                      child: Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: previewBgColor,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: previewBgColor.withValues(alpha: 0.3),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Icon(
                              _selectedIcon,
                              color: previewIconColor,
                              size: 36,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: colors.cardBg,
                              shape: BoxShape.circle,
                              boxShadow: const [
                                BoxShadow(color: Colors.black12, blurRadius: 4),
                              ],
                            ),
                            child: const Icon(
                              Icons.edit,
                              color: Colors.blueAccent,
                              size: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),

                    // ЧИСТИЙ МІНІМАЛІСТИЧНИЙ ФОРМ-БЛОК
                    Column(
                      children: [
                        // 1. НАЗВА
                        _buildMaterialField(
                          controller: _nameCtrl,
                          label: 'name'.tr(),
                          colors: colors,
                          maxLength: 20,
                          isError: _showNameError,
                        ),
                        const SizedBox(height: 16),

                        // 2. ВАЛЮТА
                        TextField(
                          controller: _currencyCtrl,
                          readOnly: true,
                          onTap: _openCurrencyPicker,
                          style: TextStyle(
                            color: colors.textMain,
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                          ),
                          decoration: InputDecoration(
                            filled: false,
                            labelText: 'currency'.tr(),
                            labelStyle: TextStyle(
                              color: colors.textSecondary,
                              fontSize: 16,
                            ),
                            floatingLabelStyle: const TextStyle(
                              color: Colors.blueAccent,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                            prefix: Padding(
                              padding: const EdgeInsets.only(right: 12.0),
                              child: CircleAvatar(
                                radius: 14,
                                backgroundColor: colors.iconBg,
                                child: Padding(
                                  padding: const EdgeInsets.all(2.0),
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: Alignment.center,
                                    child: Text(
                                      currencySymbol.trim(),
                                      maxLines: 1,
                                      textAlign: TextAlign.center,
                                      strutStyle: const StrutStyle(
                                        fontSize: 14,
                                        height: 1.0,
                                        forceStrutHeight: true,
                                      ),
                                      textHeightBehavior:
                                          const TextHeightBehavior(
                                            applyHeightToFirstAscent: false,
                                            applyHeightToLastDescent: false,
                                          ),
                                      style: TextStyle(
                                        color: colors.textMain,
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        height: 1.0,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            suffixIcon: Padding(
                              padding: const EdgeInsets.only(top: 16.0),
                              child: Icon(
                                Icons.keyboard_arrow_down,
                                color: colors.textSecondary,
                              ),
                            ),
                            counterText: "",
                            enabledBorder: UnderlineInputBorder(
                              borderSide: BorderSide(
                                color: colors.textSecondary.withValues(
                                  alpha: 0.3,
                                ),
                                width: 1,
                              ),
                            ),
                            focusedBorder: const UnderlineInputBorder(
                              borderSide: BorderSide(
                                color: Colors.blueAccent,
                                width: 2,
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 12,
                            ),
                            isDense: true,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // 3. РАХУНОК (АКАУНТ)
                        if (widget.type == CategoryType.account) ...[
                          _buildMaterialField(
                            controller: _amountCtrl,
                            label: widget.category == null
                                ? 'initial_balance'.tr()
                                : 'current_balance'.tr(),
                            colors: colors,
                            isNumber: true,
                            suffix: " $currencySymbol",
                          ),
                          const SizedBox(height: 16),

                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              'include_in_total'.tr(),
                              style: TextStyle(
                                color: colors.textMain,
                                fontWeight: FontWeight.w500,
                                fontSize: 16,
                              ),
                            ),
                            value: _includeInTotal,
                            activeThumbColor: Colors.blueAccent,
                            onChanged: (val) =>
                                setState(() => _includeInTotal = val),
                          ),
                        ],

                        // 4. БЮДЖЕТ (ДЛЯ ВИТРАТ ТА ДОХОДІВ)
                        if (widget.type != CategoryType.account) ...[
                          _buildMaterialField(
                            controller: _budgetCtrl,
                            label: 'monthly_budget'.tr(),
                            colors: colors,
                            isNumber: true,
                            suffix: " $currencySymbol",
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ДОПОМІЖНИЙ ВІДЖЕТ ДЛЯ МАТЕРІАЛ-ПОЛЯ
  Widget _buildMaterialField({
    required TextEditingController controller,
    required String label,
    required AppColorsExtension colors,
    String? suffix,
    bool isNumber = false,
    int? maxLength,
    bool isError = false,
  }) {
    final baseColor = isError ? Colors.red : colors.textSecondary;
    final activeColor = isError ? Colors.red : Colors.blueAccent;
    final underlineBaseColor = isError
        ? Colors.red
        : colors.textSecondary.withValues(alpha: 0.3);

    return TextField(
      controller: controller,
      maxLength: isNumber ? null : maxLength,
      keyboardType: isNumber
          ? const TextInputType.numberWithOptions(decimal: true)
          : TextInputType.text,
      inputFormatters: isNumber
          ? [
              TextInputFormatter.withFunction((oldValue, newValue) {
                // Видаляємо пробіли і коми для чистої логіки
                String text = newValue.text
                    .replaceAll(',', '.')
                    .replaceAll(' ', '');
                if (text.isEmpty) return newValue.copyWith(text: text);

                if (text.indexOf('.') != text.lastIndexOf('.')) return oldValue;

                if (text.length > 1 &&
                    text.startsWith('0') &&
                    !text.startsWith('0.')) {
                  text = text.replaceFirst(RegExp(r'^0+'), '');
                  if (text.isEmpty) text = '0';
                }

                if (text.startsWith('.')) text = '0$text';

                var parts = text.split('.');
                String intPart = parts[0];
                String? decPart = parts.length > 1 ? parts[1] : null;

                if (intPart.length > 12) {
                  intPart = intPart.substring(0, 12);
                }

                if (decPart != null && decPart.length > 2) {
                  decPart = decPart.substring(0, 2);
                }

                // МАГІЯ ТУТ: Додаємо пробіли кожні 3 цифри в цілу частину
                String formattedInt = intPart.replaceAllMapped(
                  RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                  (Match m) => '${m[1]} ',
                );

                String newString = decPart == null
                    ? formattedInt
                    : (text.endsWith('.')
                          ? '$formattedInt.'
                          : '$formattedInt.$decPart');

                return TextEditingValue(
                  text: newString,
                  selection: TextSelection.collapsed(offset: newString.length),
                );
              }),
            ]
          : null,
      textCapitalization: TextCapitalization.sentences,
      style: TextStyle(
        color: colors.textMain,
        fontSize: 18,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        filled: false,
        labelText: label,
        labelStyle: TextStyle(color: baseColor, fontSize: 16),
        floatingLabelStyle: TextStyle(
          color: activeColor,
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
        suffixText: suffix,
        suffixStyle: TextStyle(
          fontWeight: FontWeight.bold,
          color: colors.textSecondary,
          fontSize: 16,
        ),
        counterText: "",
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(
            color: underlineBaseColor,
            width: isError ? 2 : 1,
          ),
        ),
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: activeColor, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
        isDense: true,
      ),
    );
  }
}
