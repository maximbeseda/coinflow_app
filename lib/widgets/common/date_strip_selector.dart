import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../theme/app_colors_extension.dart';

// === ТВОРЯ ІДЕАЛЬНА ФІЗИКА КІНЕТИЧНОГО СКРОЛУ ===
class CustomSnappingScrollPhysics extends ScrollPhysics {
  const CustomSnappingScrollPhysics({super.parent});

  @override
  CustomSnappingScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return CustomSnappingScrollPhysics(parent: buildParent(ancestor));
  }

  @override
  Simulation? createBallisticSimulation(
    ScrollMetrics position,
    double velocity,
  ) {
    if ((velocity <= 0.0 && position.pixels <= position.minScrollExtent) ||
        (velocity >= 0.0 && position.pixels >= position.maxScrollExtent)) {
      return super.createBallisticSimulation(position, velocity);
    }

    if (position is! PageMetrics) {
      return super.createBallisticSimulation(position, velocity);
    }

    final double pageWidth =
        position.viewportDimension * position.viewportFraction;
    final double currentPage = position.pixels / pageWidth;
    final Tolerance currentTolerance = toleranceFor(position);

    double targetPage;

    if (velocity.abs() < currentTolerance.velocity) {
      targetPage = currentPage.roundToDouble();
    } else {
      int jumpSteps = 1;
      if (velocity.abs() > 1000) jumpSteps = 2;
      if (velocity.abs() > 2500) jumpSteps = 3;
      if (velocity.abs() > 4000) {
        jumpSteps = 7;
      }

      if (velocity > 0) {
        targetPage = currentPage.floorToDouble() + jumpSteps;
      } else {
        targetPage = currentPage.ceilToDouble() - jumpSteps;
      }
    }

    final double targetPixels = targetPage * pageWidth;

    if (targetPixels == position.pixels &&
        velocity.abs() < currentTolerance.velocity) {
      return null;
    }

    final SpringDescription customSpring = SpringDescription(
      mass: spring.mass,
      stiffness: spring.stiffness * 2.0,
      damping: spring.damping * 1.3,
    );

    return SpringSimulation(
      customSpring,
      position.pixels,
      targetPixels,
      velocity,
      tolerance: currentTolerance,
    );
  }
}

class DateStripSelector extends StatefulWidget {
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateChanged;
  final VoidCallback onCalendarTap;

  const DateStripSelector({
    super.key,
    required this.selectedDate,
    required this.onDateChanged,
    required this.onCalendarTap,
  });

  @override
  State<DateStripSelector> createState() => _DateStripSelectorState();
}

class _DateStripSelectorState extends State<DateStripSelector> {
  late PageController _pageController;
  final int _baseIndex = 10000;
  late DateTime _baseDate;
  final double _viewportFraction = 0.35;
  int _currentIndex = 10000;

  // 👇 НОВИЙ ЗАПОБІЖНИК: чи крутиться стрічка автоматично
  bool _isProgrammaticScroll = false;

  int _getDaysDifference(DateTime target, DateTime base) {
    final targetUtc = DateTime.utc(target.year, target.month, target.day);
    final baseUtc = DateTime.utc(base.year, base.month, base.day);
    return targetUtc.difference(baseUtc).inDays;
  }

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _baseDate = DateTime(now.year, now.month, now.day);

    final initialPage =
        _baseIndex + _getDaysDifference(widget.selectedDate, _baseDate);
    _currentIndex = initialPage;

    _pageController = PageController(
      initialPage: initialPage,
      viewportFraction: _viewportFraction,
    );
  }

  // 👇 ВИПРАВЛЕНО: Стрічка реагує на зовнішню зміну дати (з календаря)
  @override
  void didUpdateWidget(covariant DateStripSelector oldWidget) {
    super.didUpdateWidget(oldWidget);

    final oldDays = _getDaysDifference(oldWidget.selectedDate, _baseDate);
    final newDays = _getDaysDifference(widget.selectedDate, _baseDate);

    if (oldDays != newDays) {
      final targetPage = _baseIndex + newDays;

      if (_pageController.hasClients && _currentIndex != targetPage) {
        // Активуємо запобіжник перед тим, як крутити
        _isProgrammaticScroll = true;
        _currentIndex = targetPage;

        _pageController
            .animateToPage(
              targetPage,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
            )
            .then((_) {
              // Знімаємо блок після закінчення прокрутки
              if (mounted) _isProgrammaticScroll = false;
            });
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _scrollToIndex(int index) {
    if (_pageController.hasClients) {
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  String _getBottomText(DateTime date, BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final diff = _getDaysDifference(date, today);

    if (diff == 0) return 'today'.tr();
    if (diff == -1) return 'yesterday'.tr();
    if (diff == 1) return 'tomorrow'.tr();

    final locale = context.locale.languageCode;
    return DateFormat('MMM, E', locale).format(date);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColorsExtension>()!;

    return SizedBox(
      height: 60,
      child: Row(
        children: [
          GestureDetector(
            onTap: widget.onCalendarTap,
            child: SizedBox(
              width: 50,
              child: Icon(
                Icons.calendar_month_rounded,
                size: 24,
                color: colors.textSecondary,
              ),
            ),
          ),

          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onDoubleTap: () => _scrollToIndex(_baseIndex),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  IgnorePointer(
                    child: FractionallySizedBox(
                      widthFactor: _viewportFraction,
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: colors.textSecondary.withValues(alpha: 0.15),
                            width: 1.5,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),

                  AnimatedBuilder(
                    animation: _pageController,
                    builder: (context, child) {
                      return PageView.builder(
                        controller: _pageController,
                        physics: const CustomSnappingScrollPhysics(),
                        pageSnapping: false,
                        onPageChanged: (index) {
                          // 👇 ВИПРАВЛЕНО: Якщо крутить календар, ми не відправляємо дату назад
                          if (_isProgrammaticScroll) return;

                          setState(() => _currentIndex = index);
                          final newDate = _baseDate.add(
                            Duration(days: index - _baseIndex),
                          );
                          widget.onDateChanged(newDate);
                        },
                        itemBuilder: (context, index) {
                          final date = _baseDate.add(
                            Duration(days: index - _baseIndex),
                          );

                          double pageOffset = 0;
                          if (_pageController.hasClients) {
                            pageOffset =
                                (_pageController.page ??
                                    _pageController.initialPage.toDouble()) -
                                index;
                          } else {
                            pageOffset = (_pageController.initialPage - index)
                                .toDouble();
                          }

                          double scale = (1.0 - (pageOffset.abs() * 0.2)).clamp(
                            0.8,
                            1.0,
                          );
                          double opacity = (1.0 - (pageOffset.abs() * 0.5))
                              .clamp(0.4, 1.0);

                          return GestureDetector(
                            onTap: () => _scrollToIndex(index),
                            behavior: HitTestBehavior.opaque,
                            child: Opacity(
                              opacity: opacity,
                              child: Transform.scale(
                                scale: scale,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      DateFormat('dd').format(date),
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w800,
                                        color: colors.textMain,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      _getBottomText(date, context),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: colors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
