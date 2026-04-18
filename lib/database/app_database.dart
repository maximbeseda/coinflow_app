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

  @override
  Set<Column> get primaryKey => {id};
}

// ==========================================
// БАЗА ДАНИХ ТА ЗАПИТИ
// ==========================================

@DriftDatabase(tables: [Categories, Transactions, Subscriptions])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  // 👇 ДОДАНО: limit та offset для пагінації
  Future<List<Transaction>> getFilteredTransactions({
    DateTime? startDate,
    DateTime? endDate,
    List<String>? filterCategoryIds,
    String? currency,
    int? limit,
    int? offset,
  }) {
    final query = select(transactions);

    query.where((t) {
      Expression<bool> predicate = const Constant(true);

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

    // 👇 НОВЕ: Застосовуємо пагінацію на рівні SQL
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
