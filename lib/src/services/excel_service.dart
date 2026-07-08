// lib/src/utils/excel_service.dart
import 'dart:io';
import 'package:excel/excel.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/category.dart';
import '../models/transaction_model.dart';
import 'package:path/path.dart' as p;

class ExcelService {
  static Future<File?> exportTransactions() async {
    final excel = Excel.createExcel();
    final Sheet sheet = excel['Transactions'];

    sheet.appendRow([
      'Date',
      'Description',
      'Type',
      'Category',
      'Amount',
    ]);

    final txBox = Hive.box<TransactionModel>('transactions');
    final catBox = Hive.box<Category>('categories');

    for (final tx in txBox.values) {
      final category = catBox.get(tx.categoryId)?.name ?? 'Unknown';
      sheet.appendRow([
        tx.createdAt.toIso8601String(),
        tx.description,
        tx.isNewIncome ? 'Income' : 'Expense',
        category,
        tx.amount,
      ]);
    }

    final directory = await getExternalStorageDirectory();
    if (directory == null) return null;

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final fileName = 'transactions_$timestamp.xlsx';
    final filePath = p.join(directory.path, fileName);
    final file = File(filePath);
    await file.writeAsBytes(excel.encode()!);

    try {
      final status = await Permission.storage.request();
      if (status.isGranted) {
        final outputDir = await FilePicker.platform.getDirectoryPath();
        if (outputDir != null) {
          final finalPath = p.join(outputDir, fileName);
          final finalFile = File(finalPath);
          await finalFile.writeAsBytes(await file.readAsBytes());
          await file.delete();
          return finalFile;
        }
      }
    } catch (e) {
      print('Directory picker failed: $e');
    }

    return file;
  }

  static Future<void> importTransactions() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx'],
    );

    if (result == null) return;

    final file = File(result.files.single.path!);
    final bytes = file.readAsBytesSync();
    final excel = Excel.decodeBytes(bytes);

    final sheet = excel['Transactions'];
    final txBox = Hive.box<TransactionModel>('transactions');
    final catBox = Hive.box<Category>('categories');

    for (var row in sheet.rows.skip(1)) {
      final date = DateTime.parse(row[0]!.value.toString());
      final description = row[1]!.value.toString();
      final isIncome = row[2]!.value.toString().toLowerCase() == 'income';
      final categoryName = row[3]!.value.toString();
      final amount = double.parse(row[4]!.value.toString());

      Category? category;
      try {
        category = catBox.values.firstWhere(
          (c) => c.name.toLowerCase() == categoryName.toLowerCase(),
        );
      } catch (e) {
        category = null;
      }

      if (category == null) continue;

      final tx = TransactionModel(
        categoryId: category.key as int,
        amount: amount,
        description: description,
        isNewIncome: isIncome,
        createdAt: date,
      );

      await txBox.add(tx);
    }

    print('✅ Import complete!');
  }
}
