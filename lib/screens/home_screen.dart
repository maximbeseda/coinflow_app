import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:vibration/vibration.dart';
import 'package:provider/provider.dart';
import '../models/category_model.dart';
import '../models/subscription_model.dart';
import '../widgets/coin_widget.dart';
import '../widgets/history_bottom_sheet.dart';
import '../widgets/summary_header.dart';
import '../widgets/general_history_bottom_sheet.dart';
import '../widgets/settings_drawer.dart';
import '../widgets/dialogs/transfer_dialog.dart';
import '../widgets/dialogs/category_dialog.dart';
import '../widgets/dialogs/edit_transaction_dialog.dart';
import '../widgets/dialogs/due_subscription_dialog.dart';
import '../utils/currency_formatter.dart';
import '../providers/finance_provider.dart';

String formatCurrency(double amount) => CurrencyFormatter.format(amount);

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  final Color colorBlueGrey = const Color(0xFFD1D9E6);
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  List<String> deletingIds = [];
  bool isEditMode = false;
  String? draggedCategoryId;
  late AnimationController _jiggleController;

  final Map<String, PageController> _pageControllers = {};

  // Прапорець для запобігання дублювання діалогів
  bool _isShowingDueDialog = false;

  @override
  void initState() {
    super.initState();
    _jiggleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );

    // Додаємо слухача, який перевірятиме підписки при кожній зміні в провайдері
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final financeProvider = context.read<FinanceProvider>();
      financeProvider.addListener(_checkDueSubscriptions);
      // Перша перевірка при запуску
      _checkDueSubscriptions();
    });
  }

  // Метод перевірки наявності платежів
  void _checkDueSubscriptions() {
    if (!mounted) return;
    final provider = context.read<FinanceProvider>();

    // Якщо є підписки до оплати і діалог ще НЕ відкритий
    if (provider.dueSubscriptions.isNotEmpty &&
        !provider.isLoading &&
        !_isShowingDueDialog) {
      _showDueSubscriptionDialog(provider.dueSubscriptions.first);
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
    // Важливо видалити слухача при видаленні екрана
    try {
      context.read<FinanceProvider>().removeListener(_checkDueSubscriptions);
    } catch (_) {}

    _jiggleController.dispose();
    for (var ctrl in _pageControllers.values) {
      ctrl.dispose();
    }
    super.dispose();
  }

  // Решта твого коду (handleTransfer, confirmDeletion, build тощо)...
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
      context.read<FinanceProvider>().addTransfer(
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
    return await showDialog<bool>(
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
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    message,
                    style: const TextStyle(fontSize: 14, color: Colors.black54),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  Row(
                    children: [
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
    final provider = context.read<FinanceProvider>();

    if (result == 'delete' && c != null) {
      bool confirmed = await _confirmDeletion(
        context,
        "Видалити категорію?",
        "Ви впевнені, що хочете видалити '${c.name}'? Це також видалить історію операцій.",
      );
      if (confirmed) {
        if (!mounted) return;
        setState(() => deletingIds.add(c.id));
        await Future.delayed(const Duration(milliseconds: 350));
        provider.deleteCategory(c);
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
          bgColor: type == CategoryType.income
              ? Colors.black
              : (type == CategoryType.account
                    ? const Color(0xFF2C2C2E)
                    : const Color(0xFFE5E5EA)),
          iconColor: type == CategoryType.expense ? Colors.black : Colors.white,
        );
        provider.addOrUpdateCategory(n);
      } else {
        c.name = result['name'];
        c.icon = result['icon'];
        c.budget = result['budget'];
        if (type == CategoryType.account) {
          c.amount = result['amount'] ?? c.amount;
        }
        provider.addOrUpdateCategory(c);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<FinanceProvider>(context);

    // ПРАВИЛЬНИЙ ВИКЛИК:
    if (provider.dueSubscriptions.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showDueSubscriptionDialog(provider.dueSubscriptions.first);
      });
    }
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
        child: Consumer<FinanceProvider>(
          builder: (context, provider, child) {
            if (provider.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            double totalBalance = provider.accounts.fold(
              0,
              (sum, item) => sum + item.amount,
            );
            double totalExpenses = provider.expenses.fold(
              0,
              (sum, item) => sum + item.amount.abs(),
            );
            final allCategories = provider.allCategoriesList;

            return Container(
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
                maintainBottomViewPadding: true,
                child: Column(
                  children: [
                    SummaryHeader(
                      totalBalance: totalBalance,
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
                            title: "Історія: Баланс",
                            filterType: CategoryType.account,
                            transactions: provider.history,
                            allCategories: allCategories,
                            onDelete: (t) => context
                                .read<FinanceProvider>()
                                .deleteTransaction(t),
                            onEdit: (t) async {
                              final finance = context.read<FinanceProvider>();
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
                            title: "Історія: Витрати",
                            filterType: CategoryType.expense,
                            transactions: provider.history,
                            allCategories: allCategories,
                            onDelete: (t) => context
                                .read<FinanceProvider>()
                                .deleteTransaction(t),
                            onEdit: (t) async {
                              final finance = context.read<FinanceProvider>();
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
                    _buildSection(provider.incomes, CategoryType.income),
                    _buildSection(
                      provider.accounts,
                      CategoryType.account,
                      isTarget: true,
                    ),
                    Expanded(
                      child: _buildSection(
                        provider.expenses,
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

  // Методи _buildSection, _buildCoin, _buildAddBtn залишаються без змін...
  Widget _buildSection(
    List<Category> list,
    CategoryType type, {
    bool isTarget = false,
    bool isGrid = false,
  }) {
    String typeKey = type.name;
    if (!_pageControllers.containsKey(typeKey)) {
      _pageControllers[typeKey] = PageController();
    }
    PageController pageCtrl = _pageControllers[typeKey]!;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
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
    bool isDeleting = deletingIds.contains(c.id);
    final provider = context.read<FinanceProvider>();

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
        builder: (_) => HistoryBottomSheet(
          category: c,
          transactions: provider.history,
          allCategories: provider.allCategoriesList,
          onDelete: (t) => context.read<FinanceProvider>().deleteTransaction(t),
          onEdit: (t) async {
            final finance = context.read<FinanceProvider>();
            final result = await showDialog<Map<String, dynamic>>(
              context: context,
              builder: (ctx) => EditTransactionDialog(transaction: t),
            );
            if (result != null) {
              finance.editTransaction(t, result['amount'], result['date']);
            }
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
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
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
          builder: (context, child) {
            final angle =
                math.sin(_jiggleController.value * math.pi * 2) * 0.04;
            return Transform.rotate(angle: angle, child: child);
          },
          child: coin,
        );
      }

      Widget emptySpace = Opacity(opacity: 0.0, child: coin);
      Widget dragFeedbackReorder = Material(
        color: Colors.transparent,
        child: CoinWidget(category: c),
      );

      Widget interactiveCoin;

      if (isEditMode) {
        interactiveCoin = GestureDetector(
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
        interactiveCoin = GestureDetector(
          onTap: openHistory,
          child: LongPressDraggable<Category>(
            data: c,
            maxSimultaneousDrags: 1,
            delay: const Duration(milliseconds: 250),
            onDragStarted: () async {
              bool? hasVibrator = await Vibration.hasVibrator();
              if (hasVibrator == true) {
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
        interactiveCoin = GestureDetector(
          onTap: openHistory,
          onLongPress: () async {
            bool? hasVibrator = await Vibration.hasVibrator();
            if (hasVibrator == true) {
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

      return interactiveCoin;
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
                    context.read<FinanceProvider>().reorderCategories(
                      source,
                      c,
                    );
                    return true;
                  }
                  return false;
                } else {
                  if (isSameGroup) {
                    if (source.type == CategoryType.account) return true;
                    return false;
                  }
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
                  bool isSameGroup = source.type == c.type;
                  if (isSameGroup && source.type != CategoryType.account) {
                    return;
                  }
                  _handleTransfer(source, c);
                }
              },
              builder: (_, candidateData, _) {
                bool isHovered = candidateData.isNotEmpty;
                return buildContent(isHovered);
              },
            )
          : buildContent(false),
    );
  }

  Widget _buildAddBtn(CategoryType type) => GestureDetector(
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
              color: Colors.grey.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.add, color: Colors.grey, size: 24),
          ),
          const SizedBox(height: 4),
          const Text("", style: TextStyle(fontSize: 10)),
        ],
      ),
    ),
  );
}
