import 'dart:ui' as ui;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:easy_localization/easy_localization.dart';

import '../providers/all_providers.dart';

import '../models/app_currency.dart';
import '../utils/currency_formatter.dart';
import '../utils/date_formatter.dart';
import '../widgets/dialogs/month_picker_dialog.dart';
import '../database/app_database.dart';
import '../theme/app_colors_extension.dart';
import '../widgets/common/animated_dots.dart';

class StatsScreen extends ConsumerStatefulWidget {
  const StatsScreen({super.key});

  @override
  ConsumerState<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends ConsumerState<StatsScreen> {
  bool _showExpenses = true;
  bool _showTrends = false;
  late DateTime _statsMonth;
  bool _animatingForward = true;
  DateTime _lastSwipeTime = DateTime.now();

  int _touchedPieIndex = -1;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _statsMonth = DateTime(now.year, now.month, 1);
  }

  void _changeMonth(DateTime newMonth) {
    if (newMonth == _statsMonth) return;
    final now = DateTime.now();
    if (now.difference(_lastSwipeTime).inMilliseconds < 400) return;
    _lastSwipeTime = now;

    setState(() {
      _animatingForward = newMonth.isAfter(_statsMonth);
      _statsMonth = newMonth;
      _touchedPieIndex = -1;
    });
  }

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

  List<Category> _getSortedActiveCategories(CategoryState catState) {
    final allCategories = catState.allCategoriesList;
    final Map<String, Category> categoryMap = {
      for (var c in allCategories) c.id: c,
    };

    final categoryTotals = ref
        .read(statsProvider.notifier)
        .calculateCategoryTotalsForMonth(_statsMonth, _showExpenses);

    List<Category> activeCategories = [];
    categoryTotals.forEach((categoryId, amountInBaseCurrency) {
      if (amountInBaseCurrency > 0 && categoryMap.containsKey(categoryId)) {
        activeCategories.add(
          categoryMap[categoryId]!.copyWith(amount: amountInBaseCurrency),
        );
      }
    });

    activeCategories.sort((a, b) => b.amount.abs().compareTo(a.amount.abs()));
    return activeCategories;
  }

  void _showCategoryTransactions(
    Category category,
    AppColorsExtension colors,
    String baseCurrencySymbol,
  ) async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return _StatsCategoryBottomSheet(
          category: category,
          statsMonth: _statsMonth,
          baseCurrencySymbol: baseCurrencySymbol,
          showExpenses: _showExpenses,
        );
      },
    );

    if (mounted) {
      setState(() {
        _touchedPieIndex = -1;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColorsExtension>()!;

    final settingsState = ref.watch(settingsProvider);
    final txState = ref.watch(transactionProvider);
    final catState = ref.watch(categoryProvider);

    final now = DateTime.now();
    final isCurrentMonth =
        _statsMonth.year == now.year && _statsMonth.month == now.month;

    String displayCurrency;

    if (isCurrentMonth) {
      displayCurrency = settingsState.baseCurrency;
    } else {
      final monthTxs = txState.history.where(
        (tx) =>
            tx.date.year == _statsMonth.year &&
            tx.date.month == _statsMonth.month,
      );
      if (monthTxs.isNotEmpty) {
        displayCurrency = monthTxs.first.baseCurrency;
      } else {
        displayCurrency = settingsState.baseCurrency;
      }
    }

    final baseCurrencySymbol = AppCurrency.fromCode(displayCurrency).symbol;

    // 👇 ОПТИМІЗАЦІЯ: Формуємо список ID один раз для швидкості кольорів (без сортування всередині білдера)
    final sortedCatIds =
        catState.allCategoriesList
            .where(
              (c) =>
                  c.type == CategoryType.expense ||
                  c.type == CategoryType.income,
            )
            .map((e) => e.id)
            .toList()
          ..sort();

    Color getUniqueColor(String id) {
      int index = sortedCatIds.indexOf(id);
      if (index == -1) index = 0;
      return _appCustomPalette[index % _appCustomPalette.length];
    }

    return Scaffold(
      backgroundColor: _showTrends ? colors.cardBg : null,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          color: _showTrends ? colors.cardBg : null,
          gradient: _showTrends
              ? null
              : LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [colors.bgGradientStart, colors.bgGradientEnd],
                ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(colors),
              if (!_showTrends) ...[
                _buildMonthSelector(colors),
                _buildTotalsToggle(colors, baseCurrencySymbol, txState),
              ],
              Expanded(
                child: _showTrends
                    ? _buildTrendsView(colors)
                    : _buildMonthlyPieView(
                        colors,
                        baseCurrencySymbol,
                        catState,
                        txState,
                        getUniqueColor, // Передаємо оптимізовану функцію
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(AppColorsExtension colors) {
    return Padding(
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
          IconButton(
            icon: Icon(
              _showTrends ? Icons.pie_chart_outline : Icons.auto_graph,
              color: colors.textMain,
            ),
            onPressed: () => setState(() => _showTrends = !_showTrends),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthSelector(AppColorsExtension colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: Icon(Icons.chevron_left, color: colors.textMain),
            onPressed: () => _changeMonth(
              DateTime(_statsMonth.year, _statsMonth.month - 1, 1),
            ),
          ),
          GestureDetector(
            onTap: () async {
              final pickedDate = await showDialog<DateTime>(
                context: context,
                builder: (ctx) => MonthPickerDialog(initialDate: _statsMonth),
              );
              if (pickedDate != null && mounted) _changeMonth(pickedDate);
            },
            child: Container(
              constraints: BoxConstraints(
                minWidth: 130,
                maxWidth: MediaQuery.of(context).size.width * 0.45,
              ),
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
              decoration: BoxDecoration(
                color: colors.cardBg,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  DateFormatter.formatMonthYear(
                    _statsMonth,
                    context.locale.languageCode,
                  ),
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
            onPressed: () => _changeMonth(
              DateTime(_statsMonth.year, _statsMonth.month + 1, 1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalsToggle(
    AppColorsExtension colors,
    String baseCurrencySymbol,
    TransactionState txState,
  ) {
    final allMonthTotals = ref
        .read(statsProvider.notifier)
        .calculateTotalsForMonth(_statsMonth);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
      child: Container(
        height: 60,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: colors.cardBg,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
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
              alignment: !_showExpenses
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
                _toggleItem(
                  'income'.tr(),
                  (allMonthTotals['incomes'] ?? 0).toInt(),
                  !txState.isMigrating,
                  !_showExpenses,
                  colors.income,
                  baseCurrencySymbol,
                  () {
                    setState(() {
                      _showExpenses = false;
                      _touchedPieIndex = -1;
                    });
                  },
                  colors,
                ),
                _toggleItem(
                  'stats_expenses'.tr(),
                  (allMonthTotals['expenses'] ?? 0).toInt(),
                  !txState.isMigrating,
                  _showExpenses,
                  colors.expense,
                  baseCurrencySymbol,
                  () {
                    setState(() {
                      _showExpenses = true;
                      _touchedPieIndex = -1;
                    });
                  },
                  colors,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _toggleItem(
    String label,
    int amount,
    bool isReady,
    bool isActive,
    Color activeColor,
    String symbol,
    VoidCallback onTap,
    AppColorsExtension colors,
  ) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: isActive ? colors.textMain : colors.textSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
            Stack(
              alignment: Alignment.center,
              children: [
                Opacity(
                  opacity: isReady ? 1.0 : 0.0,
                  child: Text(
                    "${CurrencyFormatter.format(amount)} $symbol",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: isActive
                          ? activeColor
                          : colors.textSecondary.withValues(alpha: 0.5),
                    ),
                  ),
                ),
                if (!isReady)
                  Positioned.fill(
                    child: Align(
                      alignment: Alignment.center,
                      child: AnimatedDots(
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: isActive
                              ? activeColor
                              : colors.textSecondary.withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrendsView(AppColorsExtension colors) {
    final trends = ref.read(statsProvider.notifier).calculateTrends();
    if (trends.isEmpty) {
      return Center(
        child: Text(
          'no_data'.tr(),
          style: TextStyle(color: colors.textSecondary),
        ),
      );
    }
    return _TrendsCarousel(trends: trends, colors: colors);
  }

  Widget _buildMonthlyPieView(
    AppColorsExtension colors,
    String baseCurrencySymbol,
    CategoryState catState,
    TransactionState txState,
    Color Function(String) getUniqueColor,
  ) {
    final activeData = _getSortedActiveCategories(catState);
    int activeTotal = activeData.fold(
      0,
      (sum, item) => sum + item.amount.abs().toInt(),
    );

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onHorizontalDragEnd: (details) {
        int sensitivity = 300;
        if (details.primaryVelocity != null) {
          if (details.primaryVelocity! < -sensitivity) {
            _changeMonth(DateTime(_statsMonth.year, _statsMonth.month + 1, 1));
          } else if (details.primaryVelocity! > sensitivity) {
            _changeMonth(DateTime(_statsMonth.year, _statsMonth.month - 1, 1));
          }
        }
      },
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (Widget child, Animation<double> animation) {
          final inFrom = _animatingForward
              ? const Offset(1.0, 0.0)
              : const Offset(-1.0, 0.0);
          final outTo = _animatingForward
              ? const Offset(-1.0, 0.0)
              : const Offset(1.0, 0.0);
          if (child.key == ValueKey(_statsMonth.toIso8601String())) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: inFrom,
                end: Offset.zero,
              ).animate(animation),
              child: child,
            );
          } else {
            return SlideTransition(
              position: Tween<Offset>(
                begin: outTo,
                end: Offset.zero,
              ).animate(animation),
              child: child,
            );
          }
        },
        child: Container(
          key: ValueKey(_statsMonth.toIso8601String()),
          width: double.infinity,
          margin: const EdgeInsets.fromLTRB(24, 4, 24, 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colors.cardBg,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
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
                          pieTouchData: PieTouchData(
                            touchCallback:
                                (FlTouchEvent event, pieTouchResponse) {
                                  setState(() {
                                    if (!event.isInterestedForInteractions ||
                                        pieTouchResponse == null ||
                                        pieTouchResponse.touchedSection ==
                                            null) {
                                      return;
                                    }
                                    _touchedPieIndex = pieTouchResponse
                                        .touchedSection!
                                        .touchedSectionIndex;
                                  });

                                  if (event is FlTapUpEvent &&
                                      _touchedPieIndex != -1) {
                                    final cat = activeData[_touchedPieIndex];
                                    _showCategoryTransactions(
                                      cat,
                                      colors,
                                      baseCurrencySymbol,
                                    );
                                  }
                                },
                          ),
                          sectionsSpace: 2,
                          centerSpaceRadius: 38,
                          sections: activeData.asMap().entries.map((entry) {
                            final index = entry.key;
                            final cat = entry.value;

                            final isTouched = index == _touchedPieIndex;
                            final value = cat.amount.abs() / 100.0;
                            final percentage =
                                (value / (activeTotal / 100.0)) * 100;

                            final radius = isTouched ? 48.0 : 42.0;

                            return PieChartSectionData(
                              color: getUniqueColor(cat.id),
                              value: value,
                              title: percentage >= 5.0
                                  ? "${percentage.toStringAsFixed(0)}%"
                                  : "",
                              radius: radius,
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
                          final rowColor = getUniqueColor(cat.id);
                          final isTouched = index == _touchedPieIndex;

                          return InkWell(
                            onTap: () {
                              setState(() => _touchedPieIndex = index);
                              _showCategoryTransactions(
                                cat,
                                colors,
                                baseCurrencySymbol,
                              );
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(
                                vertical: 8,
                                horizontal: 8,
                              ),
                              margin: const EdgeInsets.only(bottom: 4),
                              decoration: BoxDecoration(
                                color: isTouched
                                    ? rowColor.withValues(alpha: 0.1)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 14,
                                    backgroundColor: rowColor.withValues(
                                      alpha: 0.2,
                                    ),
                                    child: Icon(
                                      IconData(
                                        cat.icon,
                                        fontFamily: 'MaterialIcons',
                                      ),
                                      size: 16,
                                      color: rowColor,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      cat.name,
                                      style: TextStyle(
                                        fontWeight: isTouched
                                            ? FontWeight.w800
                                            : FontWeight.w600,
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
                                  Stack(
                                    alignment: Alignment.centerRight,
                                    children: [
                                      Opacity(
                                        opacity: txState.isMigrating
                                            ? 0.0
                                            : 1.0,
                                        child: Text(
                                          "${CurrencyFormatter.format(cat.amount.abs())} $baseCurrencySymbol",
                                          style: TextStyle(
                                            fontWeight: FontWeight.w800,
                                            fontSize: 14,
                                            color: colors.textMain,
                                          ),
                                        ),
                                      ),
                                      if (txState.isMigrating)
                                        Positioned.fill(
                                          child: Align(
                                            alignment: Alignment.centerRight,
                                            child: AnimatedDots(
                                              style: TextStyle(
                                                fontWeight: FontWeight.w800,
                                                fontSize: 14,
                                                color: colors.textMain,
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
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
}

class _StatsCategoryBottomSheet extends ConsumerStatefulWidget {
  final Category category;
  final DateTime statsMonth;
  final String baseCurrencySymbol;
  final bool showExpenses;

  const _StatsCategoryBottomSheet({
    required this.category,
    required this.statsMonth,
    required this.baseCurrencySymbol,
    required this.showExpenses,
  });

  @override
  ConsumerState<_StatsCategoryBottomSheet> createState() =>
      _StatsCategoryBottomSheetState();
}

class _StatsCategoryBottomSheetState
    extends ConsumerState<_StatsCategoryBottomSheet> {
  bool _isFetchingMore = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final filterNotifier = ref.read(filterProvider.notifier);
      filterNotifier.initForCategory(widget.category.id);

      final start = DateTime(
        widget.statsMonth.year,
        widget.statsMonth.month,
        1,
      );
      final end = DateTime(
        widget.statsMonth.year,
        widget.statsMonth.month + 1,
        0,
        23,
        59,
        59,
      );
      filterNotifier.setDateRange(start, end);
    });
  }

  String _fastDateFormat(DateTime d) {
    final day = d.day.toString().padLeft(2, '0');
    final month = d.month.toString().padLeft(2, '0');
    final hour = d.hour.toString().padLeft(2, '0');
    final minute = d.minute.toString().padLeft(2, '0');
    return '$day.$month.${d.year} $hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColorsExtension>()!;
    final filterState = ref.watch(filterProvider);
    final filteredTxs = filterState.results;
    final showLoader = filterState.hasMore;

    final allCategories = ref.watch(categoryProvider).allCategoriesList;
    final categoryMap = {for (var c in allCategories) c.id: c};

    // КЕШУЄМО ЛОКАЛІЗАЦІЮ
    final trUnknown = 'unknown'.tr();
    final trOutgoing = 'outgoing_transfer'.tr();
    final trTopUp = 'top_up'.tr();

    final Map<String, String> currencyCache = {};

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      builder: (_, controller) {
        return Container(
          decoration: BoxDecoration(
            color: colors.cardBg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.textSecondary.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: Color(widget.category.bgColor),
                      child: Icon(
                        IconData(
                          widget.category.icon,
                          fontFamily: 'MaterialIcons',
                        ),
                        color: Color(widget.category.iconColor),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.category.name,
                            style: TextStyle(
                              color: colors.textMain,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            DateFormatter.formatMonthYear(
                              widget.statsMonth,
                              context.locale.languageCode,
                            ),
                            style: TextStyle(
                              color: colors.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      "${CurrencyFormatter.format(widget.category.amount.abs())} ${widget.baseCurrencySymbol}",
                      style: TextStyle(
                        color: widget.showExpenses
                            ? colors.expense
                            : colors.income,
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Divider(
                height: 1,
                color: colors.textSecondary.withValues(alpha: 0.1),
              ),

              Expanded(
                child: filterState.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : filteredTxs.isEmpty
                    ? Center(
                        child: Text(
                          'no_data'.tr(),
                          style: TextStyle(color: colors.textSecondary),
                        ),
                      )
                    : NotificationListener<ScrollNotification>(
                        onNotification: (ScrollNotification scrollInfo) {
                          if (scrollInfo.metrics.pixels >=
                              scrollInfo.metrics.maxScrollExtent - 150) {
                            if (filterState.hasMore && !_isFetchingMore) {
                              _isFetchingMore = true;
                              ref
                                  .read(filterProvider.notifier)
                                  .loadNextPage()
                                  .then((_) {
                                    if (mounted) _isFetchingMore = false;
                                  });
                            }
                          }
                          return false;
                        },
                        child: ListView.builder(
                          controller: controller,
                          physics: const BouncingScrollPhysics(),
                          cacheExtent: 1000,
                          itemCount: filteredTxs.length + (showLoader ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index == filteredTxs.length) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 24.0,
                                ),
                                child: Center(
                                  child: SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: colors.textSecondary.withValues(
                                        alpha: 0.5,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }

                            final tx = filteredTxs[index];
                            final currencySymbol = currencyCache.putIfAbsent(
                              tx.currency,
                              () => AppCurrency.fromCode(tx.currency).symbol,
                            );

                            final fromCat = categoryMap[tx.fromId];
                            final toCat = categoryMap[tx.toId];

                            // 👇 ВИПРАВЛЕНО: Використовуємо змінні з кешу
                            String fromName = fromCat?.name ?? trUnknown;
                            String toName = toCat?.name ?? trUnknown;

                            String customNote = tx.title.trim();

                            // 👇 ВИПРАВЛЕНО: Використовуємо змінні з кешу
                            bool isDefaultTitle =
                                customNote.isEmpty ||
                                customNote.contains('➡️') ||
                                customNote == fromName ||
                                customNote == toName ||
                                customNote == trOutgoing ||
                                customNote == trTopUp;

                            if (isDefaultTitle) customNote = '';

                            final iconCat = widget.showExpenses
                                ? fromCat
                                : toCat;

                            return ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 4,
                              ),
                              leading: CircleAvatar(
                                backgroundColor: iconCat != null
                                    ? Color(iconCat.bgColor)
                                    : colors.iconBg,
                                child: Icon(
                                  iconCat != null
                                      ? IconData(
                                          iconCat.icon,
                                          fontFamily: 'MaterialIcons',
                                        )
                                      : Icons.help_outline,
                                  color: iconCat != null
                                      ? Color(iconCat.iconColor)
                                      : colors.textSecondary,
                                  size: 20,
                                ),
                              ),
                              title: Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      fromName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: colors.textMain,
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 4.0,
                                    ),
                                    child: Icon(
                                      Icons.arrow_forward,
                                      size: 14,
                                      color: colors.textSecondary,
                                    ),
                                  ),
                                  Flexible(
                                    child: Text(
                                      toName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: colors.textMain,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _fastDateFormat(tx.date),
                                      style: TextStyle(
                                        color: colors.textSecondary,
                                        fontSize: 12,
                                      ),
                                    ),
                                    if (customNote.isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Icon(
                                            Icons.notes,
                                            size: 14,
                                            color: colors.textSecondary
                                                .withValues(alpha: 0.7),
                                          ),
                                          const SizedBox(width: 4),
                                          Expanded(
                                            child: Text(
                                              customNote,
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontStyle: FontStyle.italic,
                                                color: colors.textSecondary,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              trailing: Text(
                                "${widget.showExpenses ? '-' : '+'}${CurrencyFormatter.format(tx.amount.abs())} $currencySymbol",
                                style: TextStyle(
                                  color: widget.showExpenses
                                      ? colors.expense
                                      : colors.income,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TrendsCarousel extends StatefulWidget {
  final Map<String, Map<String, Map<String, int>>> trends;
  final AppColorsExtension colors;

  const _TrendsCarousel({required this.trends, required this.colors});

  @override
  State<_TrendsCarousel> createState() => _TrendsCarouselState();
}

class _TrendsCarouselState extends State<_TrendsCarousel> {
  late PageController _pageController;
  late int _currentPage;

  @override
  void initState() {
    super.initState();
    _currentPage = widget.trends.isNotEmpty ? widget.trends.length - 1 : 0;
    _pageController = PageController(
      viewportFraction: 1.0,
      initialPage: _currentPage,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final keys = widget.trends.keys.toList();
    return Column(
      children: [
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            physics: const ClampingScrollPhysics(),
            itemCount: keys.length,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            itemBuilder: (context, index) {
              return _TrendCardWidget(
                currency: keys[index],
                data: widget.trends[keys[index]]!,
                colors: widget.colors,
              );
            },
          ),
        ),
        if (keys.length > 1)
          Padding(
            padding: const EdgeInsets.only(bottom: 16.0, top: 4.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(keys.length, (index) {
                bool isActive = _currentPage == index;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: isActive ? 20 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: isActive
                        ? widget.colors.textMain
                        : widget.colors.textSecondary.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),
          ),
      ],
    );
  }
}

class TextDotPainter extends FlDotPainter {
  final double radius;
  final Color color;
  final Color strokeColor;
  final double strokeWidth;
  final String text;
  final TextStyle textStyle;
  final double yOffset;
  final double maxY;

  TextDotPainter({
    required this.radius,
    required this.color,
    required this.strokeColor,
    required this.strokeWidth,
    required this.text,
    required this.textStyle,
    required this.yOffset,
    required this.maxY,
  });

  @override
  Color get mainColor => color;

  @override
  FlDotPainter lerp(FlDotPainter a, FlDotPainter b, double t) {
    return b;
  }

  @override
  void draw(Canvas canvas, FlSpot spot, Offset offsetInCanvas) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawCircle(offsetInCanvas, radius, paint);

    if (strokeWidth > 0) {
      final strokePaint = Paint()
        ..color = strokeColor
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke;
      canvas.drawCircle(offsetInCanvas, radius, strokePaint);
    }

    if (text.isNotEmpty) {
      final span = TextSpan(text: text, style: textStyle);
      final tp = TextPainter(text: span, textDirection: ui.TextDirection.ltr);
      tp.layout();
      final dx = offsetInCanvas.dx - (tp.width / 2);

      double finalYOffset = yOffset;
      if (spot.y < maxY * 0.15 && yOffset > 0) {
        finalYOffset = -14.0;
      }

      final dy =
          offsetInCanvas.dy + finalYOffset - (finalYOffset < 0 ? tp.height : 0);
      tp.paint(canvas, Offset(dx, dy));
    }
  }

  @override
  Size getSize(FlSpot spot) => Size(radius * 2, radius * 2);

  @override
  List<Object?> get props => [
    radius,
    color,
    strokeColor,
    strokeWidth,
    text,
    textStyle,
    yOffset,
    maxY,
  ];
}

class _TrendCardWidget extends StatefulWidget {
  final String currency;
  final Map<String, Map<String, int>> data;
  final AppColorsExtension colors;

  const _TrendCardWidget({
    required this.currency,
    required this.data,
    required this.colors,
  });

  @override
  State<_TrendCardWidget> createState() => _TrendCardWidgetState();
}

class _TrendCardWidgetState extends State<_TrendCardWidget> {
  late ScrollController _scrollController;
  late List<String> months;
  late double maxY;

  int _focusedIndex = 0;

  @override
  void initState() {
    super.initState();
    months = widget.data.keys.toList();

    maxY = 0.0;
    for (var m in widget.data.values) {
      double inc = (m['incomes'] ?? 0) / 100.0;
      double exp = (m['expenses'] ?? 0) / 100.0;
      if (inc > maxY) maxY = inc;
      if (exp > maxY) maxY = exp;
    }
    if (maxY == 0) maxY = 100;
    maxY = maxY * 1.2;

    double initialOffset = months.length > 1 ? (months.length - 1) * 60.0 : 0.0;
    _scrollController = ScrollController(initialScrollOffset: initialOffset);
    _focusedIndex = months.length > 1 ? months.length - 1 : 0;

    _scrollController.addListener(() {
      if (!_scrollController.hasClients) return;
      int newIndex = (_scrollController.offset / 60.0).round().clamp(
        0,
        months.isNotEmpty ? months.length - 1 : 0,
      );
      if (_focusedIndex != newIndex) {
        setState(() => _focusedIndex = newIndex);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  LineChartBarData _lineData(String key, Color color, bool isIncome) {
    int i = 0;
    List<FlSpot> spots = widget.data.values.map((v) {
      double val = (v[key] ?? 0) / 100.0;
      return FlSpot((i++).toDouble(), val);
    }).toList();

    return LineChartBarData(
      spots: spots,
      isCurved: true,
      curveSmoothness: 0.35,
      color: color,
      barWidth: 3,
      isStrokeCapRound: true,
      dotData: FlDotData(
        show: true,
        getDotPainter: (spot, percent, barData, index) {
          bool isFocused = index == _focusedIndex;

          double incVal =
              (widget.data.values.elementAt(index)['incomes'] ?? 0) / 100.0;
          double expVal =
              (widget.data.values.elementAt(index)['expenses'] ?? 0) / 100.0;

          double offset = -14.0;
          if ((incVal - expVal).abs() < (maxY * 0.15)) {
            if (isIncome) {
              offset = incVal >= expVal ? -14.0 : 10.0;
            } else {
              offset = expVal > incVal ? -14.0 : 10.0;
            }
          }

          String label = "";
          if (isFocused) {
            label = CurrencyFormatter.format((spot.y * 100).round());
          }

          return TextDotPainter(
            radius: isFocused ? 5.0 : 2.5,
            color: isFocused ? color : color.withValues(alpha: 0.3),
            strokeColor: widget.colors.cardBg,
            strokeWidth: isFocused ? 2.0 : 0.0,
            text: label,
            yOffset: offset,
            maxY: maxY,
            textStyle: TextStyle(
              color: color.withValues(alpha: isFocused ? 1.0 : 0.6),
              fontWeight: isFocused ? FontWeight.w900 : FontWeight.w600,
              fontSize: isFocused ? 12 : 9,
              shadows: [
                Shadow(
                  color: widget.colors.cardBg,
                  blurRadius: 2,
                  offset: const Offset(1, 1),
                ),
                Shadow(
                  color: widget.colors.cardBg,
                  blurRadius: 2,
                  offset: const Offset(-1, -1),
                ),
              ],
            ),
          );
        },
      ),
      belowBarData: BarAreaData(
        show: true,
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [color.withValues(alpha: 0.25), color.withValues(alpha: 0.0)],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    String symbol = AppCurrency.fromCode(widget.currency).symbol;
    double interval = maxY / 5;

    String focusedYear = months.isEmpty
        ? DateTime.now().year.toString()
        : months[_focusedIndex].split('-')[0];

    var yearData = widget.data.entries
        .where((e) => e.key.startsWith(focusedYear))
        .toList();
    int totalInc = 0, totalExp = 0;
    for (var m in yearData) {
      totalInc += (m.value['incomes'] ?? 0);
      totalExp += (m.value['expenses'] ?? 0);
    }
    int monthCount = yearData.isEmpty ? 1 : yearData.length;

    double avgInc = totalInc / monthCount;
    double avgExp = totalExp / monthCount;

    String maxLabel = NumberFormat.compact(
      locale: context.locale.languageCode,
    ).format(maxY);
    double leftAxisWidth = 24.0 + (maxLabel.length * 8.0) + 8.0;
    if (leftAxisWidth < 50) leftAxisWidth = 50.0;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 8.0,
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  "${'history_trends'.tr()} • ${widget.currency}",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: widget.colors.textMain,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                double chartWidth = months.isEmpty
                    ? 0
                    : (months.length - 1) * 60.0;

                final incomesBar = _lineData(
                  'incomes',
                  widget.colors.income,
                  true,
                );
                final expensesBar = _lineData(
                  'expenses',
                  widget.colors.expense,
                  false,
                );

                return Stack(
                  children: [
                    Positioned.fill(
                      child: SingleChildScrollView(
                        controller: _scrollController,
                        scrollDirection: Axis.horizontal,
                        dragStartBehavior: DragStartBehavior.down,
                        physics: const ClampingScrollPhysics(),
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: constraints.maxWidth / 2,
                          ),
                          child: SizedBox(
                            width: chartWidth,
                            child: LineChart(
                              LineChartData(
                                minY: 0,
                                maxY: maxY,
                                minX: 0,
                                maxX: months.length > 1
                                    ? (months.length - 1).toDouble()
                                    : 0.1,
                                gridData: FlGridData(
                                  show: true,
                                  drawHorizontalLine: false,
                                  drawVerticalLine: true,
                                  verticalInterval: 1,
                                  getDrawingVerticalLine: (value) => FlLine(
                                    color: widget.colors.textSecondary
                                        .withValues(alpha: 0.1),
                                    strokeWidth: 1,
                                    dashArray: [5, 5],
                                  ),
                                ),
                                borderData: FlBorderData(show: false),
                                titlesData: FlTitlesData(
                                  leftTitles: const AxisTitles(
                                    sideTitles: SideTitles(showTitles: false),
                                  ),
                                  rightTitles: const AxisTitles(
                                    sideTitles: SideTitles(showTitles: false),
                                  ),
                                  topTitles: const AxisTitles(
                                    sideTitles: SideTitles(showTitles: false),
                                  ),
                                  bottomTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      reservedSize: 30,
                                      interval: 1,
                                      getTitlesWidget: (value, meta) {
                                        int index = value.toInt();
                                        if (index < 0 ||
                                            index >= months.length) {
                                          return const SizedBox.shrink();
                                        }
                                        DateTime d = DateTime(
                                          int.parse(
                                            months[index].split('-')[0],
                                          ),
                                          int.parse(
                                            months[index].split('-')[1],
                                          ),
                                        );
                                        return Padding(
                                          padding: const EdgeInsets.only(
                                            top: 10.0,
                                          ),
                                          child: Text(
                                            DateFormat(
                                              'MMM yy',
                                              context.locale.languageCode,
                                            ).format(d),
                                            style: TextStyle(
                                              color:
                                                  widget.colors.textSecondary,
                                              fontSize: 10,
                                              fontWeight: FontWeight.normal,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                                lineBarsData: [incomesBar, expensesBar],
                                showingTooltipIndicators: [],
                                lineTouchData: const LineTouchData(
                                  enabled: false,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    Positioned.fill(
                      child: IgnorePointer(
                        child: LineChart(
                          LineChartData(
                            minY: 0,
                            maxY: maxY,
                            minX: 0,
                            maxX: 1,
                            gridData: FlGridData(
                              show: true,
                              drawVerticalLine: false,
                              drawHorizontalLine: true,
                              horizontalInterval: interval,
                              getDrawingHorizontalLine: (value) => FlLine(
                                color: widget.colors.textSecondary.withValues(
                                  alpha: 0.15,
                                ),
                                strokeWidth: 1,
                                dashArray: [5, 5],
                              ),
                            ),
                            borderData: FlBorderData(show: false),
                            titlesData: FlTitlesData(
                              rightTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              topTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 30,
                                  getTitlesWidget: (v, m) =>
                                      const SizedBox.shrink(),
                                ),
                              ),
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: leftAxisWidth,
                                  interval: interval,
                                  getTitlesWidget: (value, meta) {
                                    if (value == 0) {
                                      return const SizedBox.shrink();
                                    }
                                    return Container(
                                      padding: const EdgeInsets.only(
                                        left: 24.0,
                                      ),
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        NumberFormat.compact(
                                          locale: context.locale.languageCode,
                                        ).format(value),
                                        style: TextStyle(
                                          color: widget.colors.textSecondary,
                                          fontSize: 10,
                                          fontWeight: FontWeight.normal,
                                          shadows: [
                                            Shadow(
                                              color: widget.colors.cardBg,
                                              blurRadius: 4,
                                            ),
                                            Shadow(
                                              color: widget.colors.cardBg,
                                              blurRadius: 4,
                                            ),
                                          ],
                                        ),
                                        maxLines: 1,
                                        softWrap: false,
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                            lineBarsData: [
                              LineChartBarData(
                                spots: const [FlSpot(0, 0)],
                                color: Colors.transparent,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    Positioned(
                      left: constraints.maxWidth / 2 - 0.5,
                      top: 0,
                      bottom: 30,
                      child: IgnorePointer(
                        child: Container(
                          width: 1,
                          color: widget.colors.textMain.withValues(alpha: 0.25),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

          Container(
            margin: const EdgeInsets.fromLTRB(24, 16, 24, 8),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: widget.colors.iconBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: widget.colors.textSecondary.withValues(alpha: 0.1),
              ),
            ),
            child: Column(
              children: [
                Text(
                  'average_for_year'.tr(args: [focusedYear]),
                  style: TextStyle(
                    color: widget.colors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            'income'.tr(),
                            style: TextStyle(
                              color: widget.colors.textSecondary,
                              fontSize: 10,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            "${CurrencyFormatter.format(avgInc.round())} $symbol",
                            style: TextStyle(
                              color: widget.colors.income,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 30,
                      color: widget.colors.textSecondary.withValues(alpha: 0.2),
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            'stats_expenses'.tr(),
                            style: TextStyle(
                              color: widget.colors.textSecondary,
                              fontSize: 10,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            "${CurrencyFormatter.format(avgExp.round())} $symbol",
                            style: TextStyle(
                              color: widget.colors.expense,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
