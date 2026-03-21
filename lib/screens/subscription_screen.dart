import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import '../providers/category_provider.dart';
import '../providers/subscription_provider.dart';
import '../providers/settings_provider.dart';
import '../models/subscription_model.dart';
import '../models/app_currency.dart';
import '../models/category_model.dart';
import '../utils/app_constants.dart';
import '../widgets/dialogs/custom_calendar_dialog.dart';
import '../theme/app_colors_extension.dart';

class SubscriptionScreen extends StatefulWidget {
  final Subscription? subscription;

  const SubscriptionScreen({super.key, this.subscription});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  late TextEditingController _nameCtrl;
  late TextEditingController _amountCtrl;
  late TextEditingController _currencyCtrl;
  late TextEditingController _periodicityCtrl;
  late TextEditingController _accountCtrl;
  late TextEditingController _expenseCtrl;
  late TextEditingController _dateCtrl;

  String? _selectedCurrency;
  String? _selectedAccountId;
  String? _selectedExpenseId;
  String _selectedPeriodicity = 'monthly';
  late DateTime _selectedDate;

  int? _customIconCodePoint;
  bool _isAutoPay = false;

  // Стани для валідації
  bool _showNameError = false;
  bool _showAmountError = false;
  bool _showAccountError = false;
  bool _showExpenseError = false;

  @override
  void initState() {
    super.initState();
    final sub = widget.subscription;

    _nameCtrl = TextEditingController(text: sub?.name ?? '');
    String formatDouble(double val) {
      return val.toStringAsFixed(2).replaceAll(RegExp(r'\.?0*$'), '');
    }

    _amountCtrl = TextEditingController(
      text: sub != null ? formatDouble(sub.amount) : '',
    );

    _currencyCtrl = TextEditingController();
    _periodicityCtrl = TextEditingController();
    _accountCtrl = TextEditingController();
    _expenseCtrl = TextEditingController();
    _dateCtrl = TextEditingController();

    _selectedPeriodicity = sub?.periodicity ?? 'monthly';
    _selectedDate = sub?.nextPaymentDate ?? DateTime.now();
    _customIconCodePoint = sub?.customIconCodePoint;
    _isAutoPay = sub?.isAutoPay ?? false;

    // Скидання помилок при введенні
    _nameCtrl.addListener(() {
      if (_showNameError && _nameCtrl.text.trim().isNotEmpty) {
        setState(() => _showNameError = false);
      }
    });
    _amountCtrl.addListener(() {
      if (_showAmountError && _amountCtrl.text.trim().isNotEmpty) {
        setState(() => _showAmountError = false);
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final catProv = context.read<CategoryProvider>();
    final settings = context.read<SettingsProvider>();

    if (_selectedCurrency == null) {
      _selectedCurrency =
          widget.subscription?.currency ?? settings.baseCurrency;
      _updateCurrencyText(_selectedCurrency!);
    }

    if (_selectedAccountId == null && widget.subscription != null) {
      bool accountExists = catProv.accounts.any(
        (c) => c.id == widget.subscription?.accountId,
      );
      if (accountExists) {
        _selectedAccountId = widget.subscription!.accountId;
        _updateCategoryText(
          _accountCtrl,
          catProv.accounts,
          _selectedAccountId!,
        );
      }
    }

    if (_selectedExpenseId == null && widget.subscription != null) {
      bool expenseExists = catProv.expenses.any(
        (c) => c.id == widget.subscription?.categoryId,
      );
      if (expenseExists) {
        _selectedExpenseId = widget.subscription!.categoryId;
        _updateCategoryText(
          _expenseCtrl,
          catProv.expenses,
          _selectedExpenseId!,
        );
      }
    }

    _updatePeriodicityText(_selectedPeriodicity);
    _updateDateText(_selectedDate);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _amountCtrl.dispose();
    _currencyCtrl.dispose();
    _periodicityCtrl.dispose();
    _accountCtrl.dispose();
    _expenseCtrl.dispose();
    _dateCtrl.dispose();
    super.dispose();
  }

  void _updateCurrencyText(String code) {
    _currencyCtrl.text = AppCurrency.fromCode(code).code;
  }

  void _updatePeriodicityText(String period) {
    if (period == 'monthly') {
      _periodicityCtrl.text = 'period_monthly'.tr();
    } else if (period == 'yearly') {
      _periodicityCtrl.text = 'period_yearly'.tr();
    } else if (period == 'weekly') {
      _periodicityCtrl.text = 'period_weekly'.tr();
    }
  }

  void _updateCategoryText(
    TextEditingController ctrl,
    List<Category> list,
    String id,
  ) {
    try {
      ctrl.text = list.firstWhere((c) => c.id == id).name;
    } catch (_) {
      ctrl.text = '';
    }
  }

  void _updateDateText(DateTime date) {
    _dateCtrl.text = DateFormat('dd.MM.yyyy').format(date);
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

  void _openCategoryPicker(CategoryType type, TextEditingController ctrl) {
    FocusScope.of(context).unfocus();
    final catProv = context.read<CategoryProvider>();
    final colors = Theme.of(context).extension<AppColorsExtension>()!;
    final list = type == CategoryType.account
        ? catProv.accounts
        : catProv.expenses;
    final title = type == CategoryType.account
        ? 'write_off_from'.tr()
        : 'expense_category'.tr();
    final currentId = type == CategoryType.account
        ? _selectedAccountId
        : _selectedExpenseId;

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
                title,
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
                  itemCount: list.length,
                  itemBuilder: (context, index) {
                    final cat = list[index];
                    bool isSelected = currentId == cat.id;

                    return ListTile(
                      onTap: () {
                        setState(() {
                          if (type == CategoryType.account) {
                            _selectedAccountId = cat.id;
                            _showAccountError = false;
                          } else {
                            _selectedExpenseId = cat.id;
                            _showExpenseError = false;
                          }
                          _updateCategoryText(ctrl, list, cat.id);
                        });
                        Navigator.pop(ctx);
                      },
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      leading: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: cat.bgColor,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(cat.icon, size: 18, color: cat.iconColor),
                      ),
                      title: Text(
                        cat.name,
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

  void _openPeriodicityPicker() {
    FocusScope.of(context).unfocus();
    final colors = Theme.of(context).extension<AppColorsExtension>()!;
    final options = {
      'monthly': 'period_monthly'.tr(),
      'yearly': 'period_yearly'.tr(),
      'weekly': 'period_weekly'.tr(),
    };

    showModalBottomSheet(
      context: context,
      backgroundColor: colors.cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
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
              'period'.tr(),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: colors.textMain,
              ),
            ),
            const SizedBox(height: 10),
            ...options.entries.map((entry) {
              bool isSelected = _selectedPeriodicity == entry.key;
              return ListTile(
                onTap: () {
                  setState(() {
                    _selectedPeriodicity = entry.key;
                    _updatePeriodicityText(entry.key);
                  });
                  Navigator.pop(ctx);
                },
                title: Text(
                  entry.value,
                  style: TextStyle(
                    color: isSelected ? Colors.blueAccent : colors.textMain,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    fontSize: 16,
                  ),
                ),
                trailing: isSelected
                    ? const Icon(Icons.check, color: Colors.blueAccent)
                    : null,
              );
            }),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    FocusScope.of(context).unfocus();
    final picked = await showDialog<DateTime>(
      context: context,
      builder: (context) => CustomCalendarDialog(initialDate: _selectedDate),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _updateDateText(picked);
      });
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
                leading: const Icon(Icons.refresh, color: Colors.blueAccent),
                title: Text(
                  'use_category_icon'.tr(),
                  style: const TextStyle(
                    color: Colors.blueAccent,
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

  void _save() {
    FocusScope.of(context).unfocus();
    double amount =
        double.tryParse(_amountCtrl.text.replaceAll(',', '.')) ?? 0.0;

    setState(() {
      _showNameError = _nameCtrl.text.trim().isEmpty;
      _showAmountError = amount <= 0;
      _showAccountError = _selectedAccountId == null;
      _showExpenseError = _selectedExpenseId == null;
    });

    if (_showNameError ||
        _showAmountError ||
        _showAccountError ||
        _showExpenseError) {
      return;
    }

    final subProv = context.read<SubscriptionProvider>();
    final settings = context.read<SettingsProvider>();

    final newSub = Subscription(
      id:
          widget.subscription?.id ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameCtrl.text.trim(),
      amount: amount,
      categoryId: _selectedExpenseId!,
      accountId: _selectedAccountId!,
      nextPaymentDate: _selectedDate,
      periodicity: _selectedPeriodicity,
      customIconCodePoint: _customIconCodePoint,
      isAutoPay: _isAutoPay,
      currency: _selectedCurrency ?? settings.baseCurrency,
    );

    if (widget.subscription == null) {
      subProv.addSubscription(newSub);
    } else {
      subProv.updateSubscription(newSub);
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
                  ),
                  const SizedBox(height: 12),

                  // 👇 ВІДРЕДАГОВАНИЙ БЛОК З ЖИРНИМ ТЕКСТОМ
                  Builder(
                    builder: (context) {
                      final itemName = widget.subscription!.name;
                      final fullText = 'delete_subscription_message'.tr(
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
                                      color: colors
                                          .textMain, // Робимо колір яскравішим за основний текст
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

                  // 👆 КІНЕЦЬ ВІДРЕДАГОВАНОГО БЛОКУ
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
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
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
      context.read<SubscriptionProvider>().deleteSubscription(
        widget.subscription!.id,
      );
      Navigator.pop(context);
    }
  }

  // ДОПОМІЖНІ ВІДЖЕТИ ДЛЯ ПОЛІВ
  Widget _buildMaterialField({
    required TextEditingController controller,
    required String label,
    required AppColorsExtension colors,
    bool isError = false,
    bool isNumber = false,
  }) {
    final baseColor = isError ? Colors.red : colors.textSecondary;
    final activeColor = isError ? Colors.red : Colors.blueAccent;
    final underlineBaseColor = isError
        ? Colors.red
        : colors.textSecondary.withValues(alpha: 0.3);

    return TextField(
      controller: controller,
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
        labelStyle: TextStyle(color: baseColor, fontSize: 16),
        floatingLabelStyle: TextStyle(
          color: activeColor,
          fontSize: 14,
          fontWeight: FontWeight.bold,
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

  Widget _buildSelectorField({
    required TextEditingController controller,
    required String label,
    required AppColorsExtension colors,
    required VoidCallback onTap,
    bool isError = false,
    Widget? prefix,
  }) {
    final baseColor = isError ? Colors.red : colors.textSecondary;
    final activeColor = isError ? Colors.red : Colors.blueAccent;
    final underlineBaseColor = isError
        ? Colors.red
        : colors.textSecondary.withValues(alpha: 0.3);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: InputDecorator(
        // Це керує тим, чи опущений заголовок вниз, чи піднятий вгору
        isEmpty: controller.text.isEmpty && prefix == null,
        decoration: InputDecoration(
          filled: false,
          labelText: label,
          labelStyle: TextStyle(color: baseColor, fontSize: 16),
          floatingLabelStyle: TextStyle(
            color: activeColor,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
          prefix: prefix,
          suffixIcon: Padding(
            padding: const EdgeInsets.only(top: 16.0),
            child: Icon(Icons.keyboard_arrow_down, color: colors.textSecondary),
          ),
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
        // МАГІЯ ТУТ:
        child: Stack(
          alignment: Alignment.centerLeft,
          children: [
            // 1. Невидимий каркас.
            // Літери 'W' та 'j' мають найбільшу висоту (вгору і вниз),
            // тому вони гарантують ідеальну базову лінію поля (як у сусіднього TextField).
            const Text(
              'Wj',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.transparent,
              ),
            ),
            // 2. Реальний текст.
            // Він стиснеться, якщо не влазить, але завдяки Positioned.fill
            // це ніяк не вплине на висоту самого поля.
            Positioned.fill(
              child: Align(
                alignment: Alignment.centerLeft,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    controller.text,
                    style: TextStyle(
                      color: colors.textMain,
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColorsExtension>()!;
    final catProv = context.watch<CategoryProvider>();
    final isEditing = widget.subscription != null;

    final currencySymbol = AppCurrency.fromCode(
      _selectedCurrency ?? 'UAH',
    ).symbol;

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
          final cat = catProv.expenses.firstWhere(
            (c) => c.id == _selectedExpenseId,
          );
          displayColor = cat.bgColor;
          displayIconColor = cat.iconColor;
        } catch (_) {}
      }
    } else if (_selectedExpenseId != null) {
      try {
        final cat = catProv.expenses.firstWhere(
          (c) => c.id == _selectedExpenseId,
        );
        displayIcon = cat.icon;
        displayColor = cat.bgColor;
        displayIconColor = cat.iconColor;
      } catch (_) {}
    }

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
                    isEditing ? 'edit'.tr() : 'new_subscription'.tr(),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: colors.textMain,
                    ),
                  ),
                  Row(
                    children: [
                      if (isEditing)
                        IconButton(
                          icon: Icon(
                            Icons.delete_outline,
                            color: colors.expense,
                            size: 26,
                          ),
                          onPressed: _delete,
                        ),
                      IconButton(
                        icon: const Icon(
                          Icons.check,
                          color: Colors.blueAccent,
                          size: 28,
                        ),
                        onPressed: _save,
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
                    // КРУГЛЕ ПРЕВ'Ю ІКОНКИ
                    GestureDetector(
                      onTap: _openIconPicker,
                      child: Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: displayColor,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: displayColor.withValues(alpha: 0.3),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Icon(
                              displayIcon,
                              color: displayIconColor,
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

                    // 1. НАЗВА
                    _buildMaterialField(
                      controller: _nameCtrl,
                      label: 'name_hint_netflix'.tr(),
                      colors: colors,
                      isError: _showNameError,
                    ),
                    const SizedBox(height: 16),

                    // 2. СУМА ТА ВАЛЮТА (в один рядок, 50/50, поміняли місцями)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          // Сума зліва
                          child: _buildMaterialField(
                            controller: _amountCtrl,
                            label: 'amount'.tr(),
                            colors: colors,
                            isNumber: true,
                            isError: _showAmountError,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          // Валюта справа
                          child: _buildSelectorField(
                            controller: _currencyCtrl,
                            label: 'currency'.tr(),
                            colors: colors,
                            onTap: _openCurrencyPicker,
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
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // 3. ДАТА ТА ПЕРІОДИЧНІСТЬ (в один рядок, 50/50, поміняли місцями)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          // Дата зліва
                          child: TextField(
                            controller: _dateCtrl,
                            readOnly: true,
                            onTap: _pickDate,
                            // ПОВЕРНУЛИ ідеальний розмір 18
                            style: TextStyle(
                              color: colors.textMain,
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                            ),
                            decoration: InputDecoration(
                              filled: false,
                              labelText: 'payment'.tr(),
                              labelStyle: TextStyle(
                                color: colors.textSecondary,
                                fontSize: 16,
                              ),
                              floatingLabelStyle: const TextStyle(
                                color: Colors.blueAccent,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                              suffixIcon: Padding(
                                padding: const EdgeInsets.only(top: 16.0),
                                child: Icon(
                                  Icons.calendar_today,
                                  color: colors.textSecondary,
                                  size: 20,
                                ),
                              ),
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
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          // Період справа (тепер використовує розумний FittedBox з розміром 18)
                          child: _buildSelectorField(
                            controller: _periodicityCtrl,
                            label: 'period'.tr(),
                            colors: colors,
                            onTap: _openPeriodicityPicker,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // 4. ЗВІДКИ
                    _buildSelectorField(
                      controller: _accountCtrl,
                      label: 'write_off_from'.tr(),
                      colors: colors,
                      isError: _showAccountError,
                      onTap: () => _openCategoryPicker(
                        CategoryType.account,
                        _accountCtrl,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 5. КУДИ (КАТЕГОРІЯ ВИТРАТ)
                    _buildSelectorField(
                      controller: _expenseCtrl,
                      label: 'expense_category'.tr(),
                      colors: colors,
                      isError: _showExpenseError,
                      onTap: () => _openCategoryPicker(
                        CategoryType.expense,
                        _expenseCtrl,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // 6. АВТОСПИСАННЯ
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        'auto_pay'.tr(),
                        style: TextStyle(
                          color: colors.textMain,
                          fontWeight: FontWeight.w500,
                          fontSize: 16,
                        ),
                      ),
                      value: _isAutoPay,
                      activeThumbColor: Colors.blueAccent,
                      onChanged: (val) => setState(() => _isAutoPay = val),
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
}
