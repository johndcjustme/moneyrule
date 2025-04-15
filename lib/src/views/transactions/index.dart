import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:moneyrule/src/components/transaction_item.dart';
import 'package:moneyrule/src/utils/excel_service.dart';
import '../../helpers/helper.dart';
import '../../models/category.dart';
import '../../models/transaction_model.dart';

class AllTransactionsPage extends StatefulWidget {
  const AllTransactionsPage({super.key});

  @override
  State<AllTransactionsPage> createState() => _AllTransactionsPageState();
}

class _AllTransactionsPageState extends State<AllTransactionsPage> {
  DateTimeRange? _selectedRange;

  @override
  Widget build(BuildContext context) {
    final txBox = Hive.box<TransactionModel>('transactions');
    final catBox = Hive.box<Category>('categories');

    return Scaffold(
      appBar: AppBar(
        title: const Text('All Transactions'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'export') {
                final file = await ExcelService.exportTransactions();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Exported to: ${file.path}'),
                    duration: const Duration(seconds: 5),
                  ),
                );
              } else if (value == 'import') {
                await ExcelService.importTransactions();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Transactions imported successfully')),
                );
              } else if (value == 'filter') {
                final picked = await showDateRangePicker(
                  context: context,
                  firstDate: DateTime(2022),
                  lastDate: DateTime.now(),
                  initialDateRange: _selectedRange,
                );
                if (picked != null) {
                  setState(() {
                    _selectedRange = picked;
                  });
                }
              } else if (value == 'clear') {
                setState(() {
                  _selectedRange = null;
                });
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem<String>(
                value: 'export',
                child: ListTile(
                  leading: Icon(Icons.download),
                  title: Text('Export to Excel'),
                ),
              ),
              const PopupMenuItem<String>(
                value: 'import',
                child: ListTile(
                  leading: Icon(Icons.upload),
                  title: Text('Import from Excel'),
                ),
              ),
              const PopupMenuItem<String>(
                value: 'filter',
                child: ListTile(
                  leading: Icon(Icons.filter_alt),
                  title: Text('Filter by Date'),
                ),
              ),
              const PopupMenuItem<String>(
                value: 'clear',
                child: ListTile(
                  leading: Icon(Icons.clear),
                  title: Text('Clear Filter'),
                ),
              ),
            ],
          ),
        ],
      ),
      body: ValueListenableBuilder(
        valueListenable: txBox.listenable(),
        builder: (context, Box<TransactionModel> box, _) {
          final allTx = box.values.toList()
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

          final filteredTx = _selectedRange == null
              ? allTx
              : allTx
                  .where((tx) =>
                      tx.createdAt.isAfter(_selectedRange!.start
                          .subtract(const Duration(days: 1))) &&
                      tx.createdAt.isBefore(
                          _selectedRange!.end.add(const Duration(days: 1))))
                  .toList();

          final incomeTotal = filteredTx
              .where((tx) => tx.isNewIncome)
              .fold<double>(0, (sum, tx) => sum + tx.amount);

          final expenseTotal = filteredTx
              .where((tx) => !tx.isNewIncome)
              .fold<double>(0, (sum, tx) => sum + tx.amount);

          if (filteredTx.isEmpty) {
            return const Center(child: Text('No transactions recorded.'));
          }

          return ListView(
            children: [
              if (_selectedRange != null)
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Showing: ${_selectedRange!.start.toLocal().toString().split(' ')[0]} → ${_selectedRange!.end.toLocal().toString().split(' ')[0]}',
                        style:
                            const TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                      const SizedBox(height: 8),
                      Text(
                          '💰 Total Income: ₱${incomeTotal.toStringAsFixed(2)}'),
                      Text(
                          '💸 Total Deductions: ₱${expenseTotal.toStringAsFixed(2)}'),
                    ],
                  ),
                ),
              ...filteredTx.map((tx) {
                final category = catBox.get(tx.categoryId);
                return TransactionItem(
                  title: tx.description,
                  subtitle: category?.name,
                  amount: tx.amount,
                  isNewIncome: tx.isNewIncome,
                  onLongPress: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Delete Transaction'),
                        content: const Text(
                            'Are you sure you want to delete this transaction?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () {
                              tx.delete();
                              Navigator.pop(context);
                            },
                            child: const Text('Delete',
                                style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      ),
                    );
                  },
                );
              }),
            ],
          );
        },
      ),
    );
  }
}
