import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_database.dart';
import 'legacy_hive_models.dart';
import 'package:drift/drift.dart' as drift;
import 'package:drift/drift.dart'; // Додано для доступу до InsertMode

class MigrationService {
  static const String _migrationKey = 'is_migrated_to_drift_v1';

  static Future<void> runMigrationIfNeeded(AppDatabase db) async {
    final prefs = await SharedPreferences.getInstance();
    final isMigrated = prefs.getBool(_migrationKey) ?? false;

    if (isMigrated) {
      return; // Вже мігрували, нічого не робимо
    }

    debugPrint('🔄 ПОЧАТОК МІГРАЦІЇ ДАНИХ З HIVE У DRIFT...');

    // 1. Реєструємо старі адаптери (з перевіркою, щоб не реєструвати двічі)
    if (!Hive.isAdapterRegistered(4)) {
      Hive.registerAdapter(LegacyColorAdapter());
    }
    if (!Hive.isAdapterRegistered(5)) {
      Hive.registerAdapter(LegacyIconDataAdapter());
    }
    if (!Hive.isAdapterRegistered(3)) {
      Hive.registerAdapter(LegacyCategoryTypeAdapter());
    }
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(LegacyCategoryAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(LegacyTransactionAdapter());
    }
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(LegacySubscriptionAdapter());
    }

    // 2. Відкриваємо старі коробки
    final catBox = await Hive.openBox('categories');
    final txBox = await Hive.openBox('transactions');
    final subBox = await Hive.openBox('subscriptions');

    // 3. Читаємо дані (приводимо до старих типів)
    final oldCategories = catBox.values.cast<HiveCategory>().toList();
    final oldTransactions = txBox.values.cast<HiveTransaction>().toList();
    final oldSubscriptions = subBox.values.cast<HiveSubscription>().toList();

    debugPrint(
      '📦 Знайдено: ${oldCategories.length} категорій, ${oldTransactions.length} транзакцій, ${oldSubscriptions.length} підписок.',
    );

    // 4. Пакетно вставляємо все в Drift
    await db.batch((batch) {
      // КАТЕГОРІЇ
      if (oldCategories.isNotEmpty) {
        // Використовуємо asMap().entries, щоб отримати порядковий індекс
        batch.insertAll(
          db.categories,
          oldCategories.asMap().entries.map((entry) {
            final index = entry.key; // Позиція в списку Hive
            final c = entry.value;
            return CategoriesCompanion.insert(
              id: c.id,
              type: CategoryType.values[c.type.index],
              name: c.name,
              icon: c.icon.codePoint,
              bgColor: c.bgColor.toARGB32(),
              iconColor: c.iconColor.toARGB32(),
              amount: drift.Value(c.amount),
              budget: drift.Value(c.budget),
              isArchived: drift.Value(c.isArchived),
              currency: drift.Value(c.currency),
              includeInTotal: drift.Value(c.includeInTotal),
              sortOrder: drift.Value(index), // 👇 ЗБЕРІГАЄМО ПОРЯДОК
            );
          }).toList(),
          mode: InsertMode.insertOrReplace,
        );
      }

      // ТРАНЗАКЦІЇ
      if (oldTransactions.isNotEmpty) {
        batch.insertAll(
          db.transactions,
          oldTransactions.map(
            (t) => TransactionsCompanion.insert(
              id: t.id,
              fromId: t.fromId,
              toId: t.toId,
              title: t.title,
              date: t.date,
              amount: t.amount,
              currency: t.currency,
              targetAmount: drift.Value(t.targetAmount),
              targetCurrency: drift.Value(t.targetCurrency),
              baseAmount: drift.Value(t.baseAmount),
              baseCurrency: t.baseCurrency,
            ),
          ),
          mode: InsertMode.insertOrReplace,
        );
      }

      // ПІДПИСКИ
      if (oldSubscriptions.isNotEmpty) {
        batch.insertAll(
          db.subscriptions,
          oldSubscriptions.map(
            (s) => SubscriptionsCompanion.insert(
              id: s.id,
              name: s.name,
              amount: s.amount,
              categoryId: s.categoryId,
              accountId: s.accountId,
              nextPaymentDate: s.nextPaymentDate,
              periodicity: drift.Value(s.periodicity),
              customIconCodePoint: drift.Value(s.customIconCodePoint),
              isAutoPay: drift.Value(s.isAutoPay),
              currency: drift.Value(s.currency),
            ),
          ),
          mode: InsertMode.insertOrReplace,
        );
      }
    });

    // 5. Позначаємо міграцію як успішну
    await prefs.setBool(_migrationKey, true);

    // Очищення боксів Hive (за бажанням можна закоментувати для додаткової безпеки)
    await catBox.clear();
    await txBox.clear();
    await subBox.clear();

    debugPrint('✅ МІГРАЦІЯ УСПІШНО ЗАВЕРШЕНА!');
  }
}
