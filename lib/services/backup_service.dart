import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';
import 'package:encrypt/encrypt.dart' as enc; // ДОДАНО: Пакет для шифрування
import 'package:crypto/crypto.dart';

import '../providers/category_provider.dart';
import '../providers/transaction_provider.dart';
import '../providers/subscription_provider.dart';
import '../services/storage_service.dart';
import '../models/category_model.dart';
import '../models/transaction_model.dart';
import '../models/subscription_model.dart';
import '../theme/app_colors_extension.dart';

class BackupService {
  // Фіксований вектор ініціалізації
  static final _iv = enc.IV.fromLength(16);

  // Динамічний генератор ключа з пароля користувача (SHA-256 робить рівно 32 байти)
  static enc.Key _generateKeyFromPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return enc.Key(Uint8List.fromList(digest.bytes));
  }

  static void _showCustomSnackBar(
    BuildContext context,
    String message,
    bool isSuccess,
  ) {
    if (!context.mounted) return;
    final colors = Theme.of(context).extension<AppColorsExtension>()!;
    final accentColor = isSuccess ? colors.income : colors.expense;

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: colors.cardBg,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(bottom: 30, left: 20, right: 20),
        elevation: 10,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: accentColor.withValues(alpha: 0.3), width: 1),
        ),
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isSuccess ? Icons.check_circle_outline : Icons.error_outline,
                color: accentColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: colors.textMain,
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

  // ДОДАНО ПАРАМЕТР password
  static Future<void> exportData(BuildContext context, String password) async {
    try {
      final catProv = context.read<CategoryProvider>();
      final txProv = context.read<TransactionProvider>();
      final subProv = context.read<SubscriptionProvider>();

      final data = {
        'categories': catProv.allCategoriesList.map((c) => c.toJson()).toList(),
        'transactions': txProv.history.map((t) => t.toJson()).toList(),
        'subscriptions': subProv.subscriptions.map((s) => s.toJson()).toList(),
      };

      // 1. Створюємо звичайний JSON
      final String plainJsonString = jsonEncode(data);

      // 2. Створюємо шифратор на основі пароля і шифруємо
      final key = _generateKeyFromPassword(password);
      final encrypter = enc.Encrypter(enc.AES(key));

      final encrypted = encrypter.encrypt(plainJsonString, iv: _iv);
      final encryptedBase64 = encrypted.base64;

      final directory = await getTemporaryDirectory();
      final dateStr =
          "${DateTime.now().day}_${DateTime.now().month}_${DateTime.now().year}";

      // ЗМІНЕНО: Розширення .cfbak замість .json
      final file = File('${directory.path}/coinflow_backup_$dateStr.cfbak');

      // 3. Записуємо зашифрований рядок у файл
      await file.writeAsString(encryptedBase64);

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

  // ДОДАНО ПАРАМЕТР password
  static Future<void> importData(BuildContext context, String password) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.any,
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);

        if (!file.path.endsWith('.cfbak') && !file.path.endsWith('.json')) {
          throw Exception('invalid_backup_format'.tr());
        }

        // 1. Читаємо файл
        final String fileContent = await file.readAsString();
        String jsonString;

        try {
          // 2. Створюємо дешифратор на основі введеного пароля
          final key = _generateKeyFromPassword(password);
          final encrypter = enc.Encrypter(enc.AES(key));

          jsonString = encrypter.decrypt64(fileContent, iv: _iv);
        } catch (e) {
          // Фоллбек: якщо старий бекап без пароля або введено неправильний пароль
          // (У майбутньому тут можна додати викидання помилки "Невірний пароль")
          jsonString = fileContent;
        }

        final Map<String, dynamic> data = jsonDecode(jsonString);

        if (!data.containsKey('categories') ||
            !data.containsKey('transactions')) {
          throw Exception('corrupted_backup'.tr());
        }

        List<Category> importedCategories = (data['categories'] as List)
            .map((e) => Category.fromJson(e))
            .toList();
        List<Transaction> importedTransactions = (data['transactions'] as List)
            .map((e) => Transaction.fromJson(e))
            .toList();

        List<Subscription> importedSubscriptions = [];
        if (data.containsKey('subscriptions')) {
          importedSubscriptions = (data['subscriptions'] as List)
              .map((e) => Subscription.fromJson(e))
              .toList();
        }

        await StorageService.clearAll();

        await StorageService.saveCategories(importedCategories);
        await StorageService.saveHistory(importedTransactions);
        for (var sub in importedSubscriptions) {
          await StorageService.saveSubscription(sub);
        }

        if (!context.mounted) return;
        final catProv = context.read<CategoryProvider>();
        final txProv = context.read<TransactionProvider>();
        final subProv = context.read<SubscriptionProvider>();

        await catProv.loadCategories();
        await txProv.loadHistory();
        await subProv.loadSubscriptions();

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
