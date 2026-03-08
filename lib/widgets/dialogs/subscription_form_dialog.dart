import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../providers/finance_provider.dart';
import '../../models/subscription_model.dart';
import '../../utils/app_constants.dart';
import 'custom_calendar_dialog.dart';
import '../../theme/app_colors_extension.dart';

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
  bool _isAutoPay = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    final sub = widget.subscription;
    final provider = Provider.of<FinanceProvider>(context, listen: false);

    _nameController = TextEditingController(text: sub?.name ?? '');
    _amountController = TextEditingController(
      text: sub != null ? sub.amount.toString() : '',
    );

    bool accountExists = provider.accounts.any((c) => c.id == sub?.accountId);
    _selectedAccountId = accountExists ? sub?.accountId : null;

    bool expenseExists = provider.expenses.any((c) => c.id == sub?.categoryId);
    _selectedExpenseId = expenseExists ? sub?.categoryId : null;

    _selectedPeriodicity = sub?.periodicity ?? 'monthly';
    _selectedDate = sub?.nextPaymentDate ?? DateTime.now();
    _customIconCodePoint = sub?.customIconCodePoint;
    _isAutoPay = sub?.isAutoPay ?? false;
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

    if (_nameController.text.trim().isEmpty ||
        amount <= 0 ||
        _selectedAccountId == null ||
        _selectedExpenseId == null) {
      setState(() => _hasError = true);
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
      isAutoPay: _isAutoPay,
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
                    'delete_subscription_title'.tr(),
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: colors.textMain,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'delete_subscription_message'.tr(
                      args: [widget.subscription!.name],
                    ),
                    style: TextStyle(fontSize: 14, color: colors.textSecondary),
                    textAlign: TextAlign.center,
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
                            // ДОДАНО: Захист від довгого тексту
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            backgroundColor: colors.expense,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          onPressed: () => Navigator.pop(ctx, true),
                          // ЗМІНЕНО: Прибрали FittedBox, додали Ellipsis
                          child: Text(
                            'delete'.tr(),
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
                ],
              ),
            ),
          ),
        ) ??
        false;

    if (!mounted) return;
    if (confirmed) {
      final provider = Provider.of<FinanceProvider>(context, listen: false);
      provider.deleteSubscription(widget.subscription!.id);
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
              ListTile(
                leading: const Icon(Icons.refresh, color: Colors.blue),
                title: Text(
                  'use_category_icon'.tr(),
                  style: const TextStyle(
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

  InputBorder? _getErrorBorder(bool condition, AppColorsExtension colors) {
    if (_hasError && condition) {
      return OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: colors.expense, width: 1),
      );
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<FinanceProvider>(context, listen: false);
    final isEditing = widget.subscription != null;
    final colors = Theme.of(context).extension<AppColorsExtension>()!;

    IconData displayIcon = Icons.card_giftcard;
    Color displayColor = colors.iconBg;
    Color displayIconColor = colors.textSecondary;

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
      backgroundColor: colors.cardBg,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    isEditing ? 'edit'.tr() : 'new_subscription'.tr(),
                    style: TextStyle(
                      fontSize: 20,
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
                    if (isEditing)
                      GestureDetector(
                        onTap: _delete,
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
                    if (isEditing) const SizedBox(width: 12),
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
              maxLength: 20,
              textCapitalization: TextCapitalization.sentences,
              onChanged: (_) {
                if (_hasError) setState(() {});
              },
              style: TextStyle(color: colors.textMain),
              decoration: InputDecoration(
                label: Text(
                  'name_hint_netflix'.tr(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                counterText: "",
                enabledBorder: _getErrorBorder(
                  _nameController.text.trim().isEmpty,
                  colors,
                ),
                focusedBorder: _getErrorBorder(
                  _nameController.text.trim().isEmpty,
                  colors,
                ),
              ),
            ),
            const SizedBox(height: 12),

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
                    style: TextStyle(color: colors.textMain),
                    decoration: InputDecoration(
                      label: Text(
                        'amount'.tr(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      suffixText: '₴',
                      suffixStyle: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: colors.textSecondary,
                      ),
                      enabledBorder: _getErrorBorder(
                        (double.tryParse(
                                  _amountController.text.replaceAll(',', '.'),
                                ) ??
                                0) <=
                            0,
                        colors,
                      ),
                      focusedBorder: _getErrorBorder(
                        (double.tryParse(
                                  _amountController.text.replaceAll(',', '.'),
                                ) ??
                                0) <=
                            0,
                        colors,
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
                    decoration: InputDecoration(
                      label: Text(
                        'period'.tr(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    icon: Icon(
                      Icons.keyboard_arrow_down,
                      color: colors.textSecondary,
                    ),
                    dropdownColor: colors.cardBg,
                    borderRadius: BorderRadius.circular(16),
                    style: TextStyle(
                      fontSize: 14,
                      color: colors.textMain,
                      fontWeight: FontWeight.w500,
                    ),
                    initialValue: _selectedPeriodicity,
                    onTap: () => FocusScope.of(context).unfocus(),
                    items: [
                      DropdownMenuItem(
                        value: 'monthly',
                        child: Text('period_monthly'.tr()),
                      ),
                      DropdownMenuItem(
                        value: 'yearly',
                        child: Text('period_yearly'.tr()),
                      ),
                      DropdownMenuItem(
                        value: 'weekly',
                        child: Text('period_weekly'.tr()),
                      ),
                    ],
                    onChanged: (val) =>
                        setState(() => _selectedPeriodicity = val!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // ПОЛЕ "ЗВІДКИ"
            DropdownButtonFormField<String>(
              isExpanded: true,
              initialValue: _selectedAccountId,
              iconSize: 24,
              icon: Icon(
                Icons.keyboard_arrow_down,
                color: colors.textSecondary,
              ),
              dropdownColor: colors.cardBg,
              borderRadius: BorderRadius.circular(16),
              style: TextStyle(
                fontSize: 16,
                color: colors.textMain,
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                label: Text(
                  'write_off_from'.tr(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                enabledBorder: _getErrorBorder(
                  _selectedAccountId == null,
                  colors,
                ),
                focusedBorder: _getErrorBorder(
                  _selectedAccountId == null,
                  colors,
                ),
              ),
              onTap: () => FocusScope.of(context).unfocus(),
              items: provider.accounts.map((cat) {
                return DropdownMenuItem(
                  value: cat.id,
                  child: Row(
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
                      Expanded(
                        child: Text(cat.name, overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (val) => setState(() => _selectedAccountId = val),
            ),
            const SizedBox(height: 12),

            // ПОЛЕ "КУДИ"
            DropdownButtonFormField<String>(
              isExpanded: true,
              initialValue: _selectedExpenseId,
              iconSize: 24,
              icon: Icon(
                Icons.keyboard_arrow_down,
                color: colors.textSecondary,
              ),
              dropdownColor: colors.cardBg,
              borderRadius: BorderRadius.circular(16),
              style: TextStyle(
                fontSize: 16,
                color: colors.textMain,
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                label: Text(
                  'expense_category'.tr(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                enabledBorder: _getErrorBorder(
                  _selectedExpenseId == null,
                  colors,
                ),
                focusedBorder: _getErrorBorder(
                  _selectedExpenseId == null,
                  colors,
                ),
              ),
              onTap: () => FocusScope.of(context).unfocus(),
              items: provider.expenses.map((cat) {
                return DropdownMenuItem(
                  value: cat.id,
                  child: Row(
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
                      Expanded(
                        child: Text(cat.name, overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (val) => setState(() => _selectedExpenseId = val),
            ),
            const SizedBox(height: 12),

            // ДАТА ТА АВТОСПИСАННЯ
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: GestureDetector(
                    onTap: _pickDate,
                    child: InputDecorator(
                      decoration: InputDecoration(
                        label: Text(
                          'payment'.tr(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      child: SizedBox(
                        height: 24,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              DateFormat('dd.MM.yyyy').format(_selectedDate),
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: colors.textMain,
                              ),
                            ),
                            Icon(
                              Icons.calendar_today,
                              size: 18,
                              color: colors.textSecondary,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: InputDecorator(
                    decoration: InputDecoration(
                      label: Text(
                        'auto_pay'.tr(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(letterSpacing: -0.3),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    child: SizedBox(
                      height: 24,
                      child: Align(
                        alignment: Alignment.center,
                        child: Transform.scale(
                          scale: 0.75,
                          child: CupertinoSwitch(
                            value: _isAutoPay,
                            activeTrackColor: colors.textMain,
                            onChanged: (val) =>
                                setState(() => _isAutoPay = val),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),

            ElevatedButton(
              onPressed: _save,
              // ЗМІНЕНО: Прибрали FittedBox, додали Ellipsis
              child: Text(
                'save'.tr(),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
