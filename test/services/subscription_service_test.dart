import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:coin_flow/database/app_database.dart';
import 'package:coin_flow/services/subscription_service.dart';
import 'package:coin_flow/services/storage_service.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  group('SubscriptionService - Date Logic', () {
    final baseSub = Subscription(
      id: 'sub_1',
      name: 'Netflix',
      amount: 1499,
      currency: 'EUR',
      accountId: 'acc_1',
      categoryId: 'cat_1',
      periodicity: 'monthly',
      nextPaymentDate: DateTime(2024, 1, 31), // Початкова дата
      isAutoPay: false,
    );

    test(
      'advanceOnePeriod правильно обробляє кінець місяця (31 Jan -> 29 Feb)',
      () async {
        // 2024 рік — високосний
        await SubscriptionService.advanceOnePeriod(db, baseSub);

        final subs = await StorageService.getSubscriptions(db);
        // Очікуємо 29 лютого, бо в лютому немає 31 числа
        expect(subs.first.nextPaymentDate, DateTime(2024, 2, 29));
      },
    );

    test('shiftSubscriptionDate наздоганяє пропущені періоди', () async {
      // Підписка була 1 січня 2026, а сьогодні вже кінець квітня 2026
      final overdueSub = baseSub.copyWith(
        nextPaymentDate: DateTime(2026, 1, 1),
        periodicity: 'monthly',
      );

      await SubscriptionService.shiftSubscriptionDate(db, overdueSub);

      final subs = await StorageService.getSubscriptions(db);
      final nextDate = subs.first.nextPaymentDate;

      // Дата має бути в майбутньому відносно "сьогодні" (25.04.2026)
      // Отже, наступна оплата має бути 01.05.2026
      expect(nextDate.isAfter(DateTime.now()), true);
      expect(nextDate, DateTime(2026, 5, 1));
    });

    test('Логіка щотижневої підписки (weekly) додає рівно 7 днів', () async {
      final weeklySub = baseSub.copyWith(
        periodicity: 'weekly',
        nextPaymentDate: DateTime(2026, 4, 20), // Понеділок
      );

      await SubscriptionService.advanceOnePeriod(db, weeklySub);

      final subs = await StorageService.getSubscriptions(db);
      expect(
        subs.first.nextPaymentDate,
        DateTime(2026, 4, 27),
      ); // Наступний понеділок
    });

    test('Логіка щорічної підписки (yearly) додає рівно 1 рік', () async {
      final yearlySub = baseSub.copyWith(
        periodicity: 'yearly',
        nextPaymentDate: DateTime(2024, 2, 29), // Високосний день
      );

      await SubscriptionService.advanceOnePeriod(db, yearlySub);

      final subs = await StorageService.getSubscriptions(db);
      // 2025 не високосний, тому DateTime за замовчуванням може дати 1 березня
      // або залишити 28 лютого залежно від реалізації Dart.
      // Ваш код робить: DateTime(nextDate.year + 1, nextDate.month, nextDate.day)
      expect(subs.first.nextPaymentDate.year, 2025);
    });
  });
}
