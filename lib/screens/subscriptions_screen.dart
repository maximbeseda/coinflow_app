import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/finance_provider.dart';
import '../models/subscription_model.dart';
import '../models/category_model.dart';
import '../utils/currency_formatter.dart';
import '../widgets/dialogs/custom_calendar_dialog.dart';

class SubscriptionsScreen extends StatelessWidget {
  const SubscriptionsScreen({super.key});

  void _showSubscriptionDialog(
    BuildContext context, {
    Subscription? subscription,
  }) {
    showDialog(
      context: context,
      builder: (context) => SubscriptionFormDialog(subscription: subscription),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<FinanceProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Регулярні платежі',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: ElevatedButton(
              onPressed: () => _showSubscriptionDialog(context),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 56),
                backgroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 4,
                shadowColor: Colors.black.withValues(alpha: 0.2),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_circle_outline, color: Colors.white),
                  SizedBox(width: 8),
                  Text(
                    'Додати підписку',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: provider.subscriptions.isEmpty
                ? const Center(
                    child: Text(
                      'У вас ще немає регулярних платежів',
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                  )
                : ListView.builder(
                    itemCount: provider.subscriptions.length,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 8,
                    ),
                    itemBuilder: (context, index) {
                      final sub = provider.subscriptions[index];

                      final category = provider.expenses.firstWhere(
                        (c) => c.id == sub.categoryId,
                        orElse: () => Category(
                          id: '',
                          type: CategoryType.expense,
                          name: 'Невідомо',
                          icon: Icons.help_outline,
                          bgColor: Colors.grey.shade200,
                          iconColor: Colors.black54,
                        ),
                      );

                      final displayIcon = sub.customIconCodePoint != null
                          ? IconData(
                              sub.customIconCodePoint!,
                              fontFamily: 'MaterialIcons',
                            )
                          : category.icon;

                      // --- НОВА ЛОГІКА: Перевіряємо, чи підписка прострочена ---
                      final now = DateTime.now();
                      final today = DateTime(now.year, now.month, now.day);
                      final paymentDate = DateTime(
                        sub.nextPaymentDate.year,
                        sub.nextPaymentDate.month,
                        sub.nextPaymentDate.day,
                      );
                      final isDue =
                          paymentDate.isBefore(today) ||
                          paymentDate.isAtSameMomentAs(today);
                      // --------------------------------------------------------

                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(24),
                            onTap: () => _showSubscriptionDialog(
                              context,
                              subscription: sub,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        width: 50,
                                        height: 50,
                                        decoration: BoxDecoration(
                                          color: category.bgColor,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          displayIcon,
                                          color: category.iconColor,
                                          size: 24,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              sub.name,
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.black87,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 4),
                                            Row(
                                              children: [
                                                Icon(
                                                  Icons.event,
                                                  size: 14,
                                                  color: isDue
                                                      ? Colors.red
                                                      : Colors
                                                            .grey, // Підсвічуємо іконку дати
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  DateFormat(
                                                    'dd.MM.yyyy',
                                                  ).format(sub.nextPaymentDate),
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w500,
                                                    color: isDue
                                                        ? Colors.red
                                                        : Colors
                                                              .grey
                                                              .shade600, // Підсвічуємо саму дату
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            "-${CurrencyFormatter.format(sub.amount)} ₴",
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w900,
                                              color: Color(0xFFE05252),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),

                                  // --- НОВИЙ БЛОК: Кнопка ручної оплати, якщо прострочено ---
                                  if (isDue) ...[
                                    const SizedBox(height: 12),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.red.withValues(
                                          alpha: 0.05,
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: Colors.red.withValues(
                                            alpha: 0.2,
                                          ),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          const Row(
                                            children: [
                                              Icon(
                                                Icons.warning_amber_rounded,
                                                color: Colors.red,
                                                size: 18,
                                              ),
                                              SizedBox(width: 6),
                                              Text(
                                                "Потребує оплати",
                                                style: TextStyle(
                                                  color: Colors.red,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 13,
                                                ),
                                              ),
                                            ],
                                          ),
                                          SizedBox(
                                            height: 32,
                                            child: ElevatedButton(
                                              style: ElevatedButton.styleFrom(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 16,
                                                    ),
                                                backgroundColor: Colors.red,
                                                foregroundColor: Colors.white,
                                                elevation: 0,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                              ),
                                              onPressed: () async {
                                                // Викликаємо оплату через Провайдер
                                                final (
                                                  success,
                                                  message,
                                                ) = await provider
                                                    .confirmSubscriptionPayment(
                                                      sub,
                                                      sub.amount,
                                                    );

                                                if (!context.mounted) return;

                                                // Показуємо наш фірмовий SnackBar
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  SnackBar(
                                                    backgroundColor:
                                                        Colors.white,
                                                    behavior: SnackBarBehavior
                                                        .floating,
                                                    margin:
                                                        const EdgeInsets.only(
                                                          bottom: 30,
                                                          left: 20,
                                                          right: 20,
                                                        ),
                                                    elevation: 10,
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            16,
                                                          ),
                                                      side: BorderSide(
                                                        color: success
                                                            ? Colors.green
                                                                  .withValues(
                                                                    alpha: 0.5,
                                                                  )
                                                            : Colors.red
                                                                  .withValues(
                                                                    alpha: 0.5,
                                                                  ),
                                                      ),
                                                    ),
                                                    content: Row(
                                                      children: [
                                                        Container(
                                                          padding:
                                                              const EdgeInsets.all(
                                                                8,
                                                              ),
                                                          decoration: BoxDecoration(
                                                            color: success
                                                                ? Colors.green
                                                                      .withValues(
                                                                        alpha:
                                                                            0.1,
                                                                      )
                                                                : Colors.red
                                                                      .withValues(
                                                                        alpha:
                                                                            0.1,
                                                                      ),
                                                            shape:
                                                                BoxShape.circle,
                                                          ),
                                                          child: Icon(
                                                            success
                                                                ? Icons
                                                                      .check_circle_outline
                                                                : Icons
                                                                      .error_outline,
                                                            color: success
                                                                ? Colors.green
                                                                : Colors.red,
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                          width: 12,
                                                        ),
                                                        Expanded(
                                                          child: Text(
                                                            message,
                                                            style:
                                                                const TextStyle(
                                                                  color: Colors
                                                                      .black87,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w600,
                                                                ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                );
                                              },
                                              child: const Text(
                                                "Сплатити",
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                  // ---------------------------------------------------------
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// ВІДЖЕТ ДІАЛОГОВОГО ВІКОНЦЯ (ФОРМА ДОДАВАННЯ ТА РЕДАГУВАННЯ)
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

  final Map<String, List<IconData>> _groupedIcons = {
    "Підписки та Сервіси": [
      Icons.play_circle_outline,
      Icons.music_note,
      Icons.cloud_queue,
      Icons.videogame_asset,
      Icons.fitness_center,
      Icons.language,
      Icons.shopping_bag,
      Icons.article,
      Icons.phone_iphone,
      Icons.security,
      Icons.subscriptions,
      Icons.ondemand_video,
    ],
    "Фінанси та Інвестиції": [
      Icons.account_balance_wallet,
      Icons.wallet,
      Icons.account_balance,
      Icons.savings,
      Icons.credit_card,
      Icons.show_chart,
      Icons.candlestick_chart,
      Icons.pie_chart,
      Icons.trending_up,
      Icons.atm,
      Icons.percent,
      Icons.real_estate_agent,
      Icons.receipt_long,
      Icons.business_center,
      Icons.money,
    ],
    "Валюти": [
      Icons.attach_money,
      Icons.euro,
      Icons.currency_pound,
      Icons.currency_yen,
      Icons.currency_franc,
      Icons.currency_lira,
      Icons.currency_rupee,
      Icons.currency_bitcoin,
      Icons.payments,
      Icons.price_change,
    ],
    "Їжа та напої": [
      Icons.shopping_bag,
      Icons.shopping_cart,
      Icons.restaurant,
      Icons.coffee,
      Icons.fastfood,
      Icons.local_bar,
      Icons.cake,
      Icons.local_pizza,
      Icons.liquor,
      Icons.icecream,
    ],
    "Транспорт та Авто": [
      Icons.directions_car,
      Icons.local_gas_station,
      Icons.build,
      Icons.local_parking,
      Icons.directions_bus,
      Icons.train,
      Icons.flight,
      Icons.local_taxi,
      Icons.two_wheeler,
      Icons.directions_boat,
    ],
    "Дім та Рахунки": [
      Icons.home,
      Icons.water_drop,
      Icons.electric_bolt,
      Icons.wifi,
      Icons.phone_android,
      Icons.tv,
      Icons.cleaning_services,
      Icons.lightbulb,
      Icons.router,
      Icons.weekend,
    ],
    "Шопінг та Речі": [
      Icons.checkroom,
      Icons.devices,
      Icons.headphones,
      Icons.watch,
      Icons.chair,
      Icons.local_mall,
      Icons.card_giftcard,
      Icons.local_shipping,
      Icons.smartphone,
      Icons.laptop_mac,
    ],
    "Здоров'я та Краса": [
      Icons.medical_services,
      Icons.fitness_center,
      Icons.spa,
      Icons.self_improvement,
      Icons.medication,
      Icons.local_hospital,
      Icons.face,
      Icons.content_cut,
      Icons.favorite,
      Icons.healing,
    ],
    "Розваги та Хобі": [
      Icons.theater_comedy,
      Icons.movie,
      Icons.music_note,
      Icons.videogame_asset,
      Icons.sports_esports,
      Icons.menu_book,
      Icons.palette,
      Icons.camera_alt,
      Icons.pool,
      Icons.subscriptions,
    ],
    "Сім'я та Тварини": [
      Icons.pets,
      Icons.child_friendly,
      Icons.school,
      Icons.groups,
      Icons.person,
      Icons.accessibility_new,
      Icons.people,
      Icons.stroller,
      Icons.sentiment_satisfied,
      Icons.cruelty_free,
    ],
    "Інше": [
      Icons.public,
      Icons.local_laundry_service,
      Icons.security,
      Icons.work,
      Icons.help_outline,
      Icons.star,
      Icons.folder,
      Icons.push_pin,
      Icons.explore,
      Icons.bookmark,
    ],
  };

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
                    for (var entry in _groupedIcons.entries) ...[
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
