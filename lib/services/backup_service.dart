import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:easy_localization/easy_localization.dart';
import '../providers/finance_provider.dart';
import '../services/storage_service.dart';
import '../models/category_model.dart';
import '../models/transaction_model.dart';
import '../models/subscription_model.dart';
import '../theme/app_colors_extension.dart'; // ДОДАНО: Імпорт теми

class BackupService {
  // --- ДОПОМІЖНИЙ МЕТОД ДЛЯ КРАСИВИХ СПОВІЩЕНЬ ---
  static void _showCustomSnackBar(
    BuildContext context,
    String message,
    bool isSuccess,
  ) {
    if (!context.mounted) return;

    // ДОДАНО: Отримуємо кольори теми
    final colors = Theme.of(context).extension<AppColorsExtension>()!;
    final accentColor = isSuccess ? colors.income : colors.expense;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: colors.cardBg, // ЗМІНЕНО: Фон SnackBar адаптивний
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(bottom: 30, left: 20, right: 20),
        elevation: 10,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: accentColor.withValues(alpha: 0.3), // ЗМІНЕНО
            width: 1,
          ),
        ),
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.1), // ЗМІНЕНО
                shape: BoxShape.circle,
              ),
              child: Icon(
                isSuccess ? Icons.check_circle_outline : Icons.error_outline,
                color: accentColor, // ЗМІНЕНО
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: colors.textMain, // ЗМІНЕНО: Текст адаптивний
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- ЕКСПОРТ ДАНИХ (Створення файлу) ---
  static Future<void> exportData(
    FinanceProvider provider,
    BuildContext context,
  ) async {
    try {
      // 1. Збираємо всі дані (включаючи підписки та архіви!)
      final data = {
        'categories': provider.allCategoriesList
            .map((c) => c.toJson())
            .toList(),
        'transactions': provider.history.map((t) => t.toJson()).toList(),
        'subscriptions': provider.subscriptions
            .map((s) => s.toJson())
            .toList(), // ФІКС: Зберігаємо підписки
      };

      // 2. Перетворюємо дані у текстовий формат JSON
      final String jsonString = jsonEncode(data);

      // 3. Отримуємо тимчасову папку для генерації файлу
      final directory = await getTemporaryDirectory();
      final dateStr =
          "${DateTime.now().day}_${DateTime.now().month}_${DateTime.now().year}";
      final file = File('${directory.path}/coinflow_backup_$dateStr.json');

      // 4. Записуємо текст у файл
      await file.writeAsString(jsonString);

      // 5. Викликаємо системне вікно "Поділитися"
      final xFile = XFile(file.path);
      await SharePlus.instance.share(
        ShareParams(text: 'backup_share_text'.tr(), files: [xFile]),
      );
    } catch (e) {
      debugPrint("Помилка експорту: $e");
      if (!context.mounted) return;
      _showCustomSnackBar(context, 'backup_error'.tr(), false);
    }
  }

  // --- ІМПОРТ ДАНИХ (Відновлення з файлу) ---
  static Future<void> importData(
    FinanceProvider provider,
    BuildContext context,
  ) async {
    try {
      // 1. Відкриваємо провідник файлів (користувач обирає файл)
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.any,
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);

        if (!file.path.endsWith('.json')) {
          throw Exception("Невірний формат файлу. Очікується .json");
        }

        final String jsonString = await file.readAsString();
        final Map<String, dynamic> data = jsonDecode(jsonString);

        // БЕЗПЕКА: Жорстка перевірка структури файлу ДО видалення бази
        if (!data.containsKey('categories') ||
            !data.containsKey('transactions')) {
          throw Exception("Файл пошкоджено або це не бекап CoinFlow");
        }

        // 2. Парсимо дані в оперативну пам'ять
        List<Category> importedCategories = (data['categories'] as List)
            .map((e) => Category.fromJson(e))
            .toList();
        List<Transaction> importedTransactions = (data['transactions'] as List)
            .map((e) => Transaction.fromJson(e))
            .toList();

        // Зворотна сумісність: якщо файл старий і підписок там немає, просто робимо пустий список
        List<Subscription> importedSubscriptions = [];
        if (data.containsKey('subscriptions')) {
          importedSubscriptions = (data['subscriptions'] as List)
              .map((e) => Subscription.fromJson(e))
              .toList();
        }

        // 3. ТІЛЬКИ ТЕПЕР, коли ми впевнені, що дані зчитані успішно, очищаємо стару базу
        await StorageService.clearAll();

        // 4. Зберігаємо нові дані
        await StorageService.saveCategories(importedCategories);
        await StorageService.saveHistory(importedTransactions);
        for (var sub in importedSubscriptions) {
          await StorageService.saveSubscription(
            sub,
          ); // Зберігаємо підписки по одній
        }

        // 5. Оновлюємо стан додатку
        await provider.loadData();
        if (!context.mounted) return;
        _showCustomSnackBar(context, 'backup_success'.tr(), true);
      }
    } catch (e) {
      debugPrint("Помилка імпорту: $e");
      if (!context.mounted) return;
      _showCustomSnackBar(context, 'import_error'.tr(), false);
    }
  }
}
