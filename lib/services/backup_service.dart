import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';

// 👇 1. Додали Riverpod
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:encrypt/encrypt.dart' as enc;
import 'package:crypto/crypto.dart';

// 👇 2. Імпортуємо наш єдиний хаб провайдерів
import '../providers/all_providers.dart';

import '../services/storage_service.dart';
import '../database/app_database.dart';
import '../theme/app_colors_extension.dart';

class BackupService {
  static final _iv = enc.IV.fromLength(16);

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

  static Future<void> exportData(
    BuildContext context,
    WidgetRef ref,
    String password,
  ) async {
    try {
      final catState = ref.read(categoryProvider);
      final txState = ref.read(transactionProvider);
      final subState = ref.read(subscriptionProvider);

      final data = {
        'version': 1,
        'categories': catState.allCategoriesList
            .map((c) => c.toJson())
            .toList(),
        'transactions': txState.history.map((t) => t.toJson()).toList(),
        'subscriptions': subState.subscriptions.map((s) => s.toJson()).toList(),
      };

      final String jsonString = jsonEncode(data);
      final key = _generateKeyFromPassword(password);
      final encrypter = enc.Encrypter(enc.AES(key));

      final encrypted = encrypter.encrypt(jsonString, iv: _iv);
      final encryptedBase64 = encrypted.base64;

      final directory = await getTemporaryDirectory();
      final dateStr = DateFormat('dd_MM_yyyy_HHmm').format(DateTime.now());
      final file = File('${directory.path}/coinflow_backup_$dateStr.cfbak');

      await file.writeAsString(encryptedBase64);

      await SharePlus.instance.share(
        ShareParams(text: 'backup_share_text'.tr(), files: [XFile(file.path)]),
      );
    } catch (e) {
      debugPrint("Помилка експорту: $e");
      if (context.mounted) {
        _showCustomSnackBar(context, 'backup_error'.tr(), false);
      }
    }
  }

  static Future<void> importData(
    BuildContext context,
    WidgetRef ref,
    String password,
  ) async {
    try {
      // 👇 Отримуємо базу даних з Riverpod
      final db = ref.read(databaseProvider);

      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.any,
      );

      if (result == null || result.files.single.path == null) return;

      final file = File(result.files.single.path!);
      final String fileContent = await file.readAsString();
      String jsonString;

      if (file.path.endsWith('.cfbak')) {
        try {
          final key = _generateKeyFromPassword(password);
          final encrypter = enc.Encrypter(enc.AES(key));
          jsonString = encrypter.decrypt64(fileContent, iv: _iv);
        } catch (e) {
          if (context.mounted) {
            _showCustomSnackBar(
              context,
              'wrong_password_or_corrupted'.tr(),
              false,
            );
          }
          return;
        }
      } else if (file.path.endsWith('.json')) {
        jsonString = fileContent;
      } else {
        throw Exception('invalid_backup_format'.tr());
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

      // 👇 ВИПРАВЛЕНО: Передаємо [db] у методи сервісу
      await StorageService.clearAll(db);
      await StorageService.saveCategories(db, importedCategories);
      await StorageService.saveHistory(db, importedTransactions);
      for (var sub in importedSubscriptions) {
        await StorageService.saveSubscription(db, sub);
      }

      if (!context.mounted) return;

      // Оновлюємо дані в провайдерах
      await ref.read(categoryProvider.notifier).loadCategories();
      await ref.read(transactionProvider.notifier).loadHistory();
      await ref.read(subscriptionProvider.notifier).loadSubscriptions();

      if (context.mounted) {
        _showCustomSnackBar(context, 'backup_success'.tr(), true);
      }
    } catch (e) {
      debugPrint("Помилка імпорту: $e");
      if (context.mounted) {
        _showCustomSnackBar(context, 'import_error'.tr(), false);
      }
    }
  }
}
