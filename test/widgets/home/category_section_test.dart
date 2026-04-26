import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:coin_flow/widgets/home/category_section.dart';
import 'package:coin_flow/database/app_database.dart';
import '../../helpers/test_wrapper.dart';

class MockCategory extends Mock implements Category {}

void main() {
  void setupScreenSize(WidgetTester tester) {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
  }

  group('CategorySection Tests', () {
    late MockCategory testCategory;

    setUp(() {
      testCategory = MockCategory();

      when(() => testCategory.id).thenReturn('test_cat_1');
      when(() => testCategory.type).thenReturn(CategoryType.expense);
      when(() => testCategory.name).thenReturn('Їжа');
      when(() => testCategory.bgColor).thenReturn(0xFF4361EE);
      when(() => testCategory.icon).thenReturn(0xe25a);
      when(() => testCategory.iconColor).thenReturn(0xFFFFFFFF);
      when(() => testCategory.amount).thenReturn(0);
      when(() => testCategory.currency).thenReturn('₴');
      // Видалили вигадані orderIndex та isDeleted
    });

    testWidgets('1. Рендерить секцію, кнопку Add та список категорій', (
      WidgetTester tester,
    ) async {
      setupScreenSize(tester);

      await tester.pumpWidget(
        ProviderScope(
          child: makeTestableWidget(
            child: CategorySection(
              categories: [testCategory],
              type: CategoryType.expense,
              onTransfer: (_, _) {}, // Виправили __ на _
              onHistoryTap: (_) {},
              onEditTap: (_) async => null,
              onAddTap: () {},
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(Duration.zero);

      expect(find.byType(PageView), findsOneWidget);
      expect(find.byIcon(Icons.add), findsOneWidget);
      expect(find.byType(LongPressDraggable<Category>), findsOneWidget);

      addTearDown(tester.view.resetPhysicalSize);
    });

    testWidgets('2. Натискання на кнопку Add викликає onAddTap', (
      WidgetTester tester,
    ) async {
      setupScreenSize(tester);
      bool isAddTapped = false;

      await tester.pumpWidget(
        ProviderScope(
          child: makeTestableWidget(
            child: CategorySection(
              categories: const [],
              type: CategoryType.expense,
              onTransfer: (_, _) {}, // Виправили __ на _
              onHistoryTap: (_) {},
              onEditTap: (_) async => null,
              onAddTap: () {
                isAddTapped = true;
              },
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(Duration.zero);

      final addBtnFinder = find.byIcon(Icons.add);
      expect(addBtnFinder, findsOneWidget);

      await tester.tap(addBtnFinder);
      await tester.pumpAndSettle();

      expect(isAddTapped, isTrue);

      addTearDown(tester.view.resetPhysicalSize);
    });

    testWidgets(
      '3. Натискання на категорію в звичайному режимі викликає onHistoryTap',
      (WidgetTester tester) async {
        setupScreenSize(tester);
        Category? tappedCategory;

        await tester.pumpWidget(
          ProviderScope(
            child: makeTestableWidget(
              child: CategorySection(
                categories: [testCategory],
                type: CategoryType.expense,
                onTransfer: (_, _) {}, // Виправили __ на _
                onHistoryTap: (cat) {
                  tappedCategory = cat;
                },
                onEditTap: (_) async => null,
                onAddTap: () {},
              ),
            ),
          ),
        );

        await tester.pump();
        await tester.pump(Duration.zero);

        final draggableFinder = find.byType(LongPressDraggable<Category>);
        expect(draggableFinder, findsOneWidget);

        await tester.tap(draggableFinder);
        await tester.pumpAndSettle();

        expect(tappedCategory, isNotNull);
        expect(tappedCategory?.id, equals('test_cat_1'));

        addTearDown(tester.view.resetPhysicalSize);
      },
    );
  });
}
