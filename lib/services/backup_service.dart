import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import '../providers/finance_provider.dart';
import '../services/storage_service.dart';
import '../models/category_model.dart';
import '../models/transaction_model.dart';

class BackupService {
  // --- ДОПОМІЖНИЙ МЕТОД ДЛЯ КРАСИВИХ СПОВІЩЕНЬ ---
  static void _showCustomSnackBar(
    BuildContext context,
    String message,
    bool isSuccess,
  ) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.white,
        behavior: SnackBarBehavior
            .floating, // Робить віконце плаваючим, а не прилиплим до дна
        margin: const EdgeInsets.only(bottom: 30, left: 20, right: 20),
        elevation: 10,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: isSuccess
                ? Colors.green.withAlpha(80)
                : Colors.red.withAlpha(80),
            width: 1,
          ),
        ),
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSuccess
                    ? Colors.green.withAlpha(30)
                    : Colors.red.withAlpha(30),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isSuccess ? Icons.check_circle_outline : Icons.error_outline,
                color: isSuccess ? Colors.green : Colors.red,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.black87,
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
      // 1. Збираємо всі категорії та транзакції в єдиний Map
      final data = {
        'categories': [
          ...provider.incomes,
          ...provider.accounts,
          ...provider.expenses,
        ].map((c) => c.toJson()).toList(),
        'transactions': provider.history.map((t) => t.toJson()).toList(),
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
        ShareParams(text: 'Моя резервна копія CoinFlow', files: [xFile]),
      );

      // Ми не показуємо SnackBar при успішному експорті, бо система і так відкриє своє вікно Share
    } catch (e) {
      debugPrint("Помилка експорту: $e");
      if (!context.mounted) return;
      _showCustomSnackBar(
        context,
        "Помилка при створенні резервної копії 😔",
        false,
      );
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

        // Захист від того, що користувач обрав випадковий файл (наприклад, фото)
        if (!file.path.endsWith('.json')) {
          throw Exception("Невірний формат файлу. Очікується .json");
        }

        final String jsonString = await file.readAsString();
        final Map<String, dynamic> data = jsonDecode(jsonString);

        // 2. Парсимо дані назад у наші об'єкти (моделі)
        List<Category> importedCategories = (data['categories'] as List)
            .map((e) => Category.fromJson(e))
            .toList();
        List<Transaction> importedTransactions = (data['transactions'] as List)
            .map((e) => Transaction.fromJson(e))
            .toList();

        // 3. Очищаємо стару базу і зберігаємо нові дані
        await StorageService.clearAll();
        await StorageService.saveCategories(importedCategories);
        await StorageService.saveHistory(importedTransactions);

        // 4. Оновлюємо стан додатку
        await provider.loadData();
        if (!context.mounted) return;
        _showCustomSnackBar(context, "Дані успішно відновлено! 🎉", true);
      }
    } catch (e) {
      debugPrint("Помилка імпорту: $e");
      if (!context.mounted) return;
      _showCustomSnackBar(
        context,
        "Помилка відновлення. Файл пошкоджено або невірного формату 😔",
        false,
      );
    }
  }
}
