import 'dart:io';
import 'package:flutter/foundation.dart' hide Category;
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:easy_localization/easy_localization.dart';

import '../database/app_database.dart';

class ExportImportService {
  // ==========================================
  // ЧИТАННЯ CSV (Для імпорту)
  // ==========================================
  static Future<List<List<dynamic>>?> readCsvRaw(File file) async {
    try {
      String input = await file.readAsString();

      // 👇 ВАЖЛИВО: Видаляємо невидимий символ UTF-8 BOM, який ми додали для Excel!
      // Інакше він зламає назву першої колонки при імпорті.
      if (input.startsWith('\uFEFF')) {
        input = input.substring(1);
      }

      // 👇 Нормалізуємо переноси рядків (Windows/Mac/Linux)
      input = input.replaceAll('\r\n', '\n').replaceAll('\r', '\n');

      // Спробуємо стандартний розпилювач (кома)
      List<List<dynamic>> rows = const CsvToListConverter(
        fieldDelimiter: ',',
        eol: '\n',
        // 👇 Забороняємо автоматично парсити числа, щоб не губилися нулі після коми
        shouldParseNumbers: false,
      ).convert(input);

      // Якщо колонок замало, пробуємо крапку з комою (Excel формат)
      if (rows.isNotEmpty && rows.first.length <= 1) {
        rows = const CsvToListConverter(
          fieldDelimiter: ';',
          eol: '\n',
          shouldParseNumbers: false,
        ).convert(input);
      }

      return rows;
    } catch (e) {
      debugPrint("Read CSV raw error: $e");
      return null;
    }
  }

  // ==========================================
  // ДОПОМІЖНІ МЕТОДИ ДЛЯ ЕКСПОРТУ
  // ==========================================

  // Екранування тексту (захищає таблицю від ламання, якщо в коментарі є коми)
  static String _escapeCsv(String input) {
    if (input.contains(',') || input.contains('"') || input.contains('\n')) {
      return '"${input.replaceAll('"', '""')}"';
    }
    return input;
  }

  // Визначення логічного типу транзакції з використанням локалізації
  static String _getTxType(Category? from, Category? to) {
    if (from == null || to == null) {
      return 'csv_type_other'.tr();
    }
    if (from.type == CategoryType.income && to.type == CategoryType.account) {
      return 'csv_type_income'.tr();
    }
    if (from.type == CategoryType.account && to.type == CategoryType.expense) {
      return 'csv_type_expense'.tr();
    }
    if (from.type == CategoryType.account && to.type == CategoryType.account) {
      return 'csv_type_transfer'.tr();
    }
    return 'csv_type_other'.tr();
  }

  // Конвертація копійок у нормальну суму (наприклад, 15000 -> 150.00)
  static String _formatAmount(int amount) {
    return (amount / 100).toStringAsFixed(2);
  }

  // ==========================================
  // ПРОФЕСІЙНИЙ ЕКСПОРТ У CSV
  // ==========================================
  static Future<String> exportToCsv({
    required List<Transaction> transactions,
    required List<Category> allCategories,
  }) async {
    try {
      if (transactions.isEmpty) {
        return 'error';
      }

      // Словник для швидкого пошуку категорій за їх ID
      final catMap = {for (var c in allCategories) c.id: c};

      final buffer = StringBuffer();

      // Додаємо UTF-8 BOM, щоб Excel автоматично і правильно читав кирилицю/умлаути
      buffer.write('\uFEFF');

      // Записуємо локалізовані заголовки колонок
      buffer.writeln('csv_export_headers'.tr());

      for (var tx in transactions) {
        final fromCat = catMap[tx.fromId];
        final toCat = catMap[tx.toId];

        final dateStr = DateFormat('dd.MM.yyyy HH:mm').format(tx.date);
        final txType = _getTxType(fromCat, toCat);

        // Використовуємо локалізоване слово "Видалено", якщо категорія не знайдена
        final fromName = _escapeCsv(
          fromCat?.name ?? 'csv_deleted_category'.tr(),
        );
        final toName = _escapeCsv(toCat?.name ?? 'csv_deleted_category'.tr());

        final amountFrom = _formatAmount(tx.amount);
        final currencyFrom = tx.currency;

        final amountTo = _formatAmount(tx.targetAmount ?? tx.amount);
        final currencyTo = tx.targetCurrency ?? tx.currency;

        final comment = _escapeCsv(tx.title);

        // Записуємо рядок у файл
        buffer.writeln(
          '$dateStr,$txType,$fromName,$amountFrom,$currencyFrom,$toName,$amountTo,$currencyTo,$comment',
        );
      }

      // Збереження у тимчасову директорію
      final directory = await getTemporaryDirectory();
      final dateStr = DateFormat('dd_MM_yyyy_HHmm').format(DateTime.now());
      final path = '${directory.path}/CoinFlow_Export_$dateStr.csv';

      final file = File(path);
      await file.writeAsString(buffer.toString());

      // Ділимося згенерованим файлом і чекаємо на результат
      final result = await SharePlus.instance.share(
        ShareParams(files: [XFile(path)], text: 'my_coinflow_backup'.tr()),
      );

      // 👇 БЕЗПЕЧНЕ ОЧИЩЕННЯ КЕШУ з логуванням: Видаляємо файл після того, як поділилися.
      try {
        if (await file.exists()) {
          await file.delete();
          debugPrint(
            "✅ Тимчасовий CSV-файл успішно видалено з кешу",
          ); // Лог успіху
        }
      } catch (e) {
        debugPrint(
          "❌ Не вдалося видалити тимчасовий файл експорту: $e",
        ); // Лог помилки
      }

      // Перевіряємо статус (якщо користувач скасував - буде dismissed)
      if (result.status == ShareResultStatus.success) {
        return 'success';
      } else if (result.status == ShareResultStatus.dismissed) {
        return 'dismissed';
      }
      return 'success'; // Fallback для старих платформ
    } catch (e) {
      debugPrint("Export error: $e");
      return 'error';
    }
  }
}
