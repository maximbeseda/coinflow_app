import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/finance_provider.dart';
import '../../models/subscription_model.dart';
import '../../utils/app_constants.dart';
import 'custom_calendar_dialog.dart';

// ============================================================================
// ВІДЖЕТ ДІАЛОГОВОГО ВІКОНЦЯ (ФОРМА ДОДАВАННЯ ТА РЕДАГУВАННЯ ПІДПИСКИ)
// ============================================================================
class SubscriptionFormDialog extends StatefulWidget {
  final Subscription? subscription;

  const SubscriptionFormDialog({super.key, this.subscription});

  @override
  State<SubscriptionFormDialog> createState() => _SubscriptionFormDialogState();
}

class _SubscriptionFormDialogState extends State<SubscriptionFormDialog> {
  late TextEditingController _nameController;
  late TextEditingController _amountController;

  String? _selectedAccountId;
  String? _selectedExpenseId;
  String _selectedPeriodicity = 'monthly';
  late DateTime _selectedDate;

  int? _customIconCodePoint;

  // Змінна для відстеження спроби збереження з пустими полями
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    final sub = widget.subscription;
    _nameController = TextEditingController(text: sub?.name ?? '');
    _amountController = TextEditingController(
      text: sub != null ? sub.amount.toString() : '',
    );
    _selectedAccountId = sub?.accountId;
    _selectedExpenseId = sub?.categoryId;
    _selectedPeriodicity = sub?.periodicity ?? 'monthly';
    _selectedDate = sub?.nextPaymentDate ?? DateTime.now();
    _customIconCodePoint = sub?.customIconCodePoint;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _save() {
    final amount =
        double.tryParse(_amountController.text.replaceAll(',', '.')) ?? 0.0;

    // ПЕРЕВІРКА НА ПОМИЛКИ
    if (_nameController.text.trim().isEmpty ||
        amount <= 0 ||
        _selectedAccountId == null ||
        _selectedExpenseId == null) {
      setState(() {
        _hasError = true; // Вмикаємо червоні рамки
      });
      return;
    }

    final provider = Provider.of<FinanceProvider>(context, listen: false);

    final newSub = Subscription(
      id:
          widget.subscription?.id ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameController.text.trim(),
      amount: amount,
      categoryId: _selectedExpenseId!,
      accountId: _selectedAccountId!,
      nextPaymentDate: _selectedDate,
      periodicity: _selectedPeriodicity,
      customIconCodePoint: _customIconCodePoint,
    );

    if (widget.subscription == null) {
      provider.addSubscription(newSub);
    } else {
      provider.updateSubscription(newSub);
    }

    Navigator.pop(context);
  }

  Future<void> _delete() async {
    if (widget.subscription == null) return;

    // Викликаємо вікно підтвердження в стилі HomeScreen
    bool confirmed =
        await showDialog<bool>(
          context: context,
          builder: (ctx) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
            ),
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.transparent,
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Іконка попередження
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.red,
                      size: 36,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "Видалити підписку?",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "Ви впевнені, що хочете видалити '${widget.subscription!.name}'? Це зупинить відстеження регулярних платежів.",
                    style: const TextStyle(fontSize: 14, color: Colors.black54),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  Row(
                    children: [
                      // Кнопка Скасувати
                      Expanded(
                        child: TextButton(
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            backgroundColor: Colors.grey.shade100,
                            foregroundColor: Colors.black87,
                          ),
                          onPressed: () => Navigator.pop(ctx, false),
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
                      // Кнопка Видалити
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text(
                            "Видалити",
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
        ) ??
        false;

    // ОДРАЗУ після await перевіряємо, чи екран ще існує:
    if (!mounted) return;

    // Якщо користувач підтвердив видалення
    if (confirmed) {
      final provider = Provider.of<FinanceProvider>(context, listen: false);
      provider.deleteSubscription(widget.subscription!.id);

      // Закриваємо форму
      Navigator.pop(context);
    }
  }

  Future<void> _pickDate() async {
    FocusScope.of(context).unfocus();
    final picked = await showDialog<DateTime>(
      context: context,
      builder: (context) => CustomCalendarDialog(initialDate: _selectedDate),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
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

              ListTile(
                leading: const Icon(Icons.refresh, color: Colors.blue),
                title: const Text(
                  "Використати іконку категорії",
                  style: TextStyle(
                    color: Colors.blue,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                onTap: () {
                  setState(() => _customIconCodePoint = null);
                  Navigator.pop(ctx);
                },
              ),
              const Divider(),

              Expanded(
                child: CustomScrollView(
                  controller: controller,
                  slivers: [
                    for (var entry in AppConstants.groupedIcons.entries) ...[
                      SliverPadding(
                        padding: const EdgeInsets.only(bottom: 12, top: 10),
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
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 5,
                              crossAxisSpacing: 10,
                              mainAxisSpacing: 10,
                            ),
                        delegate: SliverChildBuilderDelegate((context, i) {
                          IconData icon = entry.value[i];
                          bool isSelected =
                              _customIconCodePoint == icon.codePoint;
                          return GestureDetector(
                            onTap: () {
                              setState(
                                () => _customIconCodePoint = icon.codePoint,
                              );
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
                      const SliverToBoxAdapter(child: SizedBox(height: 12)),
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

  // ДОПОМІЖНИЙ МЕТОД ДЛЯ ЧЕРВОНИХ РАМОК
  InputBorder? _getErrorBorder(bool condition) {
    if (_hasError && condition) {
      return OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(
          color: Colors.red,
          width: 1,
        ), // Тоненька червона рамка
      );
    }
    return null; // Якщо помилки немає, тягнемо налаштування з Theme
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<FinanceProvider>(context, listen: false);
    final isEditing = widget.subscription != null;

    IconData displayIcon = Icons.card_giftcard;
    Color displayColor = Colors.grey.shade200;
    Color displayIconColor = Colors.black54;

    if (_customIconCodePoint != null) {
      displayIcon = IconData(
        _customIconCodePoint!,
        fontFamily: 'MaterialIcons',
      );
      if (_selectedExpenseId != null) {
        try {
          final cat = provider.expenses.firstWhere(
            (c) => c.id == _selectedExpenseId,
          );
          displayColor = cat.bgColor;
          displayIconColor = cat.iconColor;
        } catch (_) {}
      }
    } else if (_selectedExpenseId != null) {
      try {
        final cat = provider.expenses.firstWhere(
          (c) => c.id == _selectedExpenseId,
        );
        displayIcon = cat.icon;
        displayColor = cat.bgColor;
        displayIconColor = cat.iconColor;
      } catch (_) {}
    }

    return Dialog(
      insetPadding: const EdgeInsets.all(20),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isEditing ? 'Редагувати' : 'Нова підписка',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Кнопка видалення (тільки при редагуванні)
                    if (isEditing)
                      GestureDetector(
                        onTap: _delete,
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
                    if (isEditing) const SizedBox(width: 12),

                    // Кнопка закриття (хрестик)
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
            const SizedBox(height: 16),

            Center(
              child: GestureDetector(
                onTap: _openIconPicker,
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        color: displayColor,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        displayIcon,
                        size: 30,
                        color: displayIconColor,
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
            ),
            const SizedBox(height: 24),

            // ПОЛЕ "НАЗВА"
            TextField(
              controller: _nameController,
              onChanged: (_) {
                if (_hasError) setState(() {});
              },
              decoration: InputDecoration(
                hintText: 'Назва (напр. Netflix)',
                enabledBorder: _getErrorBorder(
                  _nameController.text.trim().isEmpty,
                ),
                focusedBorder: _getErrorBorder(
                  _nameController.text.trim().isEmpty,
                ),
              ),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                // ПОЛЕ "СУМА"
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: _amountController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    onChanged: (_) {
                      if (_hasError) setState(() {});
                    },
                    decoration: InputDecoration(
                      hintText: 'Сума',
                      suffixText: '₴',
                      enabledBorder: _getErrorBorder(
                        (double.tryParse(
                                  _amountController.text.replaceAll(',', '.'),
                                ) ??
                                0) <=
                            0,
                      ),
                      focusedBorder: _getErrorBorder(
                        (double.tryParse(
                                  _amountController.text.replaceAll(',', '.'),
                                ) ??
                                0) <=
                            0,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // ПОЛЕ "ПЕРІОД"
                Expanded(
                  flex: 2,
                  child: DropdownButtonFormField<String>(
                    isExpanded: true,
                    iconSize: 24,
                    icon: const Icon(
                      Icons.keyboard_arrow_down,
                      color: Colors.black54,
                    ),
                    dropdownColor: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                      fontWeight: FontWeight.w500,
                    ),
                    initialValue: _selectedPeriodicity,
                    onTap: () => FocusScope.of(context).unfocus(),
                    items: const [
                      DropdownMenuItem(value: 'monthly', child: Text('міс.')),
                      DropdownMenuItem(value: 'yearly', child: Text('рік')),
                      DropdownMenuItem(value: 'weekly', child: Text('тиж.')),
                    ],
                    onChanged: (val) =>
                        setState(() => _selectedPeriodicity = val!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ПОЛЕ "ЗВІДКИ" З ІКОНКАМИ
            DropdownButtonFormField<String>(
              isExpanded: true, // Додано для запобігання переповнення тексту
              initialValue: _selectedAccountId,
              hint: const Text(
                'Звідки списувати',
                style: TextStyle(color: Colors.black54),
              ),
              iconSize: 24,
              icon: const Icon(
                Icons.keyboard_arrow_down,
                color: Colors.black54,
              ),
              dropdownColor: Colors.white,
              borderRadius: BorderRadius.circular(16),
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black87,
                fontWeight: FontWeight.w500,
              ),
              onTap: () => FocusScope.of(context).unfocus(),
              items: provider.accounts.map((cat) {
                return DropdownMenuItem(
                  value: cat.id,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: cat.bgColor,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(cat.icon, size: 16, color: cat.iconColor),
                      ),
                      const SizedBox(width: 12),
                      Text(cat.name),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (val) => setState(() {
                _selectedAccountId = val;
              }),
              decoration: InputDecoration(
                enabledBorder: _getErrorBorder(_selectedAccountId == null),
                focusedBorder: _getErrorBorder(_selectedAccountId == null),
              ),
            ),
            const SizedBox(height: 16),

            // ПОЛЕ "КУДИ" З ІКОНКАМИ
            DropdownButtonFormField<String>(
              isExpanded: true, // Додано для запобігання переповнення тексту
              initialValue: _selectedExpenseId,
              hint: const Text(
                'Категорія витрат',
                style: TextStyle(color: Colors.black54),
              ),
              iconSize: 24,
              icon: const Icon(
                Icons.keyboard_arrow_down,
                color: Colors.black54,
              ),
              dropdownColor: Colors.white,
              borderRadius: BorderRadius.circular(16),
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black87,
                fontWeight: FontWeight.w500,
              ),
              onTap: () => FocusScope.of(context).unfocus(),
              items: provider.expenses.map((cat) {
                return DropdownMenuItem(
                  value: cat.id,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: cat.bgColor,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(cat.icon, size: 16, color: cat.iconColor),
                      ),
                      const SizedBox(width: 12),
                      Text(cat.name),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (val) => setState(() {
                _selectedExpenseId = val;
              }),
              decoration: InputDecoration(
                enabledBorder: _getErrorBorder(_selectedExpenseId == null),
                focusedBorder: _getErrorBorder(_selectedExpenseId == null),
              ),
            ),
            const SizedBox(height: 16),

            GestureDetector(
              onTap: _pickDate,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 16,
                  horizontal: 16,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Наступна оплата:',
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      DateFormat('dd.MM.yyyy').format(_selectedDate),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            ElevatedButton(
              onPressed: _save,
              child: const Text(
                'Зберегти',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
