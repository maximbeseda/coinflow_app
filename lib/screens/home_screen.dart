import 'package:coin_flow/theme/category_defaults.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:vibration/vibration.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import '../models/category_model.dart';
import '../models/subscription_model.dart';
import '../widgets/common/coin_widget.dart';
import '../widgets/bottom_sheets/history_bottom_sheet.dart';
import '../widgets/common/summary_header.dart';
import '../widgets/bottom_sheets/general_history_bottom_sheet.dart';
import '../widgets/common/settings_drawer.dart';
import '../widgets/dialogs/transfer_dialog.dart';
import '../widgets/dialogs/category_dialog.dart';
import '../widgets/dialogs/edit_transaction_dialog.dart';
import '../widgets/dialogs/due_subscription_dialog.dart';
import '../utils/currency_formatter.dart';
import '../providers/category_provider.dart';
import '../providers/transaction_provider.dart';
import '../providers/subscription_provider.dart';
import '../theme/app_colors_extension.dart';

String formatCurrency(double amount) => CurrencyFormatter.format(amount);

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

// ДОДАНО: WidgetsBindingObserver через кому
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
    // ДОДАНО: Реєструємо спостерігача за станом додатку
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

  // ДОДАНО: Метод, що ловить розгортання додатку з фону
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (mounted) {
        // Коли додаток розгортається, просимо перевірити прострочені платежі
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
    // ДОДАНО: Видаляємо спостерігача, щоб не було витоку пам'яті
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

  void _handleTransfer(Category s, Category t) async {
    if (s == t ||
        s.type == CategoryType.expense ||
        (s.type == CategoryType.income && t.type == CategoryType.expense)) {
      return;
    }

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => TransferDialog(source: s, target: t),
    );
    if (result != null && mounted) {
      context.read<TransactionProvider>().addTransfer(
        s,
        t,
        result['amount'],
        result['date'],
      );
    }
  }

  Future<bool> _confirmDeletion(
    BuildContext context,
    String title,
    String message,
  ) async {
    final colors = Theme.of(context).extension<AppColorsExtension>()!;
    return await showDialog<bool>(
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
                    title,
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
                    message,
                    style: TextStyle(fontSize: 14, color: colors.textSecondary),
                    textAlign: TextAlign.center,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
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
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
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
  }

  void _showCategoryDialog({Category? c, required CategoryType type}) async {
    final result = await showDialog(
      context: context,
      builder: (ctx) => CategoryDialog(category: c, type: type),
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
      bool confirmed = await _confirmDeletion(
        context,
        'delete_category_title'.tr(),
        'delete_category_message'.tr(args: [c.name]),
      );
      if (confirmed) {
        if (!mounted) return;
        setState(() => deletingIds.add(c.id));
        await Future.delayed(const Duration(milliseconds: 350));
        catProv.deleteCategory(c);
        if (mounted) setState(() => deletingIds.remove(c.id));
      }
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
          amount: result['amount'] ?? 0.0,
          budget: result['budget'],
          bgColor: CategoryDefaults.getBgColor(type),
          iconColor: CategoryDefaults.getIconColor(type),
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
        child: Builder(
          builder: (context) {
            final catProv = context.watch<CategoryProvider>();
            final txProv = context.watch<TransactionProvider>();

            if (catProv.isLoading || txProv.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            double totalBalance = catProv.accounts.fold(
              0,
              (sum, item) => sum + item.amount,
            );
            double totalIncomes = catProv.allCategoriesList
                .where((c) => c.type == CategoryType.income)
                .fold(0, (sum, item) => sum + item.amount.abs());
            double totalExpenses = catProv.allCategoriesList
                .where((c) => c.type == CategoryType.expense)
                .fold(0, (sum, item) => sum + item.amount.abs());
            final allCategories = catProv.allCategoriesList;

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
                    SummaryHeader(
                      totalBalance: totalBalance,
                      totalIncomes: totalIncomes,
                      totalExpenses: totalExpenses,
                      onBalanceTap: () {
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
                          builder: (_) => GeneralHistoryBottomSheet(
                            title: 'history_balance'.tr(),
                            filterType: CategoryType.account,
                            transactions: txProv.history,
                            allCategories: allCategories,
                            onDelete: (t) => context
                                .read<TransactionProvider>()
                                .deleteTransaction(t),
                            onEdit: (t) async {
                              final finance = context
                                  .read<TransactionProvider>();
                              final result =
                                  await showDialog<Map<String, dynamic>>(
                                    context: context,
                                    builder: (ctx) =>
                                        EditTransactionDialog(transaction: t),
                                  );
                              if (result != null) {
                                finance.editTransaction(
                                  t,
                                  result['amount'],
                                  result['date'],
                                );
                              }
                            },
                          ),
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
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (_) => GeneralHistoryBottomSheet(
                            title: 'history_incomes'.tr(),
                            filterType: CategoryType.income,
                            transactions: txProv.history,
                            allCategories: allCategories,
                            onDelete: (t) => context
                                .read<TransactionProvider>()
                                .deleteTransaction(t),
                            onEdit: (t) async {
                              final finance = context
                                  .read<TransactionProvider>();
                              final result =
                                  await showDialog<Map<String, dynamic>>(
                                    context: context,
                                    builder: (ctx) =>
                                        EditTransactionDialog(transaction: t),
                                  );
                              if (result != null) {
                                finance.editTransaction(
                                  t,
                                  result['amount'],
                                  result['date'],
                                );
                              }
                            },
                          ),
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
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (_) => GeneralHistoryBottomSheet(
                            title: 'history_expenses'.tr(),
                            filterType: CategoryType.expense,
                            transactions: txProv.history,
                            allCategories: allCategories,
                            onDelete: (t) => context
                                .read<TransactionProvider>()
                                .deleteTransaction(t),
                            onEdit: (t) async {
                              final finance = context
                                  .read<TransactionProvider>();
                              final result =
                                  await showDialog<Map<String, dynamic>>(
                                    context: context,
                                    builder: (ctx) =>
                                        EditTransactionDialog(transaction: t),
                                  );
                              if (result != null) {
                                finance.editTransaction(
                                  t,
                                  result['amount'],
                                  result['date'],
                                );
                              }
                            },
                          ),
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
                    _buildSection(catProv.incomes, CategoryType.income),
                    _buildSection(
                      catProv.accounts,
                      CategoryType.account,
                      isTarget: true,
                    ),
                    Expanded(
                      child: _buildSection(
                        catProv.expenses,
                        CategoryType.expense,
                        isTarget: true,
                        isGrid: true,
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
        child: normalCoin,
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
            final catProv = context.watch<CategoryProvider>();
            final txProv = context.watch<TransactionProvider>();
            return HistoryBottomSheet(
              category: c,
              transactions: txProv.history,
              allCategories: catProv.allCategoriesList,
              onDelete: (t) =>
                  context.read<TransactionProvider>().deleteTransaction(t),
              onEdit: (t) async {
                final finance = context.read<TransactionProvider>();
                final result = await showDialog<Map<String, dynamic>>(
                  context: context,
                  builder: (ctx) => EditTransactionDialog(transaction: t),
                );
                if (result != null) {
                  finance.editTransaction(t, result['amount'], result['date']);
                }
              },
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
      } else if (c.type == CategoryType.expense) {
        return GestureDetector(
          onTap: openHistory,
          child: LongPressDraggable<Category>(
            data: c,
            maxSimultaneousDrags: 1,
            delay: const Duration(milliseconds: 250),
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
            child: isBeingDragged ? emptySpace : coin,
          ),
        );
      } else {
        return GestureDetector(
          onTap: openHistory,
          onLongPress: () async {
            if (await Vibration.hasVibrator() == true) {
              Vibration.vibrate(duration: 15, amplitude: 40);
            }
            setState(() {
              isEditMode = true;
              _jiggleController.repeat();
            });
          },
          child: coin,
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
