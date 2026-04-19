import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

part 'app_database.g.dart';

enum CategoryType { income, account, expense }

// ==========================================
// ТАБЛИЦІ
// ==========================================

class Categories extends Table {
  TextColumn get id => text()();
  IntColumn get type => intEnum<CategoryType>()();
  TextColumn get name => text()();
  IntColumn get icon => integer()();
  IntColumn get bgColor => integer()();
  IntColumn get iconColor => integer()();
  IntColumn get amount => integer().withDefault(const Constant(0))();
  IntColumn get budget => integer().nullable()();
  BoolColumn get isArchived => boolean().withDefault(const Constant(false))();
  TextColumn get currency => text().withDefault(const Constant('UAH'))();
  BoolColumn get includeInTotal =>
      boolean().withDefault(const Constant(true))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  // 👇 ДОДАНО ДЛЯ КОШИКА
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class Transactions extends Table {
  TextColumn get id => text()();
  TextColumn get fromId => text()();
  TextColumn get toId => text()();
  TextColumn get title => text()();
  DateTimeColumn get date => dateTime()();

  // Source
  IntColumn get amount => integer()();
  TextColumn get currency => text()();

  // Target
  IntColumn get targetAmount => integer().nullable()();
  TextColumn get targetCurrency => text().nullable()();

  // Base
  IntColumn get baseAmount => integer().withDefault(const Constant(0))();
  TextColumn get baseCurrency => text()();

  // 👇 ДОДАНО ДЛЯ КОШИКА
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class Subscriptions extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  IntColumn get amount => integer()();
  TextColumn get categoryId => text()();
  TextColumn get accountId => text()();
  DateTimeColumn get nextPaymentDate => dateTime()();
  TextColumn get periodicity => text().withDefault(const Constant('monthly'))();
  IntColumn get customIconCodePoint => integer().nullable()();
  BoolColumn get isAutoPay => boolean().withDefault(const Constant(false))();
  TextColumn get currency => text().withDefault(const Constant('UAH'))();

  // 👇 ДОДАНО ДЛЯ КОШИКА
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

// ==========================================
// БАЗА ДАНИХ ТА ЗАПИТИ
// ==========================================

@DriftDatabase(tables: [Categories, Transactions, Subscriptions])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  // 👇 ЗБІЛЬШИЛИ ВЕРСІЮ СХЕМИ ДО 2
  @override
  int get schemaVersion => 2;

  // 👇 ДОДАЛИ МІГРАЦІЮ, ЩОБ НЕ ЗЛАМАТИ ІСНУЮЧУ БАЗУ
  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        if (from < 2) {
          // Якщо оновлюємося з 1-ї версії до 2-ї, просто додаємо нові колонки
          await m.addColumn(categories, categories.deletedAt);
          await m.addColumn(transactions, transactions.deletedAt);
          await m.addColumn(subscriptions, subscriptions.deletedAt);
        }
      },
    );
  }

  Future<List<Transaction>> getFilteredTransactions({
    DateTime? startDate,
    DateTime? endDate,
    List<String>? filterCategoryIds,
    String? currency,
    int? limit,
    int? offset,
    // 👇 Додаємо можливість явно просити видалені або ні (за замовчуванням - тільки живі)
    bool includeDeleted = false,
  }) {
    final query = select(transactions);

    query.where((t) {
      Expression<bool> predicate = const Constant(true);

      // Фільтруємо кошик
      if (!includeDeleted) {
        predicate = predicate & t.deletedAt.isNull();
      }

      if (startDate != null && endDate != null) {
        final endOfDay = DateTime(
          endDate.year,
          endDate.month,
          endDate.day,
          23,
          59,
          59,
        );
        predicate = predicate & t.date.isBetweenValues(startDate, endOfDay);
      } else if (startDate != null) {
        predicate = predicate & t.date.isBiggerOrEqualValue(startDate);
      } else if (endDate != null) {
        final endOfDay = DateTime(
          endDate.year,
          endDate.month,
          endDate.day,
          23,
          59,
          59,
        );
        predicate = predicate & t.date.isSmallerOrEqualValue(endOfDay);
      }

      if (filterCategoryIds != null && filterCategoryIds.isNotEmpty) {
        predicate =
            predicate &
            (t.fromId.isIn(filterCategoryIds) | t.toId.isIn(filterCategoryIds));
      }

      if (currency != null && currency.isNotEmpty) {
        predicate =
            predicate &
            (t.currency.equals(currency) | t.targetCurrency.equals(currency));
      }

      return predicate;
    });

    query.orderBy([
      (t) => OrderingTerm(expression: t.date, mode: OrderingMode.desc),
    ]);

    if (limit != null) {
      query.limit(limit, offset: offset);
    }

    return query.get();
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'coinflow_db.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
