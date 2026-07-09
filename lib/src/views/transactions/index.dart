import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:moneyrule/src/components/edit_transaction_sheet.dart';
import 'package:moneyrule/src/components/transaction_item.dart';
import 'package:moneyrule/src/services/excel_service.dart';
import 'package:moneyrule/src/utils/theme_color.dart';
import 'package:moneyrule/src/utils/theme_front.dart';
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

  DateTimeRange _todayRange() {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = DateTime(now.year, now.month, now.day, 23, 59, 59);
    return DateTimeRange(start: start, end: end);
  }

  DateTimeRange _yesterdayRange() {
    final now = DateTime.now();
    final yesterday = now.subtract(const Duration(days: 1));
    final start = DateTime(yesterday.year, yesterday.month, yesterday.day);
    final end = DateTime(
        yesterday.year, yesterday.month, yesterday.day, 23, 59, 59);
    return DateTimeRange(start: start, end: end);
  }

  DateTimeRange _thisWeekRange() {
    final now = DateTime.now();
    final start = now.subtract(Duration(days: now.weekday - 1));
    final weekStart =
        DateTime(start.year, start.month, start.day);
    final end = DateTime(now.year, now.month, now.day, 23, 59, 59);
    return DateTimeRange(start: weekStart, end: end);
  }

  DateTimeRange _thisMonthRange() {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, 1);
    final end = DateTime(now.year, now.month, now.day, 23, 59, 59);
    return DateTimeRange(start: start, end: end);
  }

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
                
                if (file?.path == null) return;

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Exported to: ${file?.path}'),
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
              } else if (value == 'today') {
                setState(() {
                  _selectedRange = _todayRange();
                });
              } else if (value == 'yesterday') {
                setState(() {
                  _selectedRange = _yesterdayRange();
                });
              } else if (value == 'week') {
                setState(() {
                  _selectedRange = _thisWeekRange();
                });
              } else if (value == 'month') {
                setState(() {
                  _selectedRange = _thisMonthRange();
                });
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
                value: 'today',
                child: ListTile(
                  leading: Icon(Icons.today),
                  title: Text('Today'),
                ),
              ),
              const PopupMenuItem<String>(
                value: 'yesterday',
                child: ListTile(
                  leading: Icon(Icons.history),
                  title: Text('Yesterday'),
                ),
              ),
              const PopupMenuItem<String>(
                value: 'week',
                child: ListTile(
                  leading: Icon(Icons.view_week),
                  title: Text('This Week'),
                ),
              ),
              const PopupMenuItem<String>(
                value: 'month',
                child: ListTile(
                  leading: Icon(Icons.calendar_month),
                  title: Text('This Month'),
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
                      !tx.createdAt.isBefore(_selectedRange!.start) &&
                      !tx.createdAt.isAfter(_selectedRange!.end))
                  .toList();

          final incomeTotal = filteredTx
              .where((tx) => tx.isNewIncome)
              .fold<double>(0, (sum, tx) => sum + tx.amount);

          final expenseTotal = filteredTx
              .where((tx) => !tx.isNewIncome)
              .fold<double>(0, (sum, tx) => sum + tx.amount);

          double totalForCategory(String name) {
            return filteredTx
                .where((tx) {
                  final cat = catBox.get(tx.categoryId);
                  return !tx.isNewIncome &&
                      cat != null &&
                      cat.name.toLowerCase() == name.toLowerCase();
                })
                .fold<double>(0, (sum, tx) => sum + tx.amount);
          }

          final needTotal = totalForCategory('Needs');
          final wantsTotal = totalForCategory('Wants');
          final savingsTotal = totalForCategory('Save');

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
                        'Showing: ${DateFormat('MMM d, y').format(_selectedRange!.start)} → ${DateFormat('MMM d, y').format(_selectedRange!.end)}',
                        style:
                            const TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 16),
                      Text('Transactions: ${filteredTx.length}', style: TextStyle(color: ThemeColor.textSecondary)),
                      const SizedBox(height: 16),
                       Row(children: [
                        const Text('Income: '),
                        Text(Helper.currencyFormatter(incomeTotal, '+'), style: const TextStyle(color: ThemeColor.income, fontWeight: FontWeight.bold)),
                      ],),
                        Row(children: [
                          const Text('Deductions: '),
                          Text(Helper.currencyFormatter(expenseTotal, '-'), style: const TextStyle(color: ThemeColor.textSecondary, fontWeight: FontWeight.bold)),
                        ],),

                        Padding(padding: const EdgeInsets.only(left: 16), child: Column(children: [
                        Row(children: [
                          const Text('Needs: ', style: TextStyle(color: ThemeColor.textSecondary)),
                          Text(Helper.currencyFormatter(needTotal, '-'), style: const TextStyle(color: ThemeColor.textSecondary, fontWeight: FontWeight.bold)),
                        ],),
                        Row(children: [
                          const Text('Wants: ', style: TextStyle(color: ThemeColor.textSecondary)),
                          Text(Helper.currencyFormatter(wantsTotal, '-'), style: const TextStyle(color: ThemeColor.textSecondary, fontWeight: FontWeight.bold)),
                        ],),
                        Row(children: [
                          const Text('Savings: ', style: TextStyle(color: ThemeColor.textSecondary)),
                          Text(Helper.currencyFormatter(savingsTotal, '-'), style: const TextStyle(color: ThemeColor.textSecondary, fontWeight: FontWeight.bold)),
                        ],)])),
                      const SizedBox(height: 16),
             
                       
                      const Divider(),
                      const SizedBox(height: 16),
                      const Text('TRANSACTIONS', style: TextStyle(fontSize: ThemeFont.bodyLarge, fontWeight: FontWeight.bold)),
                      // Text(
                      //     '🧮 Overall Total: ${Helper.currencyFormatter(incomeTotal - expenseTotal, (incomeTotal - expenseTotal) >= 0 ? '+' : '')}'),
                    ],
                  ),
                ),
              ...filteredTx.map((tx) {
                final category = catBox.get(tx.categoryId);
                return TransactionItem(
                  title: tx.description,
                  subtitle:
                      '${category?.name ?? 'Unknown'} • ${tx.createdAt.toLocal().toString().split('.')[0]}',
                  amount: tx.amount,
                  isNewIncome: tx.isNewIncome,
                  onDelete: () {
                    tx.delete();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Transaction deleted successfully')),
                    );
                  },
                  onTap: () => showEditTransactionSheet(context, tx),
                );
              }),
            ],
          );
        },
      ),
    );
  }
}
