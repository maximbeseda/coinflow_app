import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/category_model.dart';
import '../../utils/app_constants.dart';

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
    _amountCtrl = TextEditingController(
      text: widget.category != null ? widget.category!.amount.toString() : "0",
    );
    _budgetCtrl = TextEditingController(
      text: widget.category?.budget != null
          ? widget.category!.budget.toString()
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
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
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
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                "Оберіть іконку",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ),
                      ),
                      SliverGrid(
                        gridDelegate:
                            const SliverGridDelegateWithMaxCrossAxisExtent(
                              maxCrossAxisExtent:
                                  60, // Максимальна ширина однієї комірки
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
                                    ? Colors.blue
                                    : Colors.grey.shade100,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                icon,
                                color: isSelected
                                    ? Colors.white
                                    : Colors.black87,
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
    Color previewBgColor = widget.type == CategoryType.income
        ? Colors.black
        : (widget.type == CategoryType.account
              ? const Color(0xFF2C2C2E)
              : const Color(0xFFE5E5EA));
    Color previewIconColor = widget.type == CategoryType.expense
        ? Colors.black
        : Colors.white;

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
                    widget.category == null ? "Нова категорія" : "Редагувати",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  // БЛОК КНОПОК: ВИДАЛЕННЯ ТА ЗАКРИТТЯ
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Кнопка видалення (показується тільки при редагуванні)
                      if (widget.category != null)
                        GestureDetector(
                          onTap: () => Navigator.pop(context, 'delete'),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.red.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.delete_outline,
                              color: Colors.red,
                              size: 20,
                            ),
                          ),
                        ),
                      if (widget.category != null) const SizedBox(width: 12),

                      // Елегантний хрестик закриття вікна (показується завжди)
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.grey.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            color: Colors.black87,
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
                _nameCtrl.text.isEmpty ? "Назва..." : _nameCtrl.text,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 24),

              _buildTextField(
                controller: _nameCtrl,
                label: "Назва",
                maxLength: 20,
                keyboardType: TextInputType.text,
              ),

              if (widget.type == CategoryType.account) ...[
                const SizedBox(height: 12),
                _buildTextField(
                  controller: _amountCtrl,
                  label: widget.category == null
                      ? "Початковий баланс"
                      : "Поточний баланс",
                  suffix: "₴",
                  isNumber: true,
                ),
              ],

              if (widget.type != CategoryType.account) ...[
                const SizedBox(height: 12),
                _buildTextField(
                  controller: _budgetCtrl,
                  label: "Місячний бюджет",
                  hintText: "Вкажіть суму",
                  suffix: "₴",
                  isNumber: true,
                ),
              ],

              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                height: 50,
                // Прибрали гігантські налаштування style
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
                    widget.category == null ? "Створити" : "Зберегти",
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
        suffixStyle: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.black54,
        ),
        // Всі відступи та кольори тепер беруться з Theme
      ),
    );
  }
}
