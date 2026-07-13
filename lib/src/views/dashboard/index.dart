import 'dart:math';

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:moneyrule/src/components/card_expenses.dart';
import 'package:moneyrule/src/components/category_summary_item.dart';
import 'package:moneyrule/src/components/edit_transaction_sheet.dart';
import 'package:moneyrule/src/components/graph_category_label.dart';
import 'package:moneyrule/src/components/graph_column_item.dart';
import 'package:moneyrule/src/components/no_recent_transactions.dart';
import 'package:moneyrule/src/components/notes.dart';
import 'package:moneyrule/src/components/notes_title.dart';
import 'package:moneyrule/src/components/recent_transaction_title.dart';
import 'package:moneyrule/src/components/select_month.dart';
import 'package:moneyrule/src/components/select_year.dart';
import 'package:moneyrule/src/components/transaction_item.dart';
import 'package:moneyrule/src/models/user.dart';
import 'package:moneyrule/src/services/auth.dart';
import 'package:moneyrule/src/services/notes_service.dart';
import 'package:moneyrule/src/utils/theme_color.dart';
import 'package:moneyrule/src/utils/theme_front.dart';
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
  final _notesService = NotesService();  

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
              _notesService.saveNotes(_notesController.text);
              // _saveNotes();
              setState(() {});
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showAddUserDialog() {
    final nameController = TextEditingController();
    // final passwordController = TextEditingController();
    final userBox = Hive.box<User>('users');
    final categoryBox = Hive.box<Category>('categories');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add User'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Username',
                border: OutlineInputBorder(),
              ),
            ),
            // const SizedBox(height: 16),
            // TextField(
            //   controller: passwordController,
            //   decoration: const InputDecoration(
            //     labelText: 'Password',
            //     border: OutlineInputBorder(),
            //   ),
            //   obscureText: true,
            // ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final navigator = Navigator.of(context);
              final name = nameController.text.trim();
              const password = '1234';

              if (name.isEmpty || password.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Fill all fields')),
                );
                return;
              }

              final exists = userBox.values.any((u) => u.name == name);
              if (exists) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Username already exists')),
                );
                return;
              }

              final newUser = User(
                id: User.generateId(),
                name: name,
                password: password,
                isLogin: false,
                type: 'standard',
              );
              await userBox.add(newUser);

              final newUserId = newUser.id;
              await categoryBox.add(
                Category(name: 'Needs', percentage: 50, amount: 0, userId: newUserId),
              );
              await categoryBox.add(
                Category(name: 'Wants', percentage: 30, amount: 0, userId: newUserId),
              );
              await categoryBox.add(
                Category(name: 'Save', percentage: 20, amount: 0, userId: newUserId),
              );

              // Log out any currently logged-in user, then log in the new user
              for (final u in userBox.values) {
                if (u.isLogin) {
                  u.isLogin = false;
                  await u.save();
                }
              }
              newUser.isLogin = true;
              await newUser.save();

              navigator.pop();
              navigator.pushReplacementNamed('/dashboard');
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final transactionBox = Hive.box<TransactionModel>('transactions');

    return Scaffold(
      body: SafeArea(child: ValueListenableBuilder(
        valueListenable: transactionBox.listenable(),
        builder: (context, Box<TransactionModel> txBox, _) {
          final currentUserId = User.currentUserId();
          final transactions = txBox.values
              .where((tx) => tx.userId == currentUserId)
              .toList();

          final incomeTotal = transactions
              .where((tx) => tx.isNewIncome)
              .fold<double>(0, (sum, tx) => sum + tx.amount);

          final expenseTotal = transactions
              .where((tx) => !tx.isNewIncome)
              .fold<double>(0, (sum, tx) => sum + tx.amount);

          final balance = incomeTotal == 0 ? 0.0 : incomeTotal - expenseTotal;

          final categoryBox = Hive.box<Category>('categories');
          final categories = categoryBox.values
              .where((c) => c.userId == currentUserId)
              .toList();

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
          final yesterday = DateTime(today.year, today.month, today.day - 1);
          final yesterdayExpenses = transactions
              .where((tx) =>
                  !tx.isNewIncome &&
                  tx.createdAt.year == yesterday.year &&
                  tx.createdAt.month == yesterday.month &&
                  tx.createdAt.day == yesterday.day)
              .toList();

          final todayBreakdown = _expenseBreakdown(todayExpenses);
          final yesterdayBreakdown = _expenseBreakdown(yesterdayExpenses);

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
                    const Padding(padding:  EdgeInsets.all(16), child: Row(children: [
                      Text('Split', style: TextStyle(fontSize: ThemeFont.bodySmall, color: ThemeColor.textSecondary)),
                      Text('Wise', style: TextStyle(fontSize: ThemeFont.bodySmall, color: ThemeColor.income)),
                    ])),
                    Padding(padding: const EdgeInsets.only(left: 16, right: 16, bottom: 75), child: 
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                         
                          const SizedBox(height: 65),
                          const Text('Hello,', style: TextStyle(fontSize: ThemeFont.headlineMedium, color: ThemeColor.textSecondary)),
                          Text('${currentUser?.name ?? 'User'}!', style: const TextStyle(fontSize: ThemeFont.headlineMedium))
                        ]),

                        Row(children: [
                          IconButton(onPressed: () {
                            _showNotesDialog();
                          }, icon: const Icon(Icons.edit), color: ThemeColor.textSecondary,),
                          const SizedBox(width: 6),
                          PopupMenuButton<String>(
                            icon: const CircleAvatar(
                              radius: 20,
                              backgroundColor: ThemeColor.expense,
                              child: Icon(Icons.person, size: 20, color: ThemeColor.textSecondary),
                            ),
                            onSelected: (value) async {
                              if (value == 'account') {
                                Navigator.pushNamed(context, '/account');
                              } else if (value == 'categories') {
                                Navigator.pushNamed(context, '/categories');
                              } else if (value.startsWith('switch:')) {
                                final targetId = value.substring('switch:'.length);
                                final navigator = Navigator.of(context);
                                final userBox = Hive.box<User>('users');
                                for (final u in userBox.values) {
                                  u.isLogin = u.id == targetId;
                                  await u.save();
                                }
                                navigator.pushReplacementNamed('/dashboard');
                              } else if (value == 'add_user') {
                                _showAddUserDialog();
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
                                value: 'categories',
                                child: ListTile(
                                  leading: Icon(Icons.category),
                                  title: Text('Categories'),
                                ),
                              ),
                              // PopupMenuDivider(),
                                const PopupMenuItem<String>(
                                enabled: false, // Disables tap actions and styling
                                child: Text(
                                  'USERS',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: ThemeColor.textSecondary,
                                  ),
                                ),
                              ),
                              // list of users here
                              for (final user in Hive.box<User>('users').values)
                                PopupMenuItem(
                                  value: 'switch:${user.id}',
                                  child: ListTile(
                                    leading: Icon(
                                      user.isLogin ? Icons.check_circle : Icons.person,
                                      color: user.isLogin ? ThemeColor.income : null,
                                    ),
                                    title: Text(user.name),
                                    trailing: user.isLogin ? const Text('Active', style: TextStyle(color: ThemeColor.income)) : null,
                                  ),
                                ),

                              const PopupMenuItem(
                                value: 'add_user',
                                child: ListTile(
                                  leading: Icon(Icons.add),
                                  title: Text('Add User'),
                                ),
                              ),
                              // const PopupMenuItem(
                              //   value: 'logout',
                              //   child: ListTile(
                              //     leading: Icon(Icons.logout),
                              //     title: Text('Logout'),
                              //   ),
                              // ),
                            ],
                          ),
                        ]),
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
                                          // Row(children: [
                                          //   CardExpenses(
                                          //     title: 'Today',
                                          //     total: todayBreakdown.total,
                                          //     needs: todayBreakdown.needs,
                                          //     wants: todayBreakdown.wants,
                                          //     save: todayBreakdown.save,
                                          //     transactions: todayBreakdown.count,
                                          //   ),
                                          //   const SizedBox(width: 8),
                                          //   CardExpenses(
                                          //     title: 'Yesterday',
                                          //     total: yesterdayBreakdown.total,
                                          //     needs: yesterdayBreakdown.needs,
                                          //     wants: yesterdayBreakdown.wants,
                                          //     save: yesterdayBreakdown.save,
                                          //     transactions: yesterdayBreakdown.count,
                                          //   ),

                                          // ],),

                                          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                                            Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
                                              const Text('TODAY', style: TextStyle(color: ThemeColor.textPrimary, fontWeight: FontWeight.bold)),
                                              Text(Helper.currencyFormatter(todayBreakdown.total, '-'), style: const TextStyle(fontSize: ThemeFont.titleLarge, color: ThemeColor.textSecondary)),
                                              Center(child: Container(width: 200, child: const Divider(color: ThemeColor.textTertiary, thickness: 0.5,),)),
                                              Text(Helper.currencyFormatter(yesterdayBreakdown.total, '-'), style: const TextStyle(fontSize: ThemeFont.bodyMedium, color: ThemeColor.textTertiary, fontWeight: FontWeight.bold)),
                                              const Text('Yesterday', style: TextStyle(color: ThemeColor.textSecondary, fontSize: ThemeFont.bodySmall)),
                                            ],),
                                            // SizedBox(width: 16,),
                                            //   Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                            //   Text('YESTERDAY', style: TextStyle(color: ThemeColor.textSecondary)),
                                            //   Text('-10,000.00', style: TextStyle(fontSize: ThemeFont.titleMedium, color: ThemeColor.textTertiary, fontWeight: FontWeight.bold)),
                                            // ],),
                                            // const SizedBox(width: 16,),
                                            // const SizedBox(width: 16,),
                                            // Text('YESTERDAY', style: TextStyle(color: ThemeColor.textTertiary),),
                                          ],),
                                          // Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Center(child: Container(width: 250, child: Divider(),))
                                          // ),
                                          // Divider(),
                                          const SizedBox(height: 24),

                                          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
                                              const Text('NEEDS', style: TextStyle(fontSize: ThemeFont.bodySmall, fontWeight: FontWeight.bold)),
                                              const SizedBox(height: 4,),
                                              Text(Helper.currencyFormatter(todayBreakdown.needs, '-'), style: const TextStyle(fontWeight: FontWeight.bold, color: ThemeColor.textSecondary)),
                                              Text(Helper.currencyFormatter(yesterdayBreakdown.needs, '-'), style: const TextStyle(color: ThemeColor.textTertiary)),
                                            ],)),
                                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
                                              const Text('WANTS', style: TextStyle(fontSize: ThemeFont.bodySmall, fontWeight: FontWeight.bold)),
                                              const SizedBox(height: 4,),
                                              Text(Helper.currencyFormatter(todayBreakdown.wants, '-'), style: const TextStyle(fontWeight: FontWeight.bold, color: ThemeColor.textSecondary)),
                                              Text(Helper.currencyFormatter(yesterdayBreakdown.wants, '-'), style: const TextStyle(color: ThemeColor.textTertiary)),
                                            ],)),
                                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
                                              const Text('SAVE', style: TextStyle(fontSize: ThemeFont.bodySmall, fontWeight: FontWeight.bold)),
                                              const SizedBox(height: 4,),
                                              Text(Helper.currencyFormatter(todayBreakdown.save, '-'), style: const TextStyle(fontWeight: FontWeight.bold, color: ThemeColor.textSecondary)),
                                              Text(Helper.currencyFormatter(yesterdayBreakdown.save, '-'), style: const TextStyle(color: ThemeColor.textTertiary)),
                                            ],)),
                                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
                                            const Text('TXs', style: TextStyle(fontSize: ThemeFont.bodySmall, fontWeight: FontWeight.bold)),
                                              const SizedBox(height: 4,),
                                              Text(todayBreakdown.count.toString(), style: const TextStyle(fontWeight: FontWeight.bold, color: ThemeColor.textSecondary)),
                                              Text(yesterdayBreakdown.count.toString(), style: const TextStyle(color: ThemeColor.textTertiary)),
                                            ],)),
                                          ],),

                                          const SizedBox(height: 32),

                                          if (todayExpenses.isNotEmpty)
                                            Padding(padding: const EdgeInsets.only(bottom: 32), child: SingleChildScrollView(
                                                scrollDirection: Axis.horizontal,
                                                child: Row(
                                                  children: [
                                                    const Padding(
                                                      padding: EdgeInsets.only(right: 16),
                                                      child: Column(
                                                        children: [
                                                          Row(
                                                            children: [
                                                            Text('TODAY\'S TX: ',
                                                                style: TextStyle(
                                                                    color: ThemeColor.textSecondary)),
                                                            // Text(Helper.currencyFormatter(
                                                            //     todayExpenseTotal, '-'), style: const TextStyle(fontWeight: FontWeight.bold))
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
                                                              color: ThemeColor.textTertiary)),
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
                                                              color: ThemeColor.textTertiary)),
                                                        SizedBox(width: 2),
                                                        Icon(Icons.chevron_right, size: 14, color: ThemeColor.textTertiary,)
                                                      ],),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ))
                                          else const Center(child: Padding(padding: EdgeInsets.only(bottom: 32), child: Text('No expenses recorded today', style: TextStyle(color: ThemeColor.textTertiary)))),
                                  ],
                              )),
                          )
                      ]),


                      // add tab here with values All(default), Today, Yesterday
                      // const SizedBox(height: 16,),

                      // Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Row(
                      //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      //   crossAxisAlignment: CrossAxisAlignment.end,
                      //   children: [
                      //   GestureDetector(
                      //     onTap: () {
                      //       setState(() {
                      //         _showIncome = !_showIncome;
                      //       });
                      //     },
                      //     child: Text(
                      //     _showIncome
                      //         ? Helper.currencyFormatter(
                      //             balance)
                      //         : '••••••',
                      //     style: TextStyle(
                      //       fontSize: ThemeFont.headlineSmall,
                      //       color: balance < 0 ? ThemeColor.danger : ThemeColor.income
                      //       // fontWeight: FontWeight.bold
                      //     ),
                      //   )
                      //   ),
                      //   Text(Helper.currencyFormatter(expenseTotal, '-'), style: const TextStyle(fontSize: 16, color: ThemeColor.textSecondary, fontWeight: FontWeight.bold ))
                      // ])),

                      // Padding(
                      //   padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                      //   child: LinearProgressIndicator(
                      //     value: total == 0 ? 0 : incomeRatio,
                      //     backgroundColor: ThemeColor.expense,
                      //     valueColor: const AlwaysStoppedAnimation<Color>(ThemeColor.income),
                      //     minHeight: 6.0,
                      //     borderRadius: const BorderRadius.all(Radius.circular(4)),
                      //   ),
                      // ),

                    Column(crossAxisAlignment: CrossAxisAlignment.center, mainAxisAlignment: MainAxisAlignment.center, children: [

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
                            fontSize: ThemeFont.headlineMedium,
                            color: balance < 0 ? ThemeColor.danger : ThemeColor.income
                            // fontWeight: FontWeight.bold
                          ),
                        )
                        ),


                      Container(
                        width: 200,
                        padding: const EdgeInsets.symmetric(vertical: 5),
                        child: LinearProgressIndicator(
                          value: total == 0 ? 0 : incomeRatio,
                          backgroundColor: ThemeColor.expense,
                          valueColor: const AlwaysStoppedAnimation<Color>(ThemeColor.income),
                          minHeight: 6.0,
                          borderRadius: const BorderRadius.all(Radius.circular(4)),
                        ),
                      ),

                        Text(Helper.currencyFormatter(expenseTotal, '-'), style: const TextStyle(fontSize: 16, color: ThemeColor.textSecondary, fontWeight: FontWeight.bold )),
                        const Text('This Month', style: TextStyle(fontSize: ThemeFont.bodySmall, color: ThemeColor.textSecondary, ))

                    ],),

                    const SizedBox(
                      height: 16,
                    ),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16), 
                      child: Row(
                        children: [
                          ...categories.map((cat) {
                            final catId = cat.key as int;
                            
                            // 1. Capture the present date metadata components
                            final now = DateTime.now();
                            final currentYear = now.year;
                            final currentMonth = now.month;

                            final incomeForCat = transactions
                                .where((tx) => tx.isNewIncome && tx.categoryId == catId)
                                .fold<double>(0, (sum, tx) => sum + tx.amount);

                            // 2. CRUCIAL UPDATE: Filter expenses to ONLY get items from the present month
                            final expenseForCat = transactions
                                .where((tx) => 
                                    !tx.isNewIncome && 
                                    tx.categoryId == catId &&
                                    tx.createdAt.year == currentYear && // Checks matching year
                                    tx.createdAt.month == currentMonth, // Checks matching month
                                )
                                .fold<double>(0, (sum, tx) => sum + tx.amount);

                            final balanceForCat = incomeForCat - expenseForCat;
                            final double totalIncome = balanceForCat + expenseForCat;

                            return CategorySummaryItem(
                              title: cat.name, 
                              subtitle: totalIncome, 
                              expense: expenseForCat, 
                              balance: balanceForCat,
                            );
                          }),
                        ],
                      ),
                    ),

                    // CategorySummaryItem(
                    //   title: 'Summary', 
                    //   subtitle: balance + expenseTotal, 
                    //   expense: expenseTotal, 
                    //   balance: balance
                    // ),

                    const SizedBox(
                      height: 40,
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
                            SelectMonth(
                              value: _selectedMonth, 
                              onChanged: (v) => setState(() => _selectedMonth = v!)
                            ),
                            const SizedBox(width: 12),
                            SelectYear(
                              value: _selectedYear, 
                              onChanged: (v) => setState(() => _selectedYear = v!)
                            )
                          ],)
                         ],
                       ),
                     ),
                     
                    _buildDailyExpenseChart(transactions),
                    _buildMonthlyExpenseChart(transactions),

                    const RecentTransactionTitle(),
                    
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
                    else const NoRecentTransactions(),

                    NotesTitle(onPressed: _showNotesDialog),
                    Notes(text: _notesController.text.isEmpty ? 'No notes' : _notesController.text),

                    const SizedBox(
                      height: 160,
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

  ({double total, double needs, double wants, double save, int count})
      _expenseBreakdown(List<TransactionModel> expenses) {
    double total = 0, needs = 0, wants = 0, save = 0;
    for (final tx in expenses) {
      total += tx.amount;
      final name = _categoryName(tx);
      if (name == 'needs') {
        needs += tx.amount;
      } else if (name == 'wants') {
        wants += tx.amount;
      } else if (name == 'save') {
        save += tx.amount;
      }
    }
    return (total: total, needs: needs, wants: wants, save: save, count: expenses.length);
  }

  String? _categoryName(TransactionModel tx) {
    final catBox = Hive.box<Category>('categories');
    return catBox.get(tx.categoryId)?.name.toLowerCase();
  }

  Widget _buildDailyExpenseChart(List<TransactionModel> transactions) {
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

    final maxDailyTotal = List.generate(daysInMonth, (i) {
      final total = dailyNeeds[i] + dailyWants[i] + dailySavings[i];
      return _showIncomeInGraph ? dailyIncome[i] + total : total;
    }).reduce(max);
    final maxValue = maxDailyTotal;

    return Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text(DateFormat('MMM y').format(DateTime(_selectedYear, _selectedMonth)).toUpperCase(),
                      style:
                          const TextStyle(fontWeight: FontWeight.bold, color: ThemeColor.textSecondary)),
              const SizedBox(width: 8),
              Text(Helper.currencyFormatter(totalNeeds + totalWants + totalSavings, '-'), style: TextStyle(color: ThemeColor.textTertiary),)
            ],),

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
                        : (income / maxValue) * 135;
                    final needsHeight = maxValue == 0
                        ? 0.0
                        : (needs / maxValue) * 135;
                    final wantsHeight = maxValue == 0
                        ? 0.0
                        : (wants / maxValue) * 135;
                    final savingsHeight = maxValue == 0
                        ? 0.0
                        : (savings / maxValue) * 135;
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
                                    GraphColumnItem(
                                      height: incomeHeight,
                                      color: ThemeColor.income, 
                                      borderRadius: BorderRadius.vertical(
                                        top: const Radius.circular(2),
                                        bottom: Radius.circular(savingsHeight > 0 || wantsHeight > 0 || needsHeight > 0 ? 0 : 2)
                                      ) 
                                    ),
                                  GraphColumnItem(
                                    height: savingsHeight,
                                    color: ThemeColor.textTertiary, 
                                    borderRadius: BorderRadius.vertical(top: Radius.circular(_showIncomeInGraph && savingsHeight > 0 ? 0 : 2), bottom: Radius.circular(needsHeight > 0 || wantsHeight > 0 ? 0 : 2))
                                  ),
                                  GraphColumnItem(
                                    height: wantsHeight,
                                    color: ThemeColor.textSecondary, 
                                    borderRadius: BorderRadius.vertical(top: Radius.circular((_showIncomeInGraph && incomeHeight > 0) || savingsHeight > 0 ? 0 : 2), bottom: Radius.circular(needsHeight > 0 ? 0 : 2)),
                                  ),
                                  GraphColumnItem(
                                    height: needsHeight,
                                    color: ThemeColor.textPrimary, 
                                    borderRadius: BorderRadius.vertical(bottom: const Radius.circular(2), top: Radius.circular((_showIncomeInGraph && incomeHeight > 0) || wantsHeight > 0 || savingsHeight > 0 ? 0 : 2))
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

    final maxMonthlyTotal = List.generate(12, (i) {
      final total = monthlyNeeds[i] + monthlyWants[i] + monthlySavings[i];
      return _showIncomeInGraph ? monthlyIncome[i] + total : total;
    }).reduce(max);
    final maxValue = maxMonthlyTotal;

    return Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Center(child:
              
            // ),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text('YEAR $_selectedYear',
                    style:
                        const TextStyle(fontWeight: FontWeight.bold, color: ThemeColor.textSecondary)),
              const SizedBox(width: 8),
              Text(Helper.currencyFormatter(totalNeeds + totalWants + totalSavings, '-'), style: TextStyle(color: ThemeColor.textTertiary),)
            ],),

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
                      : (income / maxValue) * 135;
                  final needsHeight = maxValue == 0
                      ? 0.0
                      : (needs / maxValue) * 135;
                  final wantsHeight = maxValue == 0
                      ? 0.0
                      : (wants / maxValue) * 135;
                  final savingsHeight = maxValue == 0
                      ? 0.0
                      : (savings / maxValue) * 135;
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
                                  GraphColumnItem(
                                    height: incomeHeight,
                                    color: ThemeColor.income, 
                                    borderRadius: BorderRadius.vertical(
                                      top: const Radius.circular(2), 
                                      bottom: Radius.circular(savingsHeight > 0 || wantsHeight > 0 || needsHeight > 0 ? 0 : 2)
                                    )
                                  ),
                                GraphColumnItem(
                                  height: savingsHeight,
                                  color: ThemeColor.textTertiary, 
                                  borderRadius: BorderRadius.vertical(top: Radius.circular(_showIncomeInGraph && incomeHeight > 0 ? 0 : 2), bottom: Radius.circular(needsHeight > 0 || wantsHeight > 0 ? 0 : 2))
                                ),
                                GraphColumnItem(
                                  height: wantsHeight,
                                  color: ThemeColor.textSecondary, 
                                  borderRadius: BorderRadius.vertical(top: Radius.circular((_showIncomeInGraph && incomeHeight > 0) || savingsHeight > 0 ? 0 : 2), bottom: Radius.circular(needsHeight > 0 ? 0 : 2)),
                                ),
                                GraphColumnItem(
                                  height: needsHeight,
                                  color: ThemeColor.textPrimary, 
                                  borderRadius: BorderRadius.vertical(bottom: const Radius.circular(2), top: Radius.circular((_showIncomeInGraph && incomeHeight > 0) || wantsHeight > 0 || savingsHeight > 0 ? 0 : 2))
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
