import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:moneyrule/src/components/transaction_item.dart';
import 'package:moneyrule/src/services/auth.dart';
import 'package:pie_chart/pie_chart.dart';
import '../../helpers/helper.dart';
import '../../models/category.dart';
import '../../models/transaction_model.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

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

          final latestFive = recentTransactions.take(5).toList();

          return Column(
            children: [
              // 💰 Overall Summary Card
              Card(
                margin: const EdgeInsets.all(0),
                elevation: 4,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(0)),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'REMAINING BALANCE',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                      Text(Helper.currencyFormatter(balance),
                          style: TextStyle(
                              fontSize: 32,
                              color: balance < 0 ? Colors.red : Colors.white)),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                              child: Row(
                            children: [
                              const Icon(
                                Icons.arrow_downward_sharp,
                                color: Colors.green,
                              ),
                              const SizedBox(
                                width: 10,
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'TOTAL INCOME',
                                    style: TextStyle(
                                        fontSize: 10, color: Colors.grey),
                                  ),
                                  Text(
                                    Helper.currencyFormatter(incomeTotal),
                                    style: const TextStyle(fontSize: 18),
                                  ),
                                ],
                              )
                            ],
                          )),
                          Expanded(
                              child: Row(
                            children: [
                              const Icon(
                                Icons.arrow_upward_sharp,
                                color: Colors.orange,
                              ),
                              const SizedBox(
                                width: 10,
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'TOTAL EXPENSES',
                                    style: TextStyle(
                                        fontSize: 10, color: Colors.grey),
                                  ),
                                  Text(
                                    Helper.currencyFormatter(expenseTotal),
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
              ),

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

                      return ListTile(
                        leading: SizedBox(
                          width: 50,
                          child: PieChart(
                            dataMap: {
                              "Remaining":
                                  balanceForCat < 0 ? 0 : balanceForCat,
                              "Expenses": expenseForCat,
                            },
                            colorList: const [Colors.green, Colors.orange],
                            chartType: ChartType.ring,
                            chartRadius: 30,
                            ringStrokeWidth:
                                5, // 👈 thickness of the ring (default is 16)
                            legendOptions:
                                const LegendOptions(showLegends: false),
                            chartValuesOptions: const ChartValuesOptions(
                                showChartValues: false),
                          ),
                        ),
                        title: Text(cat.name),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          // mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            // Text(
                            //   'Income: ₱${incomeForCat.toStringAsFixed(2)}\n',
                            //   style: const TextStyle(
                            //     color: Colors.blue,
                            //     height:
                            //         0.7, // 👈 controls line spacing (default is ~1.5)
                            //   ),
                            // ),
                            const SizedBox(height: 4),
                            Text(
                              'Expenses: ${Helper.currencyFormatter(expenseForCat)}\n',
                              style: const TextStyle(
                                color: Colors.orange,
                                height:
                                    0.65, // 👈 controls line spacing (default is ~1.5)
                              ),
                            ),
                            Text(
                              'Remaining: ${Helper.currencyFormatter(balanceForCat)}',
                              style: TextStyle(
                                height:
                                    0.65, // 👈 controls line spacing (default is ~1.5)
                                color: balanceForCat >= 0
                                    ? Colors.green
                                    : Colors.red,
                              ),
                            )
                          ],
                        ),
                      );
                    }),
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
                    ...latestFive.map((tx) {
                      final category = categoryBox.get(tx.categoryId);
                      return TransactionItem(
                        isNewIncome: tx.isNewIncome,
                        title: tx.description,
                        subtitle: category?.name,
                        amount: tx.amount,
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
            backgroundColor: Colors.orange,
            child: const Icon(Icons.remove_circle), // or any icon you prefer
          ),
          const SizedBox(height: 10),
          FloatingActionButton(
            heroTag: 'income',
            onPressed: () => Navigator.pushNamed(context, '/new-income'),
            backgroundColor: Colors.green,
            child: const Icon(Icons.add_circle), // or any icon you prefer
          ),
        ],
      ),
    );
  }
}
