import 'package:flutter_test/flutter_test.dart'; // 👈 Прибрали зайвий hide
import 'package:coin_flow/database/app_database.dart';
import 'package:coin_flow/services/backup_service.dart';

void main() {
  group('BackupService - Encryption & Decryption Engine', () {
    // 👈 Додали const для оптимізації пам'яті
    const dummyCategory = Category(
      id: 'cat_1',
      name: 'Test Category',
      type: CategoryType.expense,
      currency: 'UAH',
      amount: 0,
      icon: 1,
      bgColor: 1,
      iconColor: 1,
      isArchived: false,
      includeInTotal: true,
      sortOrder: 0,
    );

    // DateTime не може бути const, тому тут без нього
    final dummyTransaction = Transaction(
      id: 'tx_1',
      fromId: 'acc_1',
      toId: 'cat_1',
      title: 'Test Tx',
      amount: 100,
      date: DateTime(2026, 1, 1),
      currency: 'UAH',
      baseAmount: 100,
      baseCurrency: 'UAH',
    );

    final dummySubscription = Subscription(
      id: 'sub_1',
      name: 'Test Sub',
      amount: 50,
      currency: 'UAH',
      accountId: 'acc_1',
      categoryId: 'cat_1',
      periodicity: 'monthly',
      nextPaymentDate: DateTime(2026, 2, 1),
      isAutoPay: false,
    );

    test('Повний цикл: Експорт -> Шифрування -> Розшифрування -> Імпорт', () {
      const testPassword = 'SuperSecretPassword123!';

      // 1. Створюємо зашифрований рядок
      final encryptedString = BackupService.generateEncryptedPayload(
        testPassword,
        [dummyCategory],
        [dummyTransaction],
        [dummySubscription],
      );

      expect(encryptedString.contains(':'), true);
      expect(encryptedString.contains('Test Category'), false);

      // 2. Розшифровуємо
      final decryptedJson = BackupService.decryptPayload(
        testPassword,
        encryptedString,
      );

      expect(decryptedJson['version'], 1);

      final importedCategories = decryptedJson['categories'] as List;
      expect((importedCategories.first as Map)['name'], 'Test Category');

      final importedTransactions = decryptedJson['transactions'] as List;
      expect((importedTransactions.first as Map)['id'], 'tx_1');

      final importedSubscriptions = decryptedJson['subscriptions'] as List;
      expect((importedSubscriptions.first as Map)['periodicity'], 'monthly');
    });

    test('decryptPayload викидає помилку при неправильному паролі', () {
      const correctPassword = 'MyPassword';
      const wrongPassword = 'HackerPassword';

      final encryptedString = BackupService.generateEncryptedPayload(
        correctPassword,
        [],
        [],
        [],
      );

      expect(
        () => BackupService.decryptPayload(wrongPassword, encryptedString),
        throwsArgumentError,
      );
    });
  });
}
