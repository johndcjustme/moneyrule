import 'dart:math';

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:moneyrule/src/components/edit_transaction_sheet.dart';
import 'package:moneyrule/src/components/graph_category_label.dart';
import 'package:moneyrule/src/components/transaction_item.dart';
import 'package:moneyrule/src/models/user.dart';
import 'package:moneyrule/src/services/auth.dart';
import 'package:moneyrule/src/utils/theme_color.dart';
import 'package:moneyrule/src/utils/theme_front.dart';
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
  bool _showIncomeInGraph = false;
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;
  final TextEditingController _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final userBox = Hive.box<User>('users');
    User? currentUser;
    try {
      currentUser = userBox.values.firstWhere((user) => user.isLogin == true);
    } catch (e) {
      currentUser = null;
    }
    if (currentUser != null) {
      _notesController.text = currentUser.notes ?? '';
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  void _saveNotes() {
    final userBox = Hive.box<User>('users');
    User? currentUser;
    try {
      currentUser = userBox.values.firstWhere((user) => user.isLogin == true);
    } catch (e) {
      currentUser = null;
    }
    if (currentUser != null && mounted) {
      currentUser.notes = _notesController.text;
      currentUser.save();
      User.updateNotes(context, currentUser, _notesController.text);
    }
  }

  void _showNotesDialog() {
    final dialogController = TextEditingController(text: _notesController.text);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Notes'),
        content: TextField(
          style: const TextStyle(color: ThemeColor.textSecondary),
          controller: dialogController,
          maxLines: 10,
          decoration: const InputDecoration(
            border: InputBorder.none,
            hintText: 'Enter your notes here',
            filled: false,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              _notesController.text = dialogController.text;
              _saveNotes();
              setState(() {});
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final transactionBox = Hive.box<TransactionModel>('transactions');

    return Scaffold(
      // appBar: AppBar(
      //   title: const Text('SplitWise'),
      //   actions: [
      //     PopupMenuButton<String>(
      //       icon: const Icon(Icons.more_vert),
      //       onSelected: (value) {
      //         if (value == 'account') {
      //           Navigator.pushNamed(context, '/account');
      //         } else if (value == 'logout') {
      //           showDialog(
      //             context: context,
      //             builder: (context) => AlertDialog(
      //               title: const Text('Logout'),
      //               content: const Text('Are you sure you want to logout?'),
      //               actions: [
      //                 TextButton(
      //                   onPressed: () => Navigator.pop(context),
      //                   child: const Text('Cancel'),
      //                 ),
      //                 TextButton(
      //                   onPressed: () async {
      //                     await Auth.logout(context);
      //                   },
      //                   child: const Text('Logout'),
      //                 ),
      //               ],
      //             ),
      //           );
      //         }
      //       },
      //       itemBuilder: (context) => [
      //         const PopupMenuItem(
      //           value: 'account',
      //           child: ListTile(
      //             leading: Icon(Icons.account_circle),
      //             title: Text('Account Settings'),
      //           ),
      //         ),
      //         const PopupMenuItem(
      //           value: 'logout',
      //           child: ListTile(
      //             leading: Icon(Icons.logout),
      //             title: Text('Logout'),
      //           ),
      //         ),
      //       ],
      //     ),
      //   ],
      // ),
      body: SafeArea(child: ValueListenableBuilder(
        valueListenable: transactionBox.listenable(),
        builder: (context, Box<TransactionModel> txBox, _) {
          final transactions = txBox.values.toList();

          final incomeTotal = transactions
              .where((tx) => tx.isNewIncome)
              .fold<double>(0, (sum, tx) => sum + tx.amount);

          final expenseTotal = transactions
              .where((tx) => !tx.isNewIncome)
              .fold<double>(0, (sum, tx) => sum + tx.amount);

          final balance = incomeTotal == 0 ? 0.0 : incomeTotal - expenseTotal;

          final categoryBox = Hive.box<Category>('categories');
          final categories = categoryBox.values.toList();

          final recentTransactions = transactions.toList()
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
          final latestSeven = recentTransactions.take(5).toList();

          final today = DateTime.now();
          final todayExpenses = transactions
              .where((tx) =>
                  !tx.isNewIncome &&
                  tx.createdAt.year == today.year &&
                  tx.createdAt.month == today.month &&
                  tx.createdAt.day == today.day)
              .toList();
          final todayExpenseTotal = todayExpenses.fold<double>(
              0, (sum, tx) => sum + tx.amount);


          final sortedExpenses = todayExpenses.toList()
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

          final todayCategoryNames = sortedExpenses
              .map((tx) => tx.description)
              .toSet()
              .toList();

          final double total = incomeTotal + expenseTotal;
          final double incomeRatio = total == 0 ? 0.5 : balance / total;
          // final double expenseRatio = total == 0 ? 0.5 : expenseTotal / total;

          final userBox = Hive.box<User>('users');
          User? currentUser;
          try {
            currentUser = userBox.values.firstWhere((user) => user.isLogin == true);
          } catch (e) {
            currentUser = null;
          }

          return Column(
            children: [
              Expanded(
                child: ListView(
                  children: [
                    
                    Padding(padding: const EdgeInsets.only(left: 16, right: 16, bottom: 75, top: 20), child: 
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Row(children: [
                        Text('Split', style: TextStyle(color: ThemeColor.textTertiary)),
                        Text('Wise', style: TextStyle(color: ThemeColor.income)),
                      ]),
                      const SizedBox(height: 65),
                      const Text('Hello,', style: TextStyle(fontSize: ThemeFont.headlineMedium, color: ThemeColor.textSecondary)),
                      Text('${currentUser?.name ?? 'User'}!', style: const TextStyle(fontSize: ThemeFont.headlineMedium))
                      // Row(children: [],)
                    ]),

                     PopupMenuButton<String>(
            icon: const CircleAvatar(
              radius: 18,
              backgroundColor: ThemeColor.expense,
              child: Icon(Icons.person, size: 20, color: ThemeColor.textSecondary),
            ),
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
                    
                    ],)),

                    Row(
                          // color: Colors.red,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 16),
                                      child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [

                                            if (todayExpenses.isNotEmpty)
                                              Padding(padding: const EdgeInsets.only(bottom: 32), child: SingleChildScrollView(
                                                  scrollDirection: Axis.horizontal,
                                                  child: Row(
                                                    children: [
                                                      Padding(
                                                        padding: const EdgeInsets.only(right: 24),
                                                        child: Column(
                                                          children: [
                                                            Row(
                                                              children: [
                                                              const Text('TODAY: ',
                                                                  style: TextStyle(
                                                                      color: ThemeColor.textSecondary)),
                                                              Text(Helper.currencyFormatter(
                                                                  todayExpenseTotal, '-'), style: const TextStyle(fontWeight: FontWeight.bold))
                                                            ],
                                                          )
                                                        ],
                                                      ),
                                                    ),
                                                    ...List.generate(
                                                        todayCategoryNames.take(10).length,
                                                        (i) {
                                                      final name =
                                                          todayCategoryNames[i];
                                                      return Padding(
                                                        padding:
                                                            const EdgeInsets.only(right: 16),
                                                        child: Text(name,
                                                            style: const TextStyle(
                                                                color: ThemeColor.textTertiary, fontSize: ThemeFont.bodySmall)),
                                                      );
                                                    }),
                                                    Padding(
                                                      padding:
                                                          const EdgeInsets.only(right: 16),
                                                      child: InkWell(
                                                        onTap: () {
                                                          Navigator.pushNamed(
                                                              context,
                                                              '/transactions');
                                                        },
                                                        child: const Row(children: [
                                                          Text('More Transactions',
                                                            style: TextStyle(
                                                                color: ThemeColor.textTertiary, fontSize: 12)),
                                                          SizedBox(width: 2),
                                                          Icon(Icons.chevron_right, size: 14, color: ThemeColor.textTertiary,)
                                                        ],),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ))
                                            else const Padding(padding: EdgeInsets.only(bottom: 32), child: Text('No expenses recorded today', style: TextStyle(color: ThemeColor.textTertiary))),

                                              

                                            // SizedBox(height: 28,),
                                          // const Row(children: [
                                          //   Text(
                                          //   'TOTAL INCOME',
                                          //   style: TextStyle(
                                          //       color: Colors.grey,
                                          //       fontSize: 12),
                                          // )
                                          // ]),
                                          // const SizedBox(
                                          //   width: 10,
                                          // ),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            crossAxisAlignment: CrossAxisAlignment.end,
                                            children: [
                                            GestureDetector(
                                              onTap: () {
                                                setState(() {
                                                  _showIncome = !_showIncome;
                                                });
                                              },
                                              child: Text(
                                              _showIncome
                                                  ? Helper.currencyFormatter(
                                                      balance)
                                                  : '••••••',
                                              style: TextStyle(
                                                fontSize: ThemeFont.headlineSmall,
                                                color: balance < 0 ? ThemeColor.danger : ThemeColor.income
                                                // fontWeight: FontWeight.bold
                                              ),
                                            )
                                            ),
                                            Text(Helper.currencyFormatter(expenseTotal, '-'), style: TextStyle(fontSize: 16, color: balance == 0 && expenseTotal > 0 ? ThemeColor.danger : ThemeColor.textSecondary, fontWeight: FontWeight.bold ))

                                          ])
                                        ],
                                          )),
                            )
                          ]),


                      // Padding(padding: const EdgeInsets.only(top: 7, left: 16, right: 16), child: SizedBox(
                      //   width: double.infinity,
                      //   height: 5,
                      //   child: Row(
                      //     children: [
                      //       Expanded(
                      //         flex: (incomeRatio * 1000).round(),
                      //         child: Container(
                      //           decoration: const BoxDecoration(
                      //             color: ThemeColor.income,
                      //             borderRadius: BorderRadius.only(
                      //               topLeft: Radius.circular(15.0),
                      //               bottomLeft: Radius.circular(15.0),
                      //             ),
                      //           ),
                      //         ),
                      //       ),
                      //       Expanded(
                      //         flex: (expenseRatio * 1000).round(),
                      //         child: Container(
                      //           decoration: const BoxDecoration(
                      //             color: ThemeColor.expense,
                      //             borderRadius: BorderRadius.only(
                      //               topRight: Radius.circular(15.0),
                      //               bottomRight: Radius.circular(15.0),
                      //             ),

                      //           ),
                      //         ),
                      //       ),
                        
                      //     ],
                      //   ),
                      // ),),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                        child: LinearProgressIndicator(
                          value: total == 0 ? 0 : incomeRatio,
                          backgroundColor: ThemeColor.expense,
                          valueColor: const AlwaysStoppedAnimation<Color>(ThemeColor.income),
                          minHeight: 6.0,
                          borderRadius: const BorderRadius.all(Radius.circular(4)),
                        ),
                      ),
                      // Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                      //   Text(Helper.currencyFormatter(incomeTotal), style: const TextStyle(fontSize: ThemeFont.bodySmall)),
                      //   // const SizedBox(width: 14),
                      //   // Text(Helper.currencyFormatter(expenseTotal, '-'), style: TextStyle(fontSize: 16, color: balance == 0 && expenseTotal > 0 ? ThemeColor.danger : ThemeColor.textSecondary, fontWeight: FontWeight.bold ))
                      // ],),),


                  // SizedBox(height: 20,),


                  //   Card(
                  // margin: const EdgeInsets.all(0),
                  // elevation: 4,
                  // shape: RoundedRectangleBorder(
                  //     borderRadius: BorderRadius.circular(0)),
                  // child: Column(
                  //   children: [
                       
                  //     Padding(
                  //       padding: const EdgeInsets.symmetric(
                  //           horizontal: 16, vertical: 32),
                  //       child: Column(
                  //         crossAxisAlignment: CrossAxisAlignment.stretch,
                  //         children: [
                  //           // const Text(
                  //           //   'REMAINING BALANCE',
                  //           //   style:
                  //           //       TextStyle(color: Colors.grey, fontSize: 12),
                  //           // ),
                  //           // Text(Helper.currencyFormatter(balance),
                  //           //     style: TextStyle(
                  //           //         fontSize: 32,
                  //           //         color: balance < 0
                  //           //             ? Colors.red
                  //           //             : Colors.white)),
                  //           // const SizedBox(height: 14),
                  //           Row(
                  //             children: [
                  //               Expanded(
                  //                   child: Row(
                  //                 children: [
                  //                   Icon(
                  //                     Icons.arrow_downward_sharp,
                  //                     color: ThemeColor.income,
                  //                   ),
                  //                   const SizedBox(
                  //                     width: 10,
                  //                   ),
                  //                   Column(
                  //                     crossAxisAlignment:
                  //                         CrossAxisAlignment.start,
                  //                     children: [
                  //                       const Text(
                  //                         'BALANCE',
                  //                         style: TextStyle(
                  //                             fontSize: 10, color: Colors.grey),
                  //                       ),
                  //                       Text(
                  //                         Helper.currencyFormatter(balance),
                  //                         style: TextStyle(
                  //                             fontSize: 18,
                  //                             color: balance < 0
                  //                                 ? Colors.red
                  //                                 : Colors.white),
                  //                       ),
                  //                     ],
                  //                   )
                  //                 ],
                  //               )),
                  //               Expanded(
                  //                   child: Row(
                  //                 children: [
                  //                   Icon(
                  //                     Icons.arrow_upward_sharp,
                  //                     color: ThemeColor.expense,
                  //                   ),
                  //                   const SizedBox(
                  //                     width: 10,
                  //                   ),
                  //                   Column(
                  //                     crossAxisAlignment:
                  //                         CrossAxisAlignment.start,
                  //                     children: [
                  //                       const Text(
                  //                         'EXPENSES',
                  //                         style: TextStyle(
                  //                             fontSize: 10, color: Colors.grey),
                  //                       ),
                  //                       Text(
                  //                         Helper.currencyFormatter(
                  //                             expenseTotal),
                  //                         style: const TextStyle(fontSize: 18),
                  //                       ),
                  //                     ],
                  //                   )
                  //                 ],
                  //               )),
                  //             ],
                  //           )
                  //           // const Divider(height: 20),
                  //           // Text(
                  //           //   '🧮 Remaining Balance: ₱${balance.toStringAsFixed(2)}',
                  //           //   style: TextStyle(
                  //           //     color: balance >= 0 ? Colors.green : Colors.red,
                  //           //     fontWeight: FontWeight.bold,
                  //           //   ),
                  //           // ),
                  //         ],
                  //       ),
                  //     ),
                  //     SizedBox(
                  //       width: double.infinity,
                  //       height: 4,
                  //       child: Row(
                  //         children: [
                  //           Expanded(
                  //             flex: (incomeRatio * 1000).round(),
                  //             child: Container(
                  //               decoration: BoxDecoration(
                  //                 color: ThemeColor.income,
                  //               ),
                  //             ),
                  //           ),
                  //           Expanded(
                  //             flex: (expenseRatio * 1000).round(),
                  //             child: Container(
                  //               decoration: BoxDecoration(
                  //                 color: ThemeColor.expense,
                  //               ),
                  //             ),
                  //           ),
                  //         ],
                  //       ),
                  //     ),
                     
                  //   ],
                  // )),
                    const SizedBox(
                      height: 27,
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
                        trailing: SizedBox(
                          width: 175, // ⬅️ Increased width for better layout
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
                                      Helper.currencyFormatter(expenseForCat, '-'),
                                      style: const TextStyle(
                                        color: ThemeColor.textSecondary,
                                        fontSize: ThemeFont.bodySmall,
                                        height: 1.2,
                                      ),
                                    ),
                                    Text(
                                      Helper.currencyFormatter(balanceForCat, balanceForCat >= 0 ? '+' : ''),
                                      style: TextStyle(
                                        color: balanceForCat >= 0
                                            ? ThemeColor.income
                                            : ThemeColor.danger,
                                        fontSize: ThemeFont.bodySmall,
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
                                colorList: const [
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
                        title: Text(cat.name, style: const TextStyle(fontSize: ThemeFont.bodyMedium, fontWeight: FontWeight.bold)),
                        subtitle: Text(
                            Helper.currencyFormatter(totalIncome),
                            style: const TextStyle(
                                color: ThemeColor.textSecondary, fontSize: ThemeFont.bodySmall))
                      );
                    }),


ListTile(
                        trailing: SizedBox(
                          width: 175, // ⬅️ Increased width for better layout
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
                                      Helper.currencyFormatter(expenseTotal, '-'),
                                      style: const TextStyle(
                                        color: ThemeColor.textSecondary,
                                        fontSize: ThemeFont.bodySmall,
                                        height: 1.2,
                                      ),
                                    ),
                                    Text(
                                      Helper.currencyFormatter(balance, balance >= 0 ? '+' : ''),
                                      style: TextStyle(
                                        color: balance >= 0
                                            ? ThemeColor.income
                                            : ThemeColor.danger,
                                        fontSize: ThemeFont.bodySmall,
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
                                      balance < 0 ? 0 : balance,
                                  "Expenses": expenseTotal,
                                },
                                colorList: const [
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
                        title: const Text('All', style: TextStyle(fontSize: ThemeFont.bodyMedium, fontWeight: FontWeight.bold)),
                        subtitle: Text(
                            Helper.currencyFormatter(balance + expenseTotal),
                            style: const TextStyle(
                                color: ThemeColor.textSecondary, fontSize: ThemeFont.bodySmall))
                      ),


                     const SizedBox(
                       height: 32,
                     ),
                     Padding(
                       padding: const EdgeInsets.symmetric(horizontal: 16),
                       child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                         children: [
                           Row(
                             mainAxisSize: MainAxisSize.min,
                             children: [
                               const Text('INCOME',
                                   style: TextStyle(
                                       color: ThemeColor.textSecondary)),
                               Checkbox(
                                 value: _showIncomeInGraph,
                                 onChanged: (v) =>
                                     setState(() => _showIncomeInGraph = v ?? false),
                               ),
                             ],
                           ),
                           Row(children: [
                           DropdownButton<int>(
                             value: _selectedMonth,
                             underline: const SizedBox(),
                             items: List.generate(12, (i) => i + 1)
                                 .map((m) => DropdownMenuItem(
                                       value: m,
                                       child: Text(DateFormat('MMM').format(DateTime(2024, m)).toUpperCase()),
                                     ))
                                 .toList(),
                             onChanged: (v) => setState(() => _selectedMonth = v!),
                           ),
                           const SizedBox(width: 16),
                           DropdownButton<int>(
                             value: _selectedYear,
                             underline: const SizedBox(),
                             items: List.generate(10, (i) => DateTime.now().year - 5 + i)
                                 .map((y) => DropdownMenuItem(
                                       value: y,
                                       child: Text(y.toString()),
                                     ))
                                 .toList(),
                             onChanged: (v) => setState(() => _selectedYear = v!),
                           ),
                          ],)
                         ],
                       ),
                     ),
                     _buildDailyExpenseChart(transactions),
                     _buildMonthlyExpenseChart(transactions),
                    // const Divider(height: 30),
                    const SizedBox(
                      height: 32,
                    ),
                    Padding(
                      padding: const EdgeInsets.only(
                          left: 16, right: 16, bottom: 7),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'RECENT',
                            style: TextStyle(
                              fontSize: ThemeFont.titleMedium,
                              fontWeight: FontWeight.bold
                            ),
                          ),
                          IconButton(
                            onPressed: () {
                              Navigator.pushNamed(context, '/transactions');
                            },
                            icon: const Icon(Icons.chevron_right),
                          ),
                          // TextButton(
                          //   onPressed: () {
                          //     Navigator.pushNamed(context, '/transactions');
                          //   },
                          //   child: const Row(
                          //     mainAxisSize: MainAxisSize.min,
                          //     children: [
                          //       Text('More', style: TextStyle(color: ThemeColor.textPrimary, fontSize: ThemeFont.titleMedium)),
                          //       SizedBox(width: 4),
                          //       Icon(Icons.chevron_right,
                          //           size: ThemeFont.titleMedium, color: ThemeColor.textPrimary,),
                          //     ],
                          //   ),
                          // ),
                        ],
                      ),
                    ),
                    if (latestSeven.isNotEmpty)
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
                      })
                    else const Center(child: Padding(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16), child: Text('No recent transactions', style: TextStyle(color: ThemeColor.textTertiary),))),
                      Padding(
                  padding: const EdgeInsets.only(bottom: 8, top: 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('NOTES', style: TextStyle(fontSize: ThemeFont.titleMedium, fontWeight: FontWeight.bold)),
                            IconButton(
                              onPressed: _showNotesDialog,
                              icon: const Icon(Icons.edit, size: 18),
                            ),
                          ],
                        ),
                      ),
                      // const SizedBox(height: 4),
                      Padding(padding: const EdgeInsets.all(16), child: Text(
                        _notesController.text.isEmpty ? 'No notes' : _notesController.text,
                        style: const TextStyle(
                          color: ThemeColor.textSecondary,
                          fontSize: ThemeFont.bodyMedium,
                        ),
                      ))
                    ],
                  ),
                ),
                  const SizedBox(
                      height: 150,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      )),
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
            foregroundColor: ThemeColor.textTertiary,
            child: const Icon(Icons.add_circle), // or any icon you prefer
          ),
        ],
      ),
    );
  }

  String? _categoryName(TransactionModel tx) {
    final catBox = Hive.box<Category>('categories');
    return catBox.get(tx.categoryId)?.name.toLowerCase();
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
    final dailyIncome = List<double>.filled(daysInMonth, 0);
    final dailyNeeds = List<double>.filled(daysInMonth, 0);
    final dailyWants = List<double>.filled(daysInMonth, 0);
    final dailySavings = List<double>.filled(daysInMonth, 0);
    for (final tx in transactions) {
      if (tx.createdAt.year == _selectedYear &&
          tx.createdAt.month == _selectedMonth) {
        if (tx.isNewIncome) {
          dailyIncome[tx.createdAt.day - 1] += tx.amount;
          continue;
        }
        final name = _categoryName(tx);
        if (name == 'needs') {
          dailyNeeds[tx.createdAt.day - 1] += tx.amount;
        } else if (name == 'wants') {
          dailyWants[tx.createdAt.day - 1] += tx.amount;
        } else if (name == 'save') {
          dailySavings[tx.createdAt.day - 1] += tx.amount;
        }
      }
    }
    final totalIncome = dailyIncome.fold<double>(0, (s, v) => s + v);
    final totalNeeds = dailyNeeds.fold<double>(0, (s, v) => s + v);
    final totalWants = dailyWants.fold<double>(0, (s, v) => s + v);
    final totalSavings = dailySavings.fold<double>(0, (s, v) => s + v);

    final maxExpense = List.generate(daysInMonth,
        (i) => dailyNeeds[i] + dailyWants[i] + dailySavings[i]).reduce(max);
    final maxValue = max(maxExpense,
        _showIncomeInGraph ? dailyIncome.reduce(max) : 0.0);

    return Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Text(DateFormat('MMM y').format(DateTime(_selectedYear, _selectedMonth)).toUpperCase(),
                    style:
                        const TextStyle(fontWeight: FontWeight.bold, color: ThemeColor.textSecondary)),),

            const SizedBox(height: 10),

            Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
              GraphCategoryLabel(
                title: 'Income', 
                value: Helper.currencyFormatter(totalIncome, '+'),
                color: ThemeColor.income,
              ),
              GraphCategoryLabel(
                title: 'Needs', 
                value: Helper.currencyFormatter(totalNeeds, '-'),
                color: ThemeColor.textPrimary,
              ),
              GraphCategoryLabel(
                title: 'Wants', 
                value: Helper.currencyFormatter(totalWants, '-'),
                color: ThemeColor.textSecondary,
              ),
              GraphCategoryLabel(
                title: 'Save', 
                value: Helper.currencyFormatter(totalSavings, '-'),
                color: ThemeColor.textTertiary,
              ),
            ],),

            const SizedBox(height: 16),
            SizedBox(
              height: 170,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: List.generate(daysInMonth, (i) {
                    final income = dailyIncome[i];
                    final needs = dailyNeeds[i];
                    final wants = dailyWants[i];
                    final savings = dailySavings[i];
                    final incomeHeight = maxValue == 0
                        ? 0.0
                        : (income / maxValue) * 110;
                    final needsHeight = maxValue == 0
                        ? 0.0
                        : (needs / maxValue) * 110;
                    final wantsHeight = maxValue == 0
                        ? 0.0
                        : (wants / maxValue) * 110;
                    final savingsHeight = maxValue == 0
                        ? 0.0
                        : (savings / maxValue) * 110;
                    return SizedBox(
                      width: 24,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Tooltip(
                              message:
                                  'Income: ${Helper.currencyFormatter(income, '+')}\nNeeds: ${Helper.currencyFormatter(needs, '-')}\nWants: ${Helper.currencyFormatter(wants, '-')}\nSavings: ${Helper.currencyFormatter(savings, '-')}',
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.end,
                                 children: [
                                  if (_showIncomeInGraph)
                                    Container(
                                      width: 14,
                                      height: incomeHeight,
                                      decoration: const BoxDecoration(
                                        color: ThemeColor.income,
                                        borderRadius: BorderRadius.vertical(
                                            top: Radius.circular(2)),
                                      ),
                                    ),
                                  Container(
                                    width: 14,
                                    height: savingsHeight,
                                    decoration: BoxDecoration(
                                      color: ThemeColor.textPrimary,
                                      borderRadius: _showIncomeInGraph
                                          ? null
                                          : const BorderRadius.vertical(
                                              top: Radius.circular(2)),
                                    ),
                                  ),
                                  Container(
                                    width: 14,
                                    height: wantsHeight,
                                    color: ThemeColor.textSecondary,
                                  ),
                                  Container(
                                    width: 14,
                                    height: needsHeight,
                                    decoration: const BoxDecoration(
                                      color: ThemeColor.textTertiary,
                                      borderRadius: BorderRadius.vertical(
                                          bottom: Radius.circular(2)),
                                    ),
                                  ),
                                ],
                              ),
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
      );
  }

  Widget _buildMonthlyExpenseChart(List<TransactionModel> transactions) {
    final years = transactions.map((t) => t.createdAt.year).toSet().toList()
      ..sort();
    if (!years.contains(DateTime.now().year)) {
      years.add(DateTime.now().year);
    }
    if (!years.contains(_selectedYear)) {
      _selectedYear = years.last;
    }

    final monthlyIncome = List<double>.filled(12, 0);
    final monthlyNeeds = List<double>.filled(12, 0);
    final monthlyWants = List<double>.filled(12, 0);
    final monthlySavings = List<double>.filled(12, 0);
    for (final tx in transactions) {
      if (tx.createdAt.year == _selectedYear) {
        if (tx.isNewIncome) {
          monthlyIncome[tx.createdAt.month - 1] += tx.amount;
          continue;
        }
        final name = _categoryName(tx);
        if (name == 'needs') {
          monthlyNeeds[tx.createdAt.month - 1] += tx.amount;
        } else if (name == 'wants') {
          monthlyWants[tx.createdAt.month - 1] += tx.amount;
        } else if (name == 'save') {
          monthlySavings[tx.createdAt.month - 1] += tx.amount;
        }
      }
    }
    final totalIncome = monthlyIncome.fold<double>(0, (s, v) => s + v);
    final totalNeeds = monthlyNeeds.fold<double>(0, (s, v) => s + v);
    final totalWants = monthlyWants.fold<double>(0, (s, v) => s + v);
    final totalSavings = monthlySavings.fold<double>(0, (s, v) => s + v);

    final maxExpense = List.generate(12,
        (i) => monthlyNeeds[i] + monthlyWants[i] + monthlySavings[i]).reduce(max);
    final maxValue = max(maxExpense,
        _showIncomeInGraph ? monthlyIncome.reduce(max) : 0.0);

    return Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child:
                Text('YEAR $_selectedYear',
                    style:
                        const TextStyle(fontWeight: FontWeight.bold, color: ThemeColor.textSecondary)),
            ),

            const SizedBox(height: 10),

            Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
              GraphCategoryLabel(
                title: 'Income', 
                value: Helper.currencyFormatter(totalIncome, '+'),
                color: ThemeColor.income,
              ),
              GraphCategoryLabel(
                title: 'Needs', 
                value: Helper.currencyFormatter(totalNeeds, '-'),
                color: ThemeColor.textPrimary,
              ),
              GraphCategoryLabel(
                title: 'Wants', 
                value: Helper.currencyFormatter(totalWants, '-'),
                color: ThemeColor.textSecondary,
              ),
              GraphCategoryLabel(
                title: 'Save', 
                value: Helper.currencyFormatter(totalSavings, '-'),
                color: ThemeColor.textTertiary,
              ),
            ],),

            
            const SizedBox(height: 16),
            SizedBox(
              height: 170,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: List.generate(12, (i) {
                  final income = monthlyIncome[i];
                  final needs = monthlyNeeds[i];
                  final wants = monthlyWants[i];
                  final savings = monthlySavings[i];
                  final incomeHeight = maxValue == 0
                      ? 0.0
                      : (income / maxValue) * 110;
                  final needsHeight = maxValue == 0
                      ? 0.0
                      : (needs / maxValue) * 110;
                  final wantsHeight = maxValue == 0
                      ? 0.0
                      : (wants / maxValue) * 110;
                  final savingsHeight = maxValue == 0
                      ? 0.0
                      : (savings / maxValue) * 110;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Tooltip(
                            message:
                                'Income: ${Helper.currencyFormatter(income, '+')}\nNeeds: ${Helper.currencyFormatter(needs, '-')}\nWants: ${Helper.currencyFormatter(wants, '-')}\nSavings: ${Helper.currencyFormatter(savings, '-')}',
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                               children: [
                                if (_showIncomeInGraph)
                                  Container(
                                    width: 16,
                                    height: incomeHeight,
                                    decoration: const BoxDecoration(
                                      color: ThemeColor.income,
                                      borderRadius: BorderRadius.vertical(
                                          top: Radius.circular(2)),
                                    ),
                                  ),
                                Container(
                                  width: 16,
                                  height: savingsHeight,
                                  decoration: BoxDecoration(
                                    color: ThemeColor.textPrimary,
                                    borderRadius: _showIncomeInGraph
                                        ? null
                                        : const BorderRadius.vertical(
                                            top: Radius.circular(2)),
                                  ),
                                ),
                                Container(
                                  width: 16,
                                  height: wantsHeight,
                                  color: ThemeColor.textSecondary,
                                ),
                                Container(
                                  width: 16,
                                  height: needsHeight,
                                  decoration: const BoxDecoration(
                                    color: ThemeColor.textTertiary,
                                    borderRadius: BorderRadius.vertical(
                                        bottom: Radius.circular(2)),
                                  ),
                                ),
                              ],
                            ),
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
      );
  }
}
