import 'package:coin_flow/theme/category_defaults.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:vibration/vibration.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:collection/collection.dart';
import '../models/category_model.dart';
import '../models/transaction_model.dart';
import '../models/subscription_model.dart';
import '../widgets/common/coin_widget.dart';
import '../widgets/bottom_sheets/history_bottom_sheet.dart';
import '../widgets/common/summary_header.dart';
import '../widgets/bottom_sheets/general_history_bottom_sheet.dart';
import '../widgets/common/settings_drawer.dart';
import '../widgets/common/home_screen_skeleton.dart';
import '../screens/transaction_screen.dart';
import '../screens/category_screen.dart';
import '../widgets/dialogs/due_subscription_dialog.dart';
import '../utils/currency_formatter.dart';
import '../providers/category_provider.dart';
import '../providers/transaction_provider.dart';
import '../providers/subscription_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/stats_provider.dart'; // 👇 ДОДАНО ІМПОРТ НОВОГО ПРОВАЙДЕРА
import '../theme/app_colors_extension.dart';

String formatCurrency(int amount) => CurrencyFormatter.format(amount);

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  List<String> deletingIds = [];
  bool isEditMode = false;
  String? draggedCategoryId;
  late AnimationController _jiggleController;

  final Map<String, PageController> _pageControllers = {};
  bool _isShowingDueDialog = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _jiggleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final subProv = context.read<SubscriptionProvider>();
      subProv.addListener(_checkDueSubscriptions);
      _checkDueSubscriptions();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (mounted) {
        context.read<SubscriptionProvider>().refreshOnAppResume();
      }
    }
  }

  void _checkDueSubscriptions() {
    if (!mounted) return;
    final subProv = context.read<SubscriptionProvider>();

    if (subProv.dueSubscriptions.isNotEmpty && !_isShowingDueDialog) {
      _showDueSubscriptionDialog(subProv.dueSubscriptions.first);
    }
  }

  void _showDueSubscriptionDialog(Subscription sub) {
    if (_isShowingDueDialog) return;
    _isShowingDueDialog = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => DueSubscriptionDialog(subscription: sub),
    ).then((_) {
      _isShowingDueDialog = false;
      _checkDueSubscriptions();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);

    try {
      context.read<SubscriptionProvider>().removeListener(
        _checkDueSubscriptions,
      );
    } catch (_) {}
    _jiggleController.dispose();
    for (var ctrl in _pageControllers.values) {
      ctrl.dispose();
    }
    super.dispose();
  }

  void _handleTransfer(Category source, Category target) async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            TransactionScreen(source: source, target: target),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeOutQuart;

          var tween = Tween(
            begin: begin,
            end: end,
          ).chain(CurveTween(curve: curve));

          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
      ),
    );

    if (!mounted) return;

    if (result != null) {
      // Тепер отримуємо суми як цілі числа (копійки)
      final amount = result['amount'] as int;
      final targetAmount = result['targetAmount'] as int?;
      final date = result['date'] as DateTime;
      final comment = result['comment'] as String;

      if (amount > 0) {
        final txProv = context.read<TransactionProvider>();
        final catProv = context.read<CategoryProvider>();

        String txTitle = comment.trim().isNotEmpty
            ? comment.trim()
            : '${'transfer'.tr()} ${source.name} ➡️ ${target.name}';

        final newTx = Transaction(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          fromId: source.id,
          toId: target.id,
          title: txTitle,
          amount: amount, // Передаємо int
          date: date,
          currency: source.currency,
          targetAmount: targetAmount, // Передаємо int?
          targetCurrency: source.currency != target.currency
              ? target.currency
              : null,
          baseAmount: 0, // Провайдер сам перерахує це в int
          baseCurrency: '',
        );

        catProv.updateCategoryAmount(source.id, -amount);
        catProv.updateCategoryAmount(target.id, targetAmount ?? amount);

        // Зберігаємо історію
        txProv.addTransactionDirectly(newTx);
      }
    }
  }

  void _handleEditTransaction(
    Transaction t,
    List<Category> allCategories,
  ) async {
    Category? sourceCat = allCategories.firstWhereOrNull(
      (c) => c.id == t.fromId,
    );
    Category? targetCat = allCategories.firstWhereOrNull((c) => c.id == t.toId);

    if (sourceCat == null || targetCat == null) {
      return;
    }

    String? initialNote = t.title;
    if (initialNote.contains('➡️')) {
      initialNote = '';
    }

    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            TransactionScreen(
              source: sourceCat,
              target: targetCat,
              initialAmount: t.amount,
              initialTargetAmount: t.targetAmount,
              initialDate: t.date,
              initialNote: initialNote,
            ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeOutQuart;
          var tween = Tween(
            begin: begin,
            end: end,
          ).chain(CurveTween(curve: curve));
          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
      ),
    );

    if (!mounted || result == null) return;

    final finance = context.read<TransactionProvider>();

    final comment = result['comment'] as String;
    t.title = comment.trim().isNotEmpty
        ? comment.trim()
        : '${'transfer'.tr()} ${sourceCat.name} ➡️ ${targetCat.name}';

    finance.editTransaction(
      t,
      result['amount'],
      result['date'],
      newTargetAmount: result['targetAmount'],
    );
  }

  void _showCategoryDialog({Category? c, required CategoryType type}) async {
    final result = await Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            CategoryScreen(category: c, type: type),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(0.0, 1.0);
          const end = Offset.zero;
          const curve = Curves.easeOutQuart;
          var tween = Tween(
            begin: begin,
            end: end,
          ).chain(CurveTween(curve: curve));
          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
      ),
    );

    if (isEditMode && mounted) {
      setState(() {
        isEditMode = false;
        _jiggleController.stop();
      });
    }

    if (!mounted || result == null) return;
    final catProv = context.read<CategoryProvider>();

    if (result == 'delete' && c != null) {
      if (!mounted) return;
      setState(() => deletingIds.add(c.id));
      await Future.delayed(const Duration(milliseconds: 350));
      catProv.deleteCategory(c);
      if (mounted) setState(() => deletingIds.remove(c.id));
      return;
    }

    if (result is Map) {
      if (c == null) {
        final prefix = type == CategoryType.income
            ? "inc"
            : (type == CategoryType.account ? "acc" : "exp");
        final n = Category(
          id: "${prefix}_${DateTime.now().millisecondsSinceEpoch}",
          type: type,
          name: result['name'],
          icon: result['icon'],
          amount: (result['amount'] as num?)?.toInt() ?? 0, // Гарантуємо int
          budget: (result['budget'] as num?)?.toInt(), // Гарантуємо int?
          bgColor: CategoryDefaults.getBgColor(type),
          iconColor: CategoryDefaults.getIconColor(type),
          currency:
              result['currency'] ??
              context.read<SettingsProvider>().baseCurrency,
          includeInTotal: result['includeInTotal'] ?? true,
        );
        catProv.addOrUpdateCategory(n);
      } else {
        final updatedCategory = c.copyWith(
          name: result['name'],
          icon: result['icon'],
          budget: result['budget'],
          amount: type == CategoryType.account
              ? (result['amount'] ?? c.amount)
              : c.amount,
          currency: result['currency'] ?? c.currency,
          includeInTotal: result['includeInTotal'] ?? c.includeInTotal,
        );
        catProv.addOrUpdateCategory(updatedCategory);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColorsExtension>()!;

    return Scaffold(
      key: _scaffoldKey,
      endDrawer: const SettingsDrawer(),
      resizeToAvoidBottomInset: false,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          if (isEditMode) {
            setState(() {
              isEditMode = false;
              _jiggleController.stop();
            });
          }
        },
        child: Selector2<CategoryProvider, TransactionProvider, bool>(
          selector: (ctx, cat, tx) => cat.isLoading || tx.isLoading,
          builder: (context, isLoading, child) {
            if (isLoading) {
              return const HomeScreenSkeleton();
            }

            return Container(
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
                maintainBottomViewPadding: true,
                child: Column(
                  children: [
                    // 👇 ЗМІНЕНО: Додано StatsProvider у Consumer4
                    Consumer4<
                      TransactionProvider,
                      CategoryProvider,
                      SettingsProvider,
                      StatsProvider
                    >(
                      builder:
                          (
                            context,
                            txProv,
                            catProv,
                            settings,
                            statsProv,
                            child,
                          ) {
                            // 👇 ЗМІНЕНО: Викликаємо метод з statsProv
                            final monthTotals = statsProv
                                .calculateTotalsForMonth(txProv.selectedMonth);

                            // Тепер ці дані приходять як int з StatsProvider
                            int totalIncomes =
                                monthTotals['incomes']?.toInt() ?? 0;
                            int totalExpenses =
                                monthTotals['expenses']?.toInt() ?? 0;

                            // Рахуємо загальний баланс у копійках
                            int totalBalance = catProv.accounts
                                .where((item) => item.includeInTotal)
                                .fold(
                                  0,
                                  (sum, item) =>
                                      sum +
                                      settings
                                          .convertToBase(
                                            item.amount,
                                            item.currency,
                                          )
                                          .round(), // Обов'язково .round() до цілих копійок
                                );

                            return SummaryHeader(
                              totalBalance: totalBalance,
                              totalIncomes: totalIncomes,
                              totalExpenses: totalExpenses,
                              isMigrating: txProv.isMigrating,
                              onBalanceTap: () {
                                if (isEditMode) {
                                  setState(() {
                                    isEditMode = false;
                                    _jiggleController.stop();
                                  });
                                  return;
                                }
                                _openHistoryBottomSheet(
                                  context,
                                  'history_balance'.tr(),
                                  CategoryType.account,
                                );
                              },
                              onIncomesTap: () {
                                if (isEditMode) {
                                  setState(() {
                                    isEditMode = false;
                                    _jiggleController.stop();
                                  });
                                  return;
                                }
                                _openHistoryBottomSheet(
                                  context,
                                  'history_incomes'.tr(),
                                  CategoryType.income,
                                );
                              },
                              onExpensesTap: () {
                                if (isEditMode) {
                                  setState(() {
                                    isEditMode = false;
                                    _jiggleController.stop();
                                  });
                                  return;
                                }
                                _openHistoryBottomSheet(
                                  context,
                                  'history_expenses'.tr(),
                                  CategoryType.expense,
                                );
                              },
                              onSettingsTap: () {
                                if (isEditMode) {
                                  setState(() {
                                    isEditMode = false;
                                    _jiggleController.stop();
                                  });
                                  return;
                                }
                                _scaffoldKey.currentState?.openEndDrawer();
                              },
                            );
                          },
                    ),

                    // 👇 ЗМІНЕНО: Додано StatsProvider у Consumer3
                    Consumer3<
                      CategoryProvider,
                      TransactionProvider,
                      StatsProvider
                    >(
                      builder: (context, catProv, txProv, statsProv, child) {
                        // 👇 ЗМІНЕНО: Викликаємо метод з statsProv
                        final incomeMap = statsProv
                            .calculateCategoryTotalsForMonth(
                              txProv.selectedMonth,
                              false,
                              inBaseCurrency: false,
                            );
                        final displayIncomes = catProv.incomes
                            .map(
                              (c) => c.copyWith(
                                amount: incomeMap[c.id]?.toInt() ?? 0,
                              ),
                            )
                            .toList();
                        return _buildSection(
                          displayIncomes,
                          CategoryType.income,
                        );
                      },
                    ),

                    Consumer<CategoryProvider>(
                      builder: (context, catProv, child) {
                        return _buildSection(
                          catProv.accounts,
                          CategoryType.account,
                          isTarget: true,
                        );
                      },
                    ),

                    Expanded(
                      // 👇 ЗМІНЕНО: Додано StatsProvider у Consumer3
                      child:
                          Consumer3<
                            CategoryProvider,
                            TransactionProvider,
                            StatsProvider
                          >(
                            builder:
                                (context, catProv, txProv, statsProv, child) {
                                  // 👇 ЗМІНЕНО: Викликаємо метод з statsProv
                                  final expenseMap = statsProv
                                      .calculateCategoryTotalsForMonth(
                                        txProv.selectedMonth,
                                        true,
                                        inBaseCurrency: false,
                                      );
                                  final displayExpenses = catProv.expenses
                                      .map(
                                        (c) => c.copyWith(
                                          amount:
                                              expenseMap[c.id]?.toInt() ?? 0,
                                        ),
                                      )
                                      .toList();
                                  return _buildSection(
                                    displayExpenses,
                                    CategoryType.expense,
                                    isTarget: true,
                                    isGrid: true,
                                  );
                                },
                          ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _openHistoryBottomSheet(
    BuildContext context,
    String title,
    CategoryType type,
  ) {
    final txProv = context.read<TransactionProvider>();
    final catProv = context.read<CategoryProvider>();
    final allCategories = catProv.allCategoriesList;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => GeneralHistoryBottomSheet(
        title: title,
        filterType: type,
        transactions: txProv.history,
        allCategories: allCategories,
        onDelete: (t) =>
            context.read<TransactionProvider>().deleteTransaction(t),
        onEdit: (t) => _handleEditTransaction(t, allCategories),
      ),
    );
  }

  Widget _buildSection(
    List<Category> list,
    CategoryType type, {
    bool isTarget = false,
    bool isGrid = false,
  }) {
    final colors = Theme.of(context).extension<AppColorsExtension>()!;
    String typeKey = type.name;
    if (!_pageControllers.containsKey(typeKey)) {
      _pageControllers[typeKey] = PageController();
    }
    PageController pageCtrl = _pageControllers[typeKey]!;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: colors.cardBg,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 10,
            spreadRadius: 1,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          int crossAxisCount = (constraints.maxWidth / 80).floor().clamp(4, 8);
          final items = [
            ...list.map((c) => _buildCoin(c, isTarget)),
            _buildAddBtn(type),
          ];

          Widget pageView;
          if (!isGrid) {
            int perPage = crossAxisCount;
            double itemWidth = (constraints.maxWidth / perPage) - 0.01;
            pageView = SizedBox(
              height: 105,
              child: PageView.builder(
                controller: pageCtrl,
                itemCount: (items.length / perPage).ceil(),
                itemBuilder: (ctx, p) => Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: items
                      .skip(p * perPage)
                      .take(perPage)
                      .map(
                        (i) => SizedBox(
                          width: itemWidth,
                          height: 105,
                          child: Center(child: i),
                        ),
                      )
                      .toList(),
                ),
              ),
            );
          } else {
            int rowsCount = 4;
            if (constraints.maxHeight < 380) {
              rowsCount = 3;
            } else if (constraints.maxHeight > 500) {
              rowsCount = 5;
            }
            int perPage = crossAxisCount * rowsCount;
            double itemWidth = (constraints.maxWidth / crossAxisCount) - 0.01;
            double itemHeight = (constraints.maxHeight / rowsCount).clamp(
              96.0,
              125.0,
            );

            pageView = PageView.builder(
              controller: pageCtrl,
              itemCount: items.isEmpty ? 1 : (items.length / perPage).ceil(),
              itemBuilder: (ctx, p) {
                final pageItems = items
                    .skip(p * perPage)
                    .take(perPage)
                    .toList();
                return SizedBox(
                  width: constraints.maxWidth,
                  height: constraints.maxHeight,
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Wrap(
                      alignment: WrapAlignment.start,
                      runAlignment: WrapAlignment.start,
                      children: pageItems
                          .map(
                            (item) => SizedBox(
                              width: itemWidth,
                              height: itemHeight,
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: item,
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                );
              },
            );
          }

          return Stack(
            children: [
              pageView,
              if (draggedCategoryId != null) ...[
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  width: 25,
                  child: DragTarget<Category>(
                    onWillAcceptWithDetails: (_) {
                      pageCtrl.previousPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                      return false;
                    },
                    builder: (_, _, _) => Container(color: Colors.transparent),
                  ),
                ),
                Positioned(
                  right: 0,
                  top: 0,
                  bottom: 0,
                  width: 25,
                  child: DragTarget<Category>(
                    onWillAcceptWithDetails: (_) {
                      pageCtrl.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                      return false;
                    },
                    builder: (_, _, _) => Container(color: Colors.transparent),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildCoin(Category c, bool isTarget) {
    final colors = Theme.of(context).extension<AppColorsExtension>()!;
    bool isDeleting = deletingIds.contains(c.id);
    bool isBeingDragged = draggedCategoryId == c.id;

    Widget dragFeedback = Material(
      color: Colors.transparent,
      child: CoinWidget(category: c, isFeedback: true),
    );

    Widget buildInteractiveInnerCoin(
      Widget normalCoin,
      Widget placeholderCoin,
    ) {
      if (isEditMode || c.type == CategoryType.expense) return normalCoin;
      return Draggable<Category>(
        data: c,
        maxSimultaneousDrags: 1,
        onDragStarted: () => setState(() => draggedCategoryId = c.id),
        onDragEnd: (_) => setState(() => draggedCategoryId = null),
        onDraggableCanceled: (_, _) => setState(() => draggedCategoryId = null),
        feedback: dragFeedback,
        childWhenDragging: placeholderCoin,
        child: isBeingDragged ? placeholderCoin : normalCoin,
      );
    }

    void openHistory() {
      if (isEditMode) {
        setState(() {
          isEditMode = false;
          _jiggleController.stop();
        });
        return;
      }
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => Builder(
          builder: (ctx) {
            final catProv = context.read<CategoryProvider>();
            final txProv = context.read<TransactionProvider>();
            return HistoryBottomSheet(
              category: c,
              transactions: txProv.history,
              allCategories: catProv.allCategoriesList,
              onDelete: (t) =>
                  context.read<TransactionProvider>().deleteTransaction(t),
              onEdit: (t) =>
                  _handleEditTransaction(t, catProv.allCategoriesList),
            );
          },
        ),
      );
    }

    Widget buildContent(bool isHovered) {
      Widget coin = AnimatedScale(
        duration: const Duration(milliseconds: 300),
        scale: isDeleting ? 0.0 : 1.0,
        curve: Curves.easeInBack,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 250),
          opacity: isDeleting ? 0.0 : 1.0,
          child: CoinWidget(
            category: c,
            isHovered: isHovered,
            coinWrapper: buildInteractiveInnerCoin,
          ),
        ),
      );

      if (isEditMode) {
        coin = Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            coin,
            Positioned(
              top: 0,
              right: 0,
              child: GestureDetector(
                onTap: () => _showCategoryDialog(c: c, type: c.type),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: colors.cardBg,
                    shape: BoxShape.circle,
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 2,
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.edit,
                    size: 14,
                    color: Colors.blueAccent,
                  ),
                ),
              ),
            ),
          ],
        );
        coin = AnimatedBuilder(
          animation: _jiggleController,
          builder: (context, child) => Transform.rotate(
            angle: math.sin(_jiggleController.value * math.pi * 2) * 0.04,
            child: child,
          ),
          child: coin,
        );
      }

      Widget emptySpace = Opacity(opacity: 0.0, child: coin);

      Widget dragFeedbackReorder = Material(
        color: Colors.transparent,
        child: CoinWidget(category: c),
      );

      if (isEditMode) {
        return GestureDetector(
          onTap: openHistory,
          child: Draggable<Category>(
            data: c,
            maxSimultaneousDrags: 1,
            onDragStarted: () => setState(() => draggedCategoryId = c.id),
            onDragEnd: (_) => setState(() => draggedCategoryId = null),
            onDraggableCanceled: (_, _) =>
                setState(() => draggedCategoryId = null),
            feedback: dragFeedbackReorder,
            childWhenDragging: emptySpace,
            child: isBeingDragged ? emptySpace : coin,
          ),
        );
      } else {
        return GestureDetector(
          onTap: openHistory,
          child: LongPressDraggable<Category>(
            data: c,
            maxSimultaneousDrags: 1,
            delay: const Duration(milliseconds: 500),
            onDragStarted: () async {
              if (await Vibration.hasVibrator() == true) {
                Vibration.vibrate(duration: 15, amplitude: 40);
              }
              setState(() {
                isEditMode = true;
                _jiggleController.repeat();
                draggedCategoryId = c.id;
              });
            },
            onDragEnd: (_) => setState(() => draggedCategoryId = null),
            onDraggableCanceled: (_, _) =>
                setState(() => draggedCategoryId = null),
            feedback: dragFeedbackReorder,
            childWhenDragging: emptySpace,
            child: coin,
          ),
        );
      }
    }

    return KeyedSubtree(
      key: ValueKey(c.id),
      child: (isTarget || isEditMode)
          ? DragTarget<Category>(
              onWillAcceptWithDetails: (details) {
                final source = details.data;
                if (source.id == c.id) return false;
                bool isSameGroup = source.type == c.type;
                if (isEditMode) {
                  if (isSameGroup) {
                    context.read<CategoryProvider>().reorderCategories(
                      source,
                      c,
                    );
                    return true;
                  }
                  return false;
                } else {
                  if (isSameGroup) return source.type == CategoryType.account;
                  if (source.type == CategoryType.income &&
                      c.type == CategoryType.expense) {
                    return false;
                  }
                  if (source.type == CategoryType.expense) return false;
                  return true;
                }
              },
              onAcceptWithDetails: (d) {
                if (!isEditMode) {
                  final source = d.data;
                  if (source.type == c.type &&
                      source.type != CategoryType.account) {
                    return;
                  }
                  _handleTransfer(source, c);
                }
              },
              builder: (_, candidateData, _) =>
                  buildContent(candidateData.isNotEmpty),
            )
          : buildContent(false),
    );
  }

  Widget _buildAddBtn(CategoryType type) {
    final colors = Theme.of(context).extension<AppColorsExtension>()!;
    return GestureDetector(
      onTap: () {
        if (isEditMode) {
          setState(() {
            isEditMode = false;
            _jiggleController.stop();
          });
          return;
        }
        _showCategoryDialog(type: type);
      },
      child: Opacity(
        opacity: isEditMode ? 0.3 : 1.0,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("", style: TextStyle(fontSize: 10)),
            const SizedBox(height: 4),
            Container(
              width: 55,
              height: 55,
              decoration: BoxDecoration(
                color: colors.iconBg,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.add, color: colors.textSecondary, size: 24),
            ),
            const SizedBox(height: 4),
            const Text("", style: TextStyle(fontSize: 10)),
          ],
        ),
      ),
    );
  }
}
