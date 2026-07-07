import 'dart:math';

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:moneyrule/src/components/edit_transaction_sheet.dart';
import 'package:moneyrule/src/components/transaction_item.dart';
import 'package:moneyrule/src/services/auth.dart';
import 'package:moneyrule/src/utils/theme_color.dart';
import 'package:pie_chart/pie_chart.dart';
import '../../helpers/helper.dart';
import '../../models/category.dart';
import '../../models/transaction_model.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  bool _showIncome = false;
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;
  int _monthlyYear = DateTime.now().year;

  @override
  Widget build(BuildContext context) {
    final transactionBox = Hive.box<TransactionModel>('transactions');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Overview'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'account') {
                Navigator.pushNamed(context, '/account');
              } else if (value == 'logout') {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Logout'),
                    content: const Text('Are you sure you want to logout?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () async {
                          await Auth.logout(context);
                        },
                        child: const Text('Logout'),
                      ),
                    ],
                  ),
                );
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'account',
                child: ListTile(
                  leading: Icon(Icons.account_circle),
                  title: Text('Account Settings'),
                ),
              ),
              const PopupMenuItem(
                value: 'logout',
                child: ListTile(
                  leading: Icon(Icons.logout),
                  title: Text('Logout'),
                ),
              ),
            ],
          ),
        ],
      ),
      body: ValueListenableBuilder(
        valueListenable: transactionBox.listenable(),
        builder: (context, Box<TransactionModel> txBox, _) {
          final transactions = txBox.values.toList();

          final incomeTotal = transactions
              .where((tx) => tx.isNewIncome)
              .fold<double>(0, (sum, tx) => sum + tx.amount);

          final expenseTotal = transactions
              .where((tx) => !tx.isNewIncome)
              .fold<double>(0, (sum, tx) => sum + tx.amount);

          final balance = incomeTotal - expenseTotal;

          final categoryBox = Hive.box<Category>('categories');
          final categories = categoryBox.values.toList();

          final recentTransactions = transactions.toList()
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

          final latestSeven = recentTransactions.take(7).toList();

          final double total = incomeTotal + expenseTotal;
          final double incomeRatio = total == 0 ? 0.5 : balance / total;
          final double expenseRatio = total == 0 ? 0.5 : expenseTotal / total;

          return Column(
            children: [
              // 💰 Overall Summary Card
              Card(
                  margin: const EdgeInsets.all(0),
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(0)),
                  child: Column(
                    children: [
                       Row(
                          // color: Colors.red,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Container(
                                  color: Colors.black38,
                                  child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16, vertical: 20),
                                      child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                          const Row(children: [
                                            Text(
                                            'TOTAL INCOME',
                                            style: TextStyle(
                                                color: Colors.grey,
                                                fontSize: 12),
                                          )
                                          ]),
                                          // const SizedBox(
                                          //   width: 10,
                                          // ),
                                          Row(children: [
Text(
                                            _showIncome
                                                ? Helper.currencyFormatter(
                                                    incomeTotal)
                                                : '••••••',
                                            style: const TextStyle(
                                              fontSize: 24,
                                              // fontWeight: FontWeight.bold
                                            ),
                                          ),
                                          const SizedBox(
                                            width: 8,
                                          ),
                                          IconButton(
                                            icon: Icon(
                                              _showIncome
                                                  ? Icons.visibility_off
                                                  : Icons.visibility,
                                              color: Colors.grey,
                                              size: 18,
                                            ),
                                            padding: EdgeInsets.zero,
                                            constraints:
                                                const BoxConstraints(),
                                            onPressed: () {
                                              setState(() {
                                                _showIncome = !_showIncome;
                                              });
                                            },
                                          )
                                          ])
                                        ],
                                          ))),
                            )
                          ]),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 32),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // const Text(
                            //   'REMAINING BALANCE',
                            //   style:
                            //       TextStyle(color: Colors.grey, fontSize: 12),
                            // ),
                            // Text(Helper.currencyFormatter(balance),
                            //     style: TextStyle(
                            //         fontSize: 32,
                            //         color: balance < 0
                            //             ? Colors.red
                            //             : Colors.white)),
                            // const SizedBox(height: 14),
                            Row(
                              children: [
                                Expanded(
                                    child: Row(
                                  children: [
                                    Icon(
                                      Icons.arrow_downward_sharp,
                                      color: ThemeColor.income,
                                    ),
                                    const SizedBox(
                                      width: 10,
                                    ),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'BALANCE',
                                          style: TextStyle(
                                              fontSize: 10, color: Colors.grey),
                                        ),
                                        Text(
                                          Helper.currencyFormatter(balance),
                                          style: TextStyle(
                                              fontSize: 18,
                                              color: balance < 0
                                                  ? Colors.red
                                                  : Colors.white),
                                        ),
                                      ],
                                    )
                                  ],
                                )),
                                Expanded(
                                    child: Row(
                                  children: [
                                    Icon(
                                      Icons.arrow_upward_sharp,
                                      color: ThemeColor.expense,
                                    ),
                                    const SizedBox(
                                      width: 10,
                                    ),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'EXPENSES',
                                          style: TextStyle(
                                              fontSize: 10, color: Colors.grey),
                                        ),
                                        Text(
                                          Helper.currencyFormatter(
                                              expenseTotal),
                                          style: const TextStyle(fontSize: 18),
                                        ),
                                      ],
                                    )
                                  ],
                                )),
                              ],
                            )
                            // const Divider(height: 20),
                            // Text(
                            //   '🧮 Remaining Balance: ₱${balance.toStringAsFixed(2)}',
                            //   style: TextStyle(
                            //     color: balance >= 0 ? Colors.green : Colors.red,
                            //     fontWeight: FontWeight.bold,
                            //   ),
                            // ),
                          ],
                        ),
                      ),
                      SizedBox(
                        width: double.infinity,
                        height: 4,
                        child: Row(
                          children: [
                            Expanded(
                              flex: (incomeRatio * 1000).round(),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: ThemeColor.income,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: (expenseRatio * 1000).round(),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: ThemeColor.expense,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                     
                    ],
                  )),

              // 📊 Category Breakdown

              Expanded(
                child: ListView(
                  children: [
                    const SizedBox(
                      height: 38,
                    ),
                    ...categories.map((cat) {
                      final catId = cat.key as int;
                      final incomeForCat = transactions
                          .where(
                              (tx) => tx.isNewIncome && tx.categoryId == catId)
                          .fold<double>(0, (sum, tx) => sum + tx.amount);
                      final expenseForCat = transactions
                          .where(
                              (tx) => !tx.isNewIncome && tx.categoryId == catId)
                          .fold<double>(0, (sum, tx) => sum + tx.amount);
                      final balanceForCat = incomeForCat - expenseForCat;
                      final double totalIncome = balanceForCat + expenseForCat;

                      return ListTile(
                        // contentPadding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                        leading: const Icon(
                          Icons.star,
                          // color: Colors.grey, // Customize as needed
                          size: 20,
                        ),

                        trailing: SizedBox(
                          width: 170, // ⬅️ Increased width for better layout
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      Helper.currencyFormatter(expenseForCat),
                                      style: TextStyle(
                                        color: ThemeColor.expense,
                                        fontSize: 14,
                                        height: 1.2,
                                      ),
                                    ),
                                    Text(
                                      Helper.currencyFormatter(balanceForCat),
                                      style: TextStyle(
                                        color: balanceForCat >= 0
                                            ? ThemeColor.income
                                            : Colors.red,
                                        fontSize: 14,
                                        height: 1.2,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(
                                  width:
                                      8), // ⬅️ spacing between text and chart
                              PieChart(
                                dataMap: {
                                  "Remaining":
                                      balanceForCat < 0 ? 0 : balanceForCat,
                                  "Expenses": expenseForCat,
                                },
                                colorList: [
                                  ThemeColor.income,
                                  ThemeColor.expense
                                ],
                                chartType: ChartType.ring,
                                chartRadius: 30,
                                ringStrokeWidth: 4,
                                legendOptions:
                                    const LegendOptions(showLegends: false),
                                chartValuesOptions: const ChartValuesOptions(
                                    showChartValues: false),
                              ),
                            ],
                          ),
                        ),
                        title: Text(cat.name),
                        subtitle: Text(
                            'All: ${Helper.currencyFormatter(totalIncome)}',
                            style: const TextStyle(
                                color: Colors.grey, fontSize: 12)),
                        // subtitle: Column(
                        //   crossAxisAlignment: CrossAxisAlignment.start,
                        //   // mainAxisSize: MainAxisSize.min,
                        //   children: <Widget>[
                        //     // Text(
                        //     //   'Income: ₱${incomeForCat.toStringAsFixed(2)}\n',
                        //     //   style: const TextStyle(
                        //     //     color: Colors.blue,
                        //     //     height:
                        //     //         0.7, // 👈 controls line spacing (default is ~1.5)
                        //     //   ),
                        //     // ),
                        //     const SizedBox(height: 4),
                        //   ],
                        // ),
                      );
                    }),
                       const SizedBox(
                      height: 40,
                    ),
                    // 📈 Daily Expenses Chart
                    _buildDailyExpenseChart(transactions),
                    // 📊 Monthly Expenses Chart
                    _buildMonthlyExpenseChart(transactions),
                    // const Divider(height: 30),
                    const SizedBox(
                      height: 45,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'RECENT TRANSACTIONS',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              // color: Colors.grey
                            ),
                          ),
                          OutlinedButton(
                            // child: Text('hey'),
                            onPressed: () {
                              Navigator.pushNamed(context, '/transactions');
                            },
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('View All'),
                                SizedBox(width: 4),
                                Icon(Icons.arrow_forward_sharp,
                                    size:
                                        14), // This replaces the character arrow
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    ...latestSeven.map((tx) {
                      final category = categoryBox.get(tx.categoryId);
                      return TransactionItem(
                        isNewIncome: tx.isNewIncome,
                        title: tx.description,
                        subtitle: category?.name,
                        amount: tx.amount,
                        onDelete: () {
                          tx.delete();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content:
                                    Text('Transaction deleted successfully')),
                          );
                        },
                        onTap: () => showEditTransactionSheet(context, tx),
                      );
                    }),
                    const SizedBox(
                      height: 150,
                    )
                  ],
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'expense',
            onPressed: () => Navigator.pushNamed(context, '/new-expense'),
            backgroundColor: ThemeColor.expense,
            child: const Icon(Icons.remove_circle), // or any icon you prefer
          ),
          const SizedBox(height: 10),
          FloatingActionButton(
            heroTag: 'income',
            onPressed: () => Navigator.pushNamed(context, '/new-income'),
            backgroundColor: ThemeColor.income,
            child: const Icon(Icons.add_circle), // or any icon you prefer
          ),
        ],
      ),
    );
  }

  Widget _buildDailyExpenseChart(List<TransactionModel> transactions) {
    final years = transactions.map((t) => t.createdAt.year).toSet().toList()
      ..sort();
    if (!years.contains(DateTime.now().year)) {
      years.add(DateTime.now().year);
    }
    if (!years.contains(_selectedYear)) {
      _selectedYear = years.last;
    }

    final daysInMonth =
        DateUtils.getDaysInMonth(_selectedYear, _selectedMonth);
    final dailyExpenses = List<double>.filled(daysInMonth, 0);
    final dailyIncome = List<double>.filled(daysInMonth, 0);
    for (final tx in transactions) {
      if (tx.createdAt.year == _selectedYear &&
          tx.createdAt.month == _selectedMonth) {
        if (tx.isNewIncome) {
          dailyIncome[tx.createdAt.day - 1] += tx.amount;
        } else {
          dailyExpenses[tx.createdAt.day - 1] += tx.amount;
        }
      }
    }
    final maxExpense = dailyExpenses.reduce(max);
    final maxIncome = dailyIncome.reduce(max);
    final maxValue = max(maxExpense, maxIncome);
    final totalExpense = dailyExpenses.fold<double>(
        0, (sum, v) => sum + v);
    final totalIncome = dailyIncome.fold<double>(
        0, (sum, v) => sum + v);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // const Text('DAILY INCOME & EXPENSES',
                const Text('DAILY',
                    style:
                        TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                Row(
                  children: [
                    DropdownButton<int>(
                      value: _selectedMonth,
                      underline: const SizedBox(),
                      items: List.generate(12, (i) => i + 1)
                          .map((m) => DropdownMenuItem(
                                value: m,
                                child: Text(DateFormat('MMM')
                                    .format(DateTime(2024, m))),
                              ))
                          .toList(),
                      onChanged: (v) =>
                          setState(() => _selectedMonth = v!),
                    ),
                    const SizedBox(width: 8),
                    DropdownButton<int>(
                      value: _selectedYear,
                      underline: const SizedBox(),
                      items: years
                          .map((y) => DropdownMenuItem(
                                value: y,
                                child: Text(y.toString()),
                              ))
                          .toList(),
                      onChanged: (v) =>
                          setState(() => _selectedYear = v!),
                    ),
                  ],
                ),
              ],
            ),
            // const SizedBox(height: 4),
            Row(
              children: [
                Text('Expense: ${Helper.currencyFormatter(totalExpense)}',
                    style: TextStyle(
                        color: ThemeColor.expense,
                        fontSize: 13,
                        fontWeight: FontWeight.bold)),
                const SizedBox(width: 16),
                Text('Income: ${Helper.currencyFormatter(totalIncome)}',
                    style: TextStyle(
                        color: ThemeColor.income,
                        fontSize: 13,
                        fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 170,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: List.generate(daysInMonth, (i) {
                    final expense = dailyExpenses[i];
                    final income = dailyIncome[i];
                    final expenseHeight = maxValue == 0
                        ? 0.0
                        : (expense / maxValue) * 110;
                    final incomeHeight = maxValue == 0
                        ? 0.0
                        : (income / maxValue) * 110;
                    return SizedBox(
                      width: 24,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Tooltip(
                                  message: income > 0
                                      ? 'Income: ${Helper.currencyFormatter(income)}'
                                      : 'No income',
                                  child: Container(
                                    width: 8,
                                    height: incomeHeight,
                                    decoration: BoxDecoration(
                                      color: ThemeColor.income,
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 2),
                                Tooltip(
                                  message: expense > 0
                                      ? 'Expense: ${Helper.currencyFormatter(expense)}'
                                      : 'No expense',
                                  child: Container(
                                    width: 8,
                                    height: expenseHeight,
                                    decoration: BoxDecoration(
                                      color: ThemeColor.expense,
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text('${i + 1}',
                                style: const TextStyle(
                                    fontSize: 9, color: Colors.grey)),
                          ],
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthlyExpenseChart(List<TransactionModel> transactions) {
    final years = transactions.map((t) => t.createdAt.year).toSet().toList()
      ..sort();
    if (!years.contains(DateTime.now().year)) {
      years.add(DateTime.now().year);
    }
    if (!years.contains(_monthlyYear)) {
      _monthlyYear = years.last;
    }

    final monthlyExpenses = List<double>.filled(12, 0);
    final monthlyIncome = List<double>.filled(12, 0);
    for (final tx in transactions) {
      if (tx.createdAt.year == _monthlyYear) {
        if (tx.isNewIncome) {
          monthlyIncome[tx.createdAt.month - 1] += tx.amount;
        } else {
          monthlyExpenses[tx.createdAt.month - 1] += tx.amount;
        }
      }
    }
    final maxExpense = monthlyExpenses.reduce(max);
    final maxIncome = monthlyIncome.reduce(max);
    final maxValue = max(maxExpense, maxIncome);
    final totalExpense = monthlyExpenses.fold<double>(
        0, (sum, v) => sum + v);
    final totalIncome = monthlyIncome.fold<double>(
        0, (sum, v) => sum + v);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // const Text('MONTHLY INCOME & EXPENSES',
                const Text('MONTHLY',
                    style:
                        TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                DropdownButton<int>(
                  value: _monthlyYear,
                  underline: const SizedBox(),
                  items: years
                      .map((y) => DropdownMenuItem(
                            value: y,
                            child: Text(y.toString()),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() => _monthlyYear = v!),
                ),
              ],
            ),
            // const SizedBox(height: 4),
            // Text(_monthlyYear.toString(),
            //     style: const TextStyle(color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 4),
            Row(
              children: [
                Text('Expense: ${Helper.currencyFormatter(totalExpense)}',
                    style: TextStyle(
                        color: ThemeColor.expense,
                        fontSize: 13,
                        fontWeight: FontWeight.bold)),
                const SizedBox(width: 16),
                Text('Income: ${Helper.currencyFormatter(totalIncome)}',
                    style: TextStyle(
                        color: ThemeColor.income,
                        fontSize: 13,
                        fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 170,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: List.generate(12, (i) {
                  final expense = monthlyExpenses[i];
                  final income = monthlyIncome[i];
                  final expenseHeight = maxValue == 0
                      ? 0.0
                      : (expense / maxValue) * 110;
                  final incomeHeight = maxValue == 0
                      ? 0.0
                      : (income / maxValue) * 110;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Tooltip(
                                message: income > 0
                                    ? 'Income: ${Helper.currencyFormatter(income)}'
                                    : 'No income',
                                child: Container(
                                  width: 8,
                                  height: incomeHeight,
                                  decoration: BoxDecoration(
                                    color: ThemeColor.income,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 2),
                              Tooltip(
                                message: expense > 0
                                    ? 'Expense: ${Helper.currencyFormatter(expense)}'
                                    : 'No expense',
                                child: Container(
                                  width: 8,
                                  height: expenseHeight,
                                  decoration: BoxDecoration(
                                    color: ThemeColor.expense,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(DateFormat('MMM').format(DateTime(2024, i + 1)),
                              style: const TextStyle(
                                  fontSize: 9, color: Colors.grey)),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
