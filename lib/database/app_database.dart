import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

// Це потрібно для генерації коду (з'явиться після запуску build_runner)
part 'app_database.g.dart';

// 1. Оголошуємо наш Enum для категорій (такий самий, як був)
enum CategoryType { income, account, expense }

// ==========================================
// ТАБЛИЦІ
// ==========================================

class Categories extends Table {
  TextColumn get id => text()(); // Робимо текстовий ID, як було в тебе
  IntColumn get type => intEnum<CategoryType>()();
  TextColumn get name => text()();
  IntColumn get icon => integer()(); // codePoint іконки
  IntColumn get bgColor => integer()(); // колір у форматі ARGB32
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
  TextColumn get fromId => text()(); // Посилання на рахунок/дохід
  TextColumn get toId => text()(); // Посилання на рахунок/витрату
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
// БАЗА ДАНИХ
// ==========================================

@DriftDatabase(tables: [Categories, Transactions, Subscriptions])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'coinflow_db.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
