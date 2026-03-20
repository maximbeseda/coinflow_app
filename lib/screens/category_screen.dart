import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';
import '../models/category_model.dart';
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

  // ДОДАНО: Стан для помилки порожнього імені
  bool _showNameError = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.category?.name ?? "");
    _currencyCtrl = TextEditingController();

    String formatDouble(double val) {
      return val.toStringAsFixed(2).replaceAll(RegExp(r'\.?0*$'), '');
    }

    _amountCtrl = TextEditingController(
      text: widget.category != null
          ? formatDouble(widget.category!.amount)
          : "",
    );
    _budgetCtrl = TextEditingController(
      text: widget.category?.budget != null
          ? formatDouble(widget.category!.budget!)
          : "",
    );

    _selectedIcon =
        widget.category?.icon != null &&
            AppConstants.allIcons.contains(widget.category!.icon)
        ? widget.category!.icon
        : AppConstants.groupedIcons.values.first.first;

    _nameCtrl.addListener(() {
      // ДОДАНО: Якщо помилка активна і користувач почав вводити текст - прибираємо червоний колір
      if (_showNameError && _nameCtrl.text.trim().isNotEmpty) {
        _showNameError = false;
      }
      setState(() {});
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
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
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
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
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
                          padding: const EdgeInsets.all(4.0),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              curr.symbol,
                              maxLines: 1,
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : colors.textMain,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
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
    // ЗМІНЕНО: Валідація з підсвічуванням
    if (_nameCtrl.text.trim().isEmpty) {
      setState(() => _showNameError = true);
      return;
    }

    double initialAmount =
        double.tryParse(_amountCtrl.text.replaceAll(',', '.')) ?? 0;
    double? budgetAmount = double.tryParse(
      _budgetCtrl.text.replaceAll(',', '.'),
    );

    Navigator.pop(context, {
      'name': _nameCtrl.text.trim(),
      'icon': _selectedIcon,
      'amount': initialAmount,
      'budget': budgetAmount,
      'currency': _selectedCurrency,
      'includeInTotal': _includeInTotal,
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColorsExtension>()!;
    final settings = context.watch<SettingsProvider>();

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
                          onPressed: () => Navigator.pop(context, 'delete'),
                        ),
                      // ЗМІНЕНО: Кнопка тепер завжди активна, щоб викликати валідацію
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
                        // 1. НАЗВА (Тепер передаємо стан помилки)
                        _buildMaterialField(
                          controller: _nameCtrl,
                          label: 'name'.tr(),
                          colors: colors,
                          maxLength: 20,
                          isError:
                              _showNameError, // 🔴 ПЕРЕДАЄМО СТАТУС ПОМИЛКИ
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
                            prefixIcon: Padding(
                              padding: const EdgeInsets.only(right: 12.0),
                              child: CircleAvatar(
                                radius: 14,
                                backgroundColor: colors.iconBg,
                                child: Padding(
                                  padding: const EdgeInsets.all(4.0),
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      currencySymbol,
                                      maxLines: 1,
                                      style: TextStyle(
                                        color: colors.textMain,
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            prefixIconConstraints: const BoxConstraints(
                              minWidth: 36,
                              minHeight: 28,
                            ),
                            suffixIcon: Icon(
                              Icons.keyboard_arrow_down,
                              color: colors.textSecondary,
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
  // ЗМІНЕНО: Додано параметр `isError`, який керує кольором лінії та заголовка
  Widget _buildMaterialField({
    required TextEditingController controller,
    required String label,
    required AppColorsExtension colors,
    String? suffix,
    bool isNumber = false,
    int? maxLength,
    bool isError = false, // За замовчуванням помилки немає
  }) {
    // Визначаємо кольори залежно від стану
    final baseColor = isError ? Colors.red : colors.textSecondary;
    final activeColor = isError ? Colors.red : Colors.blueAccent;
    final underlineBaseColor = isError
        ? Colors.red
        : colors.textSecondary.withValues(alpha: 0.3);

    return TextField(
      controller: controller,
      maxLength: maxLength,
      keyboardType: isNumber
          ? const TextInputType.numberWithOptions(decimal: true)
          : TextInputType.text,
      inputFormatters: isNumber
          ? [FilteringTextInputFormatter.allow(RegExp(r'^\d*[.,]?\d{0,2}'))]
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
        labelStyle: TextStyle(
          color: baseColor,
          fontSize: 16,
        ), // Червоний, якщо є помилка
        floatingLabelStyle: TextStyle(
          color: activeColor, // Червоний при фокусі, якщо є помилка
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
            width: isError
                ? 2
                : 1, // Більш жирна лінія, щоб помилка була помітною
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
