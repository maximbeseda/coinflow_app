import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../models/category_model.dart';
import '../../utils/app_constants.dart';
import '../../theme/app_colors_extension.dart';
import '../../theme/category_defaults.dart'; // ДОДАНО: Імпорт нашого контракту кольорів

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

    // ЗМІНЕНО: Тепер ми беремо кольори прев'ю безпосередньо з нашої централізованої системи!
    Color previewBgColor = CategoryDefaults.getBgColor(widget.type);
    Color previewIconColor = CategoryDefaults.getIconColor(widget.type);

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
                  Text(
                    widget.category == null ? 'new_category'.tr() : 'edit'.tr(),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: colors.textMain,
                    ),
                  ),
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

              if (widget.type == CategoryType.account) ...[
                const SizedBox(height: 12),
                _buildTextField(
                  controller: _amountCtrl,
                  label: widget.category == null
                      ? 'initial_balance'.tr()
                      : 'current_balance'.tr(),
                  suffix: "₴",
                  isNumber: true,
                  colors: colors,
                ),
              ],

              if (widget.type != CategoryType.account) ...[
                const SizedBox(height: 12),
                _buildTextField(
                  controller: _budgetCtrl,
                  label: 'monthly_budget'.tr(),
                  hintText: 'enter_amount'.tr(),
                  suffix: "₴",
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
                      Navigator.pop(context, {
                        'name': _nameCtrl.text.trim(),
                        'icon': _selectedIcon,
                        'amount': initialAmount,
                        'budget': budgetAmount,
                      });
                    }
                  },
                  child: Text(
                    widget.category == null ? 'create'.tr() : 'save'.tr(),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
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
      decoration: InputDecoration(
        labelText: label,
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
