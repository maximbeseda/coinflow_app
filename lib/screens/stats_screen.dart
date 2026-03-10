import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:easy_localization/easy_localization.dart';
import '../providers/category_provider.dart';
import '../providers/transaction_provider.dart';
import '../utils/currency_formatter.dart';
import '../widgets/dialogs/month_picker_dialog.dart';
import '../models/category_model.dart';
import '../theme/app_colors_extension.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  bool _showExpenses = true;

  final List<Color> _appCustomPalette = [
    const Color(0xFF2C3E50),
    const Color(0xFFE74C3C),
    const Color(0xFF27AE60),
    const Color(0xFF2980B9),
    const Color(0xFF8E44AD),
    const Color(0xFFF39C12),
    const Color(0xFF16A085),
    const Color(0xFFD35400),
    const Color(0xFF34495E),
    const Color(0xFFC0392B),
    const Color(0xFF1ABC9C),
    const Color(0xFF9B59B6),
    const Color(0xFFF1C40F),
    const Color(0xFFE67E22),
    const Color(0xFF3498DB),
    const Color(0xFF95A5A6),
    const Color(0xFF7F8C8D),
    const Color(0xFF2ECC71),
    const Color(0xFF4A6572),
    const Color(0xFF8D6E63),
    const Color(0xFF5D4037),
    const Color(0xFF009688),
    const Color(0xFF3F51B5),
    const Color(0xFFE91E63),
  ];

  Color _getUniqueColor(String id, CategoryProvider catProv) {
    // ВИПРАВЛЕНО: Використовуємо всі категорії для генерації кольору
    List<String> allIds = catProv.allCategoriesList
        .where(
          (c) =>
              c.type == CategoryType.expense || c.type == CategoryType.income,
        )
        .map((e) => e.id)
        .toList();

    allIds.sort();
    int index = allIds.indexOf(id);
    if (index == -1) index = 0;
    return _appCustomPalette[index % _appCustomPalette.length];
  }

  String _getMonthName(DateTime date, BuildContext context) {
    final languageCode = context.locale.languageCode;
    String month = DateFormat.MMMM(languageCode).format(date);
    month = month[0].toUpperCase() + month.substring(1);
    return "$month ${date.year}";
  }

  @override
  Widget build(BuildContext context) {
    final catProv = context.watch<CategoryProvider>();
    final txProv = context.watch<TransactionProvider>();
    final colors = Theme.of(context).extension<AppColorsExtension>()!;

    final monthHistory = txProv.history
        .where(
          (t) =>
              t.date.year == txProv.selectedMonth.year &&
              t.date.month == txProv.selectedMonth.month,
        )
        .toList();

    // ВИПРАВЛЕНО: Тепер ми беремо ВСІ категорії, включаючи архівні
    final allCategories = catProv.allCategoriesList;

    final Map<String, Category> categoryMap = {
      for (var c in allCategories) c.id: c,
    };

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

    // ВИПРАВЛЕНО: Збираємо список витрат із ВСІХ категорій
    final activeExpenses = catProv.allCategoriesList
        .where(
          (c) =>
              c.type == CategoryType.expense &&
              expenseTotals.containsKey(c.id) &&
              expenseTotals[c.id]! > 0,
        )
        .map((c) => c.copyWith(amount: expenseTotals[c.id]!))
        .toList();

    activeExpenses.sort((a, b) => b.amount.abs().compareTo(a.amount.abs()));
    double totalExpenses = activeExpenses.fold(
      0,
      (sum, item) => sum + item.amount.abs(),
    );

    // ВИПРАВЛЕНО: Збираємо список доходів із ВСІХ категорій
    final activeIncomes = catProv.allCategoriesList
        .where(
          (c) =>
              c.type == CategoryType.income &&
              incomeTotals.containsKey(c.id) &&
              incomeTotals[c.id]! > 0,
        )
        .map((c) => c.copyWith(amount: incomeTotals[c.id]!))
        .toList();

    activeIncomes.sort((a, b) => b.amount.abs().compareTo(a.amount.abs()));
    double totalIncomes = activeIncomes.fold(
      0,
      (sum, item) => sum + item.amount.abs(),
    );

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
            colors: [colors.bgGradientStart, colors.bgGradientEnd],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 8.0, top: 4.0, right: 8.0),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.arrow_back, color: colors.textMain),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Expanded(
                      child: Text(
                        'statistics'.tr(),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: colors.textMain,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: Icon(Icons.chevron_left, color: colors.textMain),
                      onPressed: () => txProv.changeMonth(-1),
                    ),
                    GestureDetector(
                      onTap: () async {
                        final pickedDate = await showDialog<DateTime>(
                          context: context,
                          builder: (ctx) => MonthPickerDialog(
                            initialDate: txProv.selectedMonth,
                          ),
                        );
                        if (pickedDate != null && mounted) {
                          txProv.setMonth(pickedDate);
                        }
                      },
                      child: Container(
                        constraints: BoxConstraints(
                          minWidth: 130,
                          maxWidth: MediaQuery.of(context).size.width * 0.45,
                        ),
                        padding: const EdgeInsets.symmetric(
                          vertical: 6,
                          horizontal: 8,
                        ),
                        decoration: BoxDecoration(
                          color: colors.cardBg,
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
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            _getMonthName(txProv.selectedMonth, context),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: colors.textMain,
                            ),
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.chevron_right, color: colors.textMain),
                      onPressed: () => txProv.changeMonth(1),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24.0,
                  vertical: 8.0,
                ),
                child: Container(
                  height: 60,
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: colors.cardBg,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
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
                              color: colors.iconBg,
                              borderRadius: BorderRadius.circular(16),
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
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'stats_expenses'.tr(),
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: _showExpenses
                                            ? colors.textMain
                                            : colors.textSecondary,
                                        fontWeight: FontWeight.w700,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      "${CurrencyFormatter.format(totalExpenses)} ₴",
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w900,
                                        color: _showExpenses
                                            ? colors.expense
                                            : colors.textSecondary.withAlpha(
                                                80,
                                              ),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () =>
                                  setState(() => _showExpenses = false),
                              behavior: HitTestBehavior.opaque,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'income'.tr(),
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: !_showExpenses
                                            ? colors.textMain
                                            : colors.textSecondary,
                                        fontWeight: FontWeight.w700,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      "${CurrencyFormatter.format(totalIncomes)} ₴",
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w900,
                                        color: !_showExpenses
                                            ? colors.income
                                            : colors.textSecondary.withAlpha(
                                                80,
                                              ),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
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
              Expanded(
                child: Container(
                  width: double.infinity,
                  margin: const EdgeInsets.fromLTRB(24, 4, 24, 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colors.cardBg,
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
                                ? 'no_expenses_month'.tr()
                                : 'no_incomes_month'.tr(),
                            style: TextStyle(
                              fontSize: 16,
                              color: colors.textSecondary,
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
                                      catProv,
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
                                    catProv,
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
                                            style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 14,
                                              color: colors.textMain,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          "${percentage.toStringAsFixed(1)}%",
                                          style: TextStyle(
                                            color: colors.textSecondary,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Text(
                                          "${CurrencyFormatter.format(cat.amount.abs())} ₴",
                                          style: TextStyle(
                                            fontWeight: FontWeight.w800,
                                            fontSize: 14,
                                            color: colors.textMain,
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
