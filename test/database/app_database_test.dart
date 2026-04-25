import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:drift/drift.dart';
import 'package:coin_flow/database/app_database.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    // Важливо: ми передаємо NativeDatabase.memory() у конструктор.
    // Наша нова фабрика бачить, що передано executor, і створює
    // НОВИЙ екземпляр спеціально для тесту, ігноруючи Singleton.
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  group('AppDatabase - Фільтрація та логіка Кошика', () {
    test(
      'getFilteredTransactions приховує видалені записи за замовчуванням',
      () async {
        final now = DateTime.now();

        // 1. Додаємо живу транзакцію
        await db
            .into(db.transactions)
            .insert(
              TransactionsCompanion.insert(
                id: 'active_1',
                fromId: 'acc_1',
                toId: 'cat_1',
                title: 'Active TX',
                date: now,
                amount: 100,
                currency: 'UAH',
                baseCurrency: 'UAH',
              ),
            );

        // 2. Додаємо "видалену" транзакцію (з міткою deletedAt)
        await db
            .into(db.transactions)
            .insert(
              TransactionsCompanion.insert(
                id: 'deleted_1',
                fromId: 'acc_1',
                toId: 'cat_1',
                title: 'Deleted TX',
                date: now,
                amount: 200,
                currency: 'UAH',
                baseCurrency: 'UAH',
                deletedAt: Value(now), // Логічне видалення
              ),
            );

        // 3. Перевіряємо звичайний запит
        final alive = await db.getFilteredTransactions();
        expect(alive.length, 1);
        expect(alive.first.id, 'active_1');

        // 4. Перевіряємо запит для Кошика
        final all = await db.getFilteredTransactions(includeDeleted: true);
        expect(all.length, 2);
      },
    );

    test(
      'Логіка "Кінець дня" правильно включає транзакції о 23:59:59',
      () async {
        final targetDate = DateTime(2026, 4, 25);

        // Транзакція в останню хвилину дня
        await db
            .into(db.transactions)
            .insert(
              TransactionsCompanion.insert(
                id: 'late_tx',
                fromId: 'a',
                toId: 'b',
                title: 'Late night buy',
                date: DateTime(2026, 4, 25, 23, 59, 30),
                amount: 50,
                currency: 'UAH',
                baseCurrency: 'UAH',
              ),
            );

        // Фільтруємо суворо по 25 квітня
        final result = await db.getFilteredTransactions(
          startDate: targetDate,
          endDate: targetDate,
        );

        expect(
          result.length,
          1,
          reason: 'Транзакція повинна потрапити в інтервал дня',
        );
      },
    );

    test('Фільтр категорій працює через OR (fromId або toId)', () async {
      await db
          .into(db.transactions)
          .insert(
            TransactionsCompanion.insert(
              id: 'tx_1',
              fromId: 'my_card', // Категорія, яку шукаємо
              toId: 'food',
              title: 'Dinner',
              date: DateTime.now(),
              amount: 150,
              currency: 'UAH',
              baseCurrency: 'UAH',
            ),
          );

      final result = await db.getFilteredTransactions(
        filterCategoryIds: ['my_card'],
      );

      expect(result.length, 1);
    });
  });

  group('AppDatabase - Схема та Міграції', () {
    test('Версія схеми має бути 2', () {
      expect(db.schemaVersion, 2);
    });
  });

  group('AppDatabase - Singleton check', () {
    test('Фабрика повертає той самий екземпляр (Singleton) без параметрів', () {
      // Для цього тесту не використовуємо db з setUp
      final db1 = AppDatabase();
      final db2 = AppDatabase();

      expect(identical(db1, db2), true);
    });
  });
}
