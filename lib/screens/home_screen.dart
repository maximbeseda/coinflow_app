import 'package:coin_flow/theme/category_defaults.dart';
import 'package:flutter/material.dart';
import 'package:drift/drift.dart' as drift;
import 'dart:math' as math;
import 'package:vibration/vibration.dart';

// 👇 1. Перейшли на Riverpod
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:collection/collection.dart';

import '../database/app_database.dart';
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
import '../theme/app_colors_extension.dart';

// 👇 2. Імпортуємо НАШ ЄДИНИЙ ХАБ
import '../providers/all_providers.dart';

String formatCurrency(int amount) => CurrencyFormatter.format(amount);

// 👇 3. Замінили StatefulWidget на ConsumerStatefulWidget
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
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

    // Первинна перевірка підписок (використовуємо read, бо ми не в build)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkDueSubscriptions();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (mounted) {
        ref.read(subscriptionProvider.notifier).refreshOnAppResume();
      }
    }
  }

  void _checkDueSubscriptions() {
    if (!mounted) return;
    final subState = ref.read(subscriptionProvider);

    if (subState.dueSubscriptions.isNotEmpty && !_isShowingDueDialog) {
      _showDueSubscriptionDialog(subState.dueSubscriptions.first);
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
      // 👇 ФІКС: Просто скидаємо прапорець.
      // Більше не викликаємо _checkDueSubscriptions() вручну,
      // бо це робить ref.listen автоматично і коректно.
      _isShowingDueDialog = false;
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
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
      final amount = result['amount'] as int;
      final targetAmount = result['targetAmount'] as int?;
      final date = result['date'] as DateTime;
      final comment = result['comment'] as String;

      if (amount > 0) {
        // 👇 Використовуємо Notifiers для виклику функцій
        final txNotifier = ref.read(transactionProvider.notifier);
        final catNotifier = ref.read(categoryProvider.notifier);

        String txTitle = comment.trim().isNotEmpty
            ? comment.trim()
            : '${'transfer'.tr()} ${source.name} ➡️ ${target.name}';

        final newTx = Transaction(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          fromId: source.id,
          toId: target.id,
          title: txTitle,
          amount: amount,
          date: date,
          currency: source.currency,
          targetAmount: targetAmount,
          targetCurrency: source.currency != target.currency
              ? target.currency
              : null,
          baseAmount: 0,
          baseCurrency: '',
        );

        catNotifier.updateCategoryAmount(source.id, -amount);
        catNotifier.updateCategoryAmount(target.id, targetAmount ?? amount);

        txNotifier.addTransactionDirectly(newTx);
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

    final txNotifier = ref.read(transactionProvider.notifier);
    final comment = result['comment'] as String;

    final newTitle = comment.trim().isNotEmpty
        ? comment.trim()
        : '${'transfer'.tr()} ${sourceCat.name} ➡️ ${targetCat.name}';

    final updatedT = t.copyWith(title: newTitle);

    txNotifier.editTransaction(
      updatedT,
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
    final catNotifier = ref.read(categoryProvider.notifier);

    if (result == 'delete' && c != null) {
      if (!mounted) return;
      setState(() => deletingIds.add(c.id));
      await Future.delayed(const Duration(milliseconds: 350));
      catNotifier.deleteCategory(c);
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
          amount: (result['amount'] as num?)?.toInt() ?? 0,
          budget: (result['budget'] as num?)?.toInt(),
          isArchived: false,
          bgColor: CategoryDefaults.getBgColor(type).toARGB32(),
          iconColor: CategoryDefaults.getIconColor(type).toARGB32(),
          currency:
              result['currency'] ?? ref.read(settingsProvider).baseCurrency,
          includeInTotal: result['includeInTotal'] ?? true,
          sortOrder: 0,
        );
        catNotifier.addOrUpdateCategory(n);
      } else {
        final updatedCategory = c.copyWith(
          name: result['name'],
          icon: result['icon'],
          budget: drift.Value(result['budget']),
          amount: type == CategoryType.account
              ? (result['amount'] ?? c.amount)
              : c.amount,
          currency: result['currency'] ?? c.currency,
          includeInTotal: result['includeInTotal'] ?? c.includeInTotal,
        );
        catNotifier.addOrUpdateCategory(updatedCategory);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColorsExtension>()!;

    // 👇 4. Магія Riverpod: Миттєво слухаємо зміни у підписках і викликаємо діалог!
    ref.listen(subscriptionProvider, (prev, next) {
      if (next.dueSubscriptions.isNotEmpty && !_isShowingDueDialog) {
        _showDueSubscriptionDialog(next.dueSubscriptions.first);
      }
    });

    // 👇 Читаємо всі стани одним рядком без Consumer-матрьошок!
    final catState = ref.watch(categoryProvider);
    final txState = ref.watch(transactionProvider);
    ref.watch(settingsProvider); // Просто слідкуємо за оновленнями налаштувань

    // Щоб екран оновлювався, коли міняється статистика (графіки/рахунки)
    ref.watch(statsProvider);
    final statsNotifier = ref.read(statsProvider.notifier);
    final settingsNotifier = ref.read(settingsProvider.notifier);

    // Якщо дані ще вантажаться
    if (catState.isLoading || txState.isLoading) {
      return Scaffold(
        backgroundColor: colors.bgGradientStart,
        body: const HomeScreenSkeleton(),
      );
    }

    // Рахуємо дані для шапки
    final monthTotals = statsNotifier.calculateTotalsForMonth(
      txState.selectedMonth,
    );
    int totalIncomes = monthTotals['incomes'] ?? 0;
    int totalExpenses = monthTotals['expenses'] ?? 0;

    int totalBalance = catState.accounts
        .where((item) => item.includeInTotal)
        .fold(
          0,
          (sum, item) =>
              sum + settingsNotifier.convertToBase(item.amount, item.currency),
        );

    // Рахуємо дані для секцій (доходи)
    final incomeMap = statsNotifier.calculateCategoryTotalsForMonth(
      txState.selectedMonth,
      false,
      inBaseCurrency: false,
    );
    final displayIncomes = catState.incomes
        .map((c) => c.copyWith(amount: incomeMap[c.id] ?? 0))
        .toList();

    // Рахуємо дані для секцій (витрати)
    final expenseMap = statsNotifier.calculateCategoryTotalsForMonth(
      txState.selectedMonth,
      true,
      inBaseCurrency: false,
    );
    final displayExpenses = catState.expenses
        .map((c) => c.copyWith(amount: expenseMap[c.id] ?? 0))
        .toList();

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
        child: Container(
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
                SummaryHeader(
                  totalBalance: totalBalance,
                  totalIncomes: totalIncomes,
                  totalExpenses: totalExpenses,
                  isMigrating: txState.isMigrating,
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
                ),

                // СЕКЦІЯ: ДОХОДИ
                _buildSection(displayIncomes, CategoryType.income),

                // СЕКЦІЯ: РАХУНКИ
                _buildSection(
                  catState.accounts,
                  CategoryType.account,
                  isTarget: true,
                ),

                // СЕКЦІЯ: ВИТРАТИ
                Expanded(
                  child: _buildSection(
                    displayExpenses,
                    CategoryType.expense,
                    isTarget: true,
                    isGrid: true,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openHistoryBottomSheet(
    BuildContext context,
    String title,
    CategoryType type,
  ) {
    final txState = ref.read(transactionProvider);
    final catState = ref.read(categoryProvider);
    final allCategories = catState.allCategoriesList;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => GeneralHistoryBottomSheet(
        title: title,
        filterType: type,
        transactions: txState.history,
        allCategories: allCategories,
        onDelete: (t) =>
            ref.read(transactionProvider.notifier).deleteTransaction(t),
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
            color: Colors.black.withValues(alpha: 0.1),
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

      final catState = ref.read(categoryProvider);
      final txState = ref.read(transactionProvider);

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => HistoryBottomSheet(
          category: c,
          transactions: txState.history,
          allCategories: catState.allCategoriesList,
          onDelete: (t) =>
              ref.read(transactionProvider.notifier).deleteTransaction(t),
          onEdit: (t) => _handleEditTransaction(t, catState.allCategoriesList),
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
                    ref
                        .read(categoryProvider.notifier)
                        .reorderCategories(source, c);
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
