import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';
import '../providers/category_provider.dart';
import '../providers/transaction_provider.dart';
import '../providers/subscription_provider.dart';
import '../services/storage_service.dart';
import '../models/category_model.dart';
import '../models/transaction_model.dart';
import '../models/subscription_model.dart';
import '../theme/app_colors_extension.dart';

class BackupService {
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

  static Future<void> exportData(BuildContext context) async {
    try {
      final catProv = context.read<CategoryProvider>();
      final txProv = context.read<TransactionProvider>();
      final subProv = context.read<SubscriptionProvider>();

      final data = {
        'categories': catProv.allCategoriesList.map((c) => c.toJson()).toList(),
        'transactions': txProv.history.map((t) => t.toJson()).toList(),
        'subscriptions': subProv.subscriptions.map((s) => s.toJson()).toList(),
      };

      final String jsonString = jsonEncode(data);
      final directory = await getTemporaryDirectory();
      final dateStr =
          "${DateTime.now().day}_${DateTime.now().month}_${DateTime.now().year}";
      final file = File('${directory.path}/coinflow_backup_$dateStr.json');

      await file.writeAsString(jsonString);

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

  static Future<void> importData(BuildContext context) async {
    try {
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

        if (!data.containsKey('categories') ||
            !data.containsKey('transactions')) {
          throw Exception("Файл пошкоджено або це не бекап CoinFlow");
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

        // Перша перевірка: перед тим як читати провайдери
        if (!context.mounted) return;
        final catProv = context.read<CategoryProvider>();
        final txProv = context.read<TransactionProvider>();
        final subProv = context.read<SubscriptionProvider>();

        await catProv.loadCategories();
        await txProv.loadHistory();
        subProv.updateDependencies(catProv, txProv);

        // ДРУГА ПЕРЕВІРКА: перед тим як показувати SnackBar (бо вище були await)
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
