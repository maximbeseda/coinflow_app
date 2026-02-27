import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/finance_provider.dart';
import '../utils/currency_formatter.dart';
import '../widgets/dialogs/month_picker_dialog.dart';
import '../models/category_model.dart'; // ДОДАНО: Для роботи з Category та CategoryType

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  bool _showExpenses = true;

  final List<Color> _appCustomPalette = [
    const Color(0xFF2C3E50), // Темний графіт
    const Color(0xFFE74C3C), // Яскравий червоний
    const Color(0xFF27AE60), // Соковитий зелений
    const Color(0xFF2980B9), // Синій океан
    const Color(0xFF8E44AD), // Насичений фіолетовий
    const Color(0xFFF39C12), // Теплий помаранчевий
    const Color(0xFF16A085), // Темна бірюза
    const Color(0xFFD35400), // Темний апельсин
    const Color(0xFF34495E), // Мокрий асфальт
    const Color(0xFFC0392B), // Темно-червоний
    const Color(0xFF1ABC9C), // Світла бірюза
    const Color(0xFF9B59B6), // М'який бузок
    const Color(0xFFF1C40F), // М'який золотий
    const Color(0xFFE67E22), // Теракотовий
    const Color(0xFF3498DB), // Світло-синій
    const Color(0xFF95A5A6), // Світлий графіт
    const Color(0xFF7F8C8D), // Холодний сірий
    const Color(0xFF2ECC71), // Салатовий
    const Color(0xFF4A6572), // Сизій
    const Color(0xFF8D6E63), // Кавовий
    const Color(0xFF5D4037), // Темний шоколад
    const Color(0xFF009688), // Чайне дерево
    const Color(0xFF3F51B5), // Індиго
    const Color(0xFFE91E63), // Малиновий
  ];

  // НОВИЙ ПІДХІД: 100% унікальні кольори на основі часу створення категорії
  Color _getUniqueColor(String id, FinanceProvider provider) {
    // Збираємо всі ID категорій до купи
    List<String> allIds = [
      ...provider.expenses.map((e) => e.id),
      ...provider.incomes.map((e) => e.id),
    ];

    // Оскільки в твоєму ID зашитий час (напр. exp_1708...),
    // сортування автоматично вибудує їх у хронологічному порядку!
    allIds.sort();

    int index = allIds.indexOf(id);
    if (index == -1) index = 0; // Захист від помилок

    return _appCustomPalette[index % _appCustomPalette.length];
  }

  String _getMonthName(DateTime date) {
    const months = [
      'Січень',
      'Лютий',
      'Березень',
      'Квітень',
      'Травень',
      'Червень',
      'Липень',
      'Серпень',
      'Вересень',
      'Жовтень',
      'Листопад',
      'Грудень',
    ];
    return "${months[date.month - 1]} ${date.year}";
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FinanceProvider>();
    final colorBlueGrey = const Color(0xFFD1D9E6);

    // --- ДИНАМІЧНИЙ ПІДРАХУНОК ДЛЯ СТАТИСТИКИ ---
    // 1. Отримуємо історію ТІЛЬКИ для вибраного місяця
    final monthHistory = provider.history
        .where(
          (t) =>
              t.date.year == provider.selectedMonth.year &&
              t.date.month == provider.selectedMonth.month,
        )
        .toList();

    final allCategories = [
      ...provider.incomes,
      ...provider.accounts,
      ...provider.expenses,
    ];
    final Map<String, Category> categoryMap = {
      for (var c in allCategories) c.id: c,
    };

    // 2. Рахуємо суми "на льоту" локально
    final Map<String, double> expenseTotals = {};
    final Map<String, double> incomeTotals = {};

    for (var t in monthHistory) {
      final fromCat = categoryMap[t.fromId];
      final toCat = categoryMap[t.toId];

      if (toCat != null && toCat.type == CategoryType.expense) {
        expenseTotals[t.toId] = (expenseTotals[t.toId] ?? 0) + t.amount;
      }
      if (fromCat != null && fromCat.type == CategoryType.income) {
        incomeTotals[t.fromId] = (incomeTotals[t.fromId] ?? 0) + t.amount;
      }
    }

    // 3. Створюємо віртуальні списки для графіка (без зміни оригіналів)
    final activeExpenses = provider.expenses
        .where(
          (c) => expenseTotals.containsKey(c.id) && expenseTotals[c.id]! > 0,
        )
        .map(
          (c) => Category(
            id: c.id,
            type: c.type,
            name: c.name,
            icon: c.icon,
            bgColor: c.bgColor,
            iconColor: c.iconColor,
            amount: expenseTotals[c.id]!,
          ),
        )
        .toList();
    activeExpenses.sort((a, b) => b.amount.abs().compareTo(a.amount.abs()));
    double totalExpenses = activeExpenses.fold(
      0,
      (sum, item) => sum + item.amount.abs(),
    );

    final activeIncomes = provider.incomes
        .where((c) => incomeTotals.containsKey(c.id) && incomeTotals[c.id]! > 0)
        .map(
          (c) => Category(
            id: c.id,
            type: c.type,
            name: c.name,
            icon: c.icon,
            bgColor: c.bgColor,
            iconColor: c.iconColor,
            amount: incomeTotals[c.id]!,
          ),
        )
        .toList();
    activeIncomes.sort((a, b) => b.amount.abs().compareTo(a.amount.abs()));
    double totalIncomes = activeIncomes.fold(
      0,
      (sum, item) => sum + item.amount.abs(),
    );
    // --- КІНЕЦЬ ДИНАМІЧНОГО ПІДРАХУНКУ ---

    final activeData = _showExpenses ? activeExpenses : activeIncomes;
    final activeTotal = _showExpenses ? totalExpenses : totalIncomes;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [colorBlueGrey, const Color(0xFFF5F5F7)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // --- ШАПКА ---
              Padding(
                padding: const EdgeInsets.only(left: 8.0, top: 4.0, right: 8.0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.black87),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Expanded(
                      child: Text(
                        "Статистика",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),

              // --- ПЕРЕМИКАЧ МІСЯЦІВ (Компактний) ---
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 0.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.chevron_left,
                        color: Colors.black87,
                      ),
                      onPressed: () => provider.changeMonth(-1),
                    ),
                    GestureDetector(
                      onTap: () async {
                        final pickedDate = await showDialog<DateTime>(
                          context: context,
                          builder: (ctx) => MonthPickerDialog(
                            initialDate: provider.selectedMonth,
                          ),
                        );
                        if (pickedDate != null && mounted) {
                          provider.setMonth(pickedDate);
                        }
                      },
                      child: Container(
                        // ДОДАНО: Динамічна ширина замість жорстких 160 пікселів
                        constraints: BoxConstraints(
                          minWidth:
                              130, // Мінімальна ширина, щоб кнопки не стрибали на коротких словах (напр. "Травень")
                          maxWidth:
                              MediaQuery.of(context).size.width *
                              0.45, // Не більше 45% ширини екрану
                        ),
                        padding: const EdgeInsets.symmetric(
                          vertical: 6,
                          horizontal: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(10),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        alignment: Alignment.center,
                        // ДОДАНО: FittedBox гарантує, що якщо текст буде задовгим для маленького екрану,
                        // він елегантно зменшить шрифт, а не зламає верстку
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            _getMonthName(provider.selectedMonth),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.chevron_right,
                        color: Colors.black87,
                      ),
                      onPressed: () => provider.changeMonth(1),
                    ),
                  ],
                ),
              ),

              // --- СЛАЙДЕР ВИТРАТИ / ДОХОДИ (Компактний) ---
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24.0,
                  vertical: 8.0,
                ),
                child: Container(
                  height: 60,
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white, // Був чорний з альфою
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      // ДОДАЛИ ТІНЬ
                      BoxShadow(
                        color: Colors.black.withAlpha(10),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      AnimatedAlign(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOutCubic,
                        alignment: _showExpenses
                            ? Alignment.centerLeft
                            : Alignment.centerRight,
                        child: FractionallySizedBox(
                          widthFactor: 0.5,
                          heightFactor: 1.0,
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFFE5E5EA,
                              ), // Легкий сірий фон, щоб повзунок виділявся
                              borderRadius: BorderRadius.circular(16),
                              // Видалили внутрішню тінь, бо тепер є зовнішня
                            ),
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => _showExpenses = true),
                              behavior: HitTestBehavior.opaque,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    "Витрати",
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: _showExpenses
                                          ? Colors.black54
                                          : Colors.black38,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  Text(
                                    "${CurrencyFormatter.format(totalExpenses)} ₴",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w900,
                                      color: _showExpenses
                                          ? const Color(0xFFE05252)
                                          : Colors.black26,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () =>
                                  setState(() => _showExpenses = false),
                              behavior: HitTestBehavior.opaque,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    "Доходи",
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: !_showExpenses
                                          ? Colors.black54
                                          : Colors.black38,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  Text(
                                    "${CurrencyFormatter.format(totalIncomes)} ₴",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w900,
                                      color: !_showExpenses
                                          ? const Color(0xFF4CAF50)
                                          : Colors.black26,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // --- КРУГОВИЙ ГРАФІК ---
              Expanded(
                child: Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(
                    left: 24,
                    right: 24,
                    bottom: 16,
                    top: 4,
                  ),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(10),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: activeData.isEmpty
                      ? Center(
                          child: Text(
                            _showExpenses
                                ? "Немає витрат у цьому місяці 👏"
                                : "Немає доходів у цьому місяці 😔",
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                      : Column(
                          children: [
                            Expanded(
                              flex: 5,
                              child: PieChart(
                                PieChartData(
                                  sectionsSpace: 2,
                                  centerSpaceRadius: 38,
                                  sections: activeData.map((cat) {
                                    final value = cat.amount.abs();
                                    final percentage =
                                        (value / activeTotal) * 100;
                                    final sliceColor = _getUniqueColor(
                                      cat.id,
                                      provider,
                                    );

                                    final bool showTitle = percentage >= 5.0;

                                    return PieChartSectionData(
                                      color: sliceColor,
                                      value: value,
                                      title: showTitle
                                          ? "${percentage.toStringAsFixed(0)}%"
                                          : "",
                                      radius: 42,
                                      titlePositionPercentageOffset: 0.5,
                                      titleStyle: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white,
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            // --- ЛЕГЕНДА ---
                            Expanded(
                              flex: 7,
                              child: ListView.builder(
                                itemCount: activeData.length,
                                itemBuilder: (context, index) {
                                  final cat = activeData[index];
                                  final percentage =
                                      (cat.amount.abs() / activeTotal) * 100;
                                  final rowColor = _getUniqueColor(
                                    cat.id,
                                    provider,
                                  );

                                  return Padding(
                                    padding: const EdgeInsets.only(
                                      bottom: 12.0,
                                    ),
                                    child: Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 12,
                                          backgroundColor: rowColor.withAlpha(
                                            30,
                                          ),
                                          child: Icon(
                                            cat.icon,
                                            size: 14,
                                            color: rowColor,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            cat.name,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 14,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        Text(
                                          "${percentage.toStringAsFixed(1)}%",
                                          style: const TextStyle(
                                            color: Colors.black54,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Text(
                                          "${CurrencyFormatter.format(cat.amount.abs())} ₴",
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w800,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
