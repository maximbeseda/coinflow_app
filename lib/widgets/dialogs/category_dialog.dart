import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart'; // ДОДАНО
import '../../models/category_model.dart';
import '../../utils/app_constants.dart';
import '../../theme/app_colors_extension.dart';
import '../../theme/category_defaults.dart';
import '../../providers/settings_provider.dart'; // ДОДАНО
import '../../models/app_currency.dart'; // ДОДАНО

class CategoryDialog extends StatefulWidget {
  final Category? category;
  final CategoryType type;

  const CategoryDialog({super.key, this.category, required this.type});

  @override
  State<CategoryDialog> createState() => _CategoryDialogState();
}

class _CategoryDialogState extends State<CategoryDialog> {
  late TextEditingController _nameCtrl;
  late TextEditingController _amountCtrl;
  late TextEditingController _budgetCtrl;
  late IconData _selectedIcon;

  // ДОДАНО: Стан для нових полів
  String? _selectedCurrency;
  bool _includeInTotal = true;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.category?.name ?? "");
    String formatDouble(double val) {
      return val.toStringAsFixed(2).replaceAll(RegExp(r'\.?0*$'), '');
    }

    _amountCtrl = TextEditingController(
      text: widget.category != null
          ? formatDouble(widget.category!.amount)
          : "0",
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

    _nameCtrl.addListener(() => setState(() {}));
  }

  // ДОДАНО: Ініціалізуємо валюту з провайдера, коли контекст стає доступним
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_selectedCurrency == null) {
      final settings = context.read<SettingsProvider>();
      // Якщо редагуємо - беремо збережену валюту, якщо створюємо нову - беремо базову
      _selectedCurrency = widget.category?.currency ?? settings.baseCurrency;
      _includeInTotal = widget.category?.includeInTotal ?? true;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _amountCtrl.dispose();
    _budgetCtrl.dispose();
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
                                color: isSelected ? Colors.blue : colors.iconBg,
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

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColorsExtension>()!;
    final settings = context.watch<SettingsProvider>();

    Color previewBgColor = CategoryDefaults.getBgColor(widget.type);
    Color previewIconColor = CategoryDefaults.getIconColor(widget.type);

    // Отримуємо поточний символ валюти для суфіксів полів вводу
    final currencySymbol = AppCurrency.fromCode(
      _selectedCurrency ?? settings.baseCurrency,
    ).symbol;

    // Показуємо всі валюти світу
    List<String> availableCurrencies = AppCurrency.supportedCurrencies
        .map((c) => c.code)
        .toList();

    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      widget.category == null
                          ? 'new_category'.tr()
                          : 'edit'.tr(),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: colors.textMain,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.category != null)
                        GestureDetector(
                          onTap: () => Navigator.pop(context, 'delete'),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: colors.expense.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.delete_outline,
                              color: colors.expense,
                              size: 20,
                            ),
                          ),
                        ),
                      if (widget.category != null) const SizedBox(width: 12),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: colors.iconBg,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.close,
                            color: colors.textMain,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),

              GestureDetector(
                onTap: _openIconPicker,
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        color: previewBgColor,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        _selectedIcon,
                        color: previewIconColor,
                        size: 30,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(
                        Icons.edit,
                        color: Colors.white,
                        size: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _nameCtrl.text.isEmpty ? 'name_hint'.tr() : _nameCtrl.text,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: colors.textMain,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 24),

              _buildTextField(
                controller: _nameCtrl,
                label: 'name'.tr(),
                maxLength: 20,
                keyboardType: TextInputType.text,
                colors: colors,
              ),

              const SizedBox(height: 12),

              // ДОДАНО: Вибір валюти для всіх типів категорій
              DropdownButtonFormField<String>(
                initialValue: _selectedCurrency,
                dropdownColor: colors.cardBg,
                icon: Icon(
                  Icons.keyboard_arrow_down,
                  color: colors.textSecondary,
                ),
                decoration: InputDecoration(
                  label: Text(
                    'currency'.tr(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  labelStyle: TextStyle(color: colors.textSecondary),
                ),
                items: availableCurrencies.map((code) {
                  final curr = AppCurrency.fromCode(code);
                  return DropdownMenuItem(
                    value: code,
                    child: Text(
                      "${curr.code} (${curr.symbol})",
                      style: TextStyle(
                        color: colors.textMain,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _selectedCurrency = val);
                  }
                },
              ),

              if (widget.type == CategoryType.account) ...[
                const SizedBox(height: 12),
                _buildTextField(
                  controller: _amountCtrl,
                  label: widget.category == null
                      ? 'initial_balance'.tr()
                      : 'current_balance'.tr(),
                  suffix: currencySymbol, // ЗМІНЕНО: Динамічний символ валюти
                  isNumber: true,
                  colors: colors,
                ),

                // ДОДАНО: Тумблер для рахунків
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    color: colors.iconBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: SwitchListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    title: Text(
                      'include_in_total'.tr(),
                      style: TextStyle(
                        color: colors.textMain,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    subtitle: Text(
                      'include_in_total_desc'.tr(),
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    value: _includeInTotal,
                    activeThumbColor: colors.income,
                    onChanged: (val) {
                      setState(() {
                        _includeInTotal = val;
                      });
                    },
                  ),
                ),
              ],

              if (widget.type != CategoryType.account) ...[
                const SizedBox(height: 12),
                _buildTextField(
                  controller: _budgetCtrl,
                  label: 'monthly_budget'.tr(),
                  hintText: 'enter_amount'.tr(),
                  suffix: currencySymbol, // ЗМІНЕНО: Динамічний символ валюти
                  isNumber: true,
                  colors: colors,
                ),
              ],

              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    if (_nameCtrl.text.isNotEmpty) {
                      double initialAmount =
                          double.tryParse(
                            _amountCtrl.text.replaceAll(',', '.'),
                          ) ??
                          0;
                      double? budgetAmount = double.tryParse(
                        _budgetCtrl.text.replaceAll(',', '.'),
                      );

                      // ЗМІНЕНО: Повертаємо нові поля
                      Navigator.pop(context, {
                        'name': _nameCtrl.text.trim(),
                        'icon': _selectedIcon,
                        'amount': initialAmount,
                        'budget': budgetAmount,
                        'currency': _selectedCurrency, // ДОДАНО
                        'includeInTotal': _includeInTotal, // ДОДАНО
                      });
                    }
                  },
                  child: Text(
                    widget.category == null ? 'create'.tr() : 'save'.tr(),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required AppColorsExtension colors,
    String? hintText,
    int? maxLength,
    String? suffix,
    bool isNumber = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      maxLength: maxLength,
      keyboardType: isNumber
          ? const TextInputType.numberWithOptions(decimal: true)
          : keyboardType,
      inputFormatters: isNumber
          ? [FilteringTextInputFormatter.allow(RegExp(r'^\d*[.,]?\d{0,2}'))]
          : null,
      textCapitalization: TextCapitalization.sentences,
      style: TextStyle(color: colors.textMain),
      decoration: InputDecoration(
        label: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
        hintText: hintText,
        counterText: "",
        suffixText: suffix,
        suffixStyle: TextStyle(
          fontWeight: FontWeight.bold,
          color: colors.textSecondary,
        ),
      ),
    );
  }
}
