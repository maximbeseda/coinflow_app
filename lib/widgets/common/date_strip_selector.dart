import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../theme/app_colors_extension.dart';

// === МАГІЯ НАЙВИЩОГО РІВНЯ: ВЛАСНА ФІЗИКА КІНЕТИЧНОГО СКРОЛУ ===
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
      // Якщо просто вели пальцем і відпустили - дотягуємо до найближчої дати
      targetPage = currentPage.roundToDouble();
    } else {
      // --- ЖОРСТКИЙ ЛІМІТЕР КРОКІВ ---
      int jumpSteps = 1; // За замовчуванням легкий свайп = 1 дата
      if (velocity.abs() > 1000) jumpSteps = 2; // Середній свайп = 2 дати
      if (velocity.abs() > 2500) jumpSteps = 3; // Сильний свайп = 3 дати
      if (velocity.abs() > 4000) {
        jumpSteps = 7; // Дуже сильний ривок = 7 дати (стеля)
      }

      if (velocity > 0) {
        // Свайпнули вліво (мотаємо дати вперед)
        targetPage = currentPage.floorToDouble() + jumpSteps;
      } else {
        // Свайпнули вправо (мотаємо дати назад)
        targetPage = currentPage.ceilToDouble() - jumpSteps;
      }
    }

    final double targetPixels = targetPage * pageWidth;

    if (targetPixels == position.pixels &&
        velocity.abs() < currentTolerance.velocity) {
      return null;
    }

    // Робимо пружину жорсткішою, щоб дата фіксувалась чітко і приємно
    final SpringDescription customSpring = SpringDescription(
      mass: spring.mass,
      stiffness: spring.stiffness * 2.0, // Удвічі жорсткіша
      damping: spring.damping * 1.3, // Швидше гасить коливання в кінці
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

  final double _viewportFraction = 0.32;
  int _currentIndex = 10000;

  // БЕЗПЕЧНИЙ розрахунок різниці в днях (ігнорує літній/зимовий час)
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

    // ФІКС 1: Використовуємо безпечний розрахунок
    final initialOffset = _getDaysDifference(widget.selectedDate, _baseDate);
    _currentIndex = _baseIndex + initialOffset;

    _pageController = PageController(
      initialPage: _currentIndex,
      viewportFraction: _viewportFraction,
    );
  }

  @override
  void didUpdateWidget(covariant DateStripSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedDate != oldWidget.selectedDate) {
      // ФІКС 2: Використовуємо безпечний розрахунок
      final targetPage =
          _baseIndex + _getDaysDifference(widget.selectedDate, _baseDate);
      if (_pageController.hasClients && _currentIndex != targetPage) {
        _scrollToIndex(targetPage);
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _scrollToIndex(int index) {
    if (!_pageController.hasClients) return;
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOutCubic,
    );
  }

  String _getTopNumber(DateTime date) {
    return DateFormat('dd').format(date);
  }

  String _getBottomText(DateTime date, BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // ФІКС 3: Безпечний розрахунок і тут, щоб уникнути багів з написом "Вчора/Сьогодні"
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
            child: Container(
              width: 50,
              height: 50,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(16),
              ),
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
              // Подвійний тап повертає на сьогоднішню дату
              onDoubleTap: () => _scrollToIndex(_baseIndex),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Рамка навколо центральної дати
                  FractionallySizedBox(
                    widthFactor: _viewportFraction,
                    heightFactor: 1,
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: colors.textSecondary.withValues(alpha: 0.15),
                          width: 1.5,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),

                  PageView.builder(
                    controller: _pageController,
                    physics: const CustomSnappingScrollPhysics(),
                    pageSnapping: false,
                    onPageChanged: (index) {
                      setState(() => _currentIndex = index);

                      // ФІКС 4: Відправляємо нову дату миттєво!
                      final offsetDays = index - _baseIndex;
                      final newDate = DateTime(
                        _baseDate.year,
                        _baseDate.month,
                        _baseDate.day + offsetDays,
                      );

                      if (widget.selectedDate.year != newDate.year ||
                          widget.selectedDate.month != newDate.month ||
                          widget.selectedDate.day != newDate.day) {
                        widget.onDateChanged(newDate);
                      }
                    },
                    itemBuilder: (context, index) {
                      final offset = index - _baseIndex;
                      // ФІКС 5: Ідеальний розрахунок дати без прив'язки до 24 годин
                      final date = DateTime(
                        _baseDate.year,
                        _baseDate.month,
                        _baseDate.day + offset,
                      );
                      final isSelected = index == _currentIndex;

                      return GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => _scrollToIndex(index),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              AnimatedDefaultTextStyle(
                                duration: const Duration(milliseconds: 150),
                                style: TextStyle(
                                  fontSize: isSelected ? 22 : 18,
                                  fontWeight: isSelected
                                      ? FontWeight.w800
                                      : FontWeight.w600,
                                  color: isSelected
                                      ? colors.textMain
                                      : colors.textSecondary.withValues(
                                          alpha: 0.4,
                                        ),
                                  height: 1.0,
                                ),
                                child: Text(_getTopNumber(date)),
                              ),
                              const SizedBox(height: 2),
                              AnimatedDefaultTextStyle(
                                duration: const Duration(milliseconds: 150),
                                style: TextStyle(
                                  fontSize: isSelected ? 12 : 11,
                                  fontWeight: FontWeight.w600,
                                  color: isSelected
                                      ? colors.textSecondary
                                      : colors.textSecondary.withValues(
                                          alpha: 0.4,
                                        ),
                                ),
                                child: Text(
                                  _getBottomText(date, context),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
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
