import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:moneyrule/src/utils/theme_color.dart';
import 'package:moneyrule/src/views/dashboard/index.dart';
import 'package:moneyrule/src/views/login/index.dart';
import 'package:moneyrule/src/views/new_expense_income/index.dart';
import 'package:moneyrule/src/views/partials/what.dart';

import 'src/models/category.dart';
import 'src/models/user.dart';
import 'src/models/transaction_model.dart';
import 'src/views/account/index.dart';
import 'src/views/transactions/index.dart';

import 'dart:developer' as developer;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();

  Hive.registerAdapter(CategoryAdapter());
  Hive.registerAdapter(TransactionModelAdapter());
  Hive.registerAdapter(UserAdapter());

  // await Hive.deleteBoxFromDisk('users');

  final userBox = await Hive.openBox<User>('users');
  final categoryBox = await Hive.openBox<Category>('categories');
  await Hive.openBox<TransactionModel>('transactions');
  await Hive.openBox('session');

  if (userBox.isEmpty) {
    await userBox.add(
      User(
        id: User.generateId(),
        name: 'admin',
        password: '1234',
        isLogin: true,
        type: 'default',
      ),
    );
  }

  // Migrate existing users: fill in id and type if missing
  for (final user in userBox.values) {
    var changed = false;
    if (user.id == null || user.id!.isEmpty) {
      user.id = User.generateId();
      changed = true;
    }
    if (user.type == null || user.type!.isEmpty) {
      user.type = 'default';
      changed = true;
    }
    if (changed) {
      await user.save();
    }
  }

  // Insert default categories if empty
  if (categoryBox.isEmpty) {
    final defaultUserId =
        userBox.values.where((user) => user.type == 'default').firstOrNull?.id ??
            userBox.values.firstOrNull?.id;
    await categoryBox.add(
      Category(name: 'Needs', percentage: 50, amount: 0, userId: defaultUserId),
    );
    await categoryBox.add(
      Category(name: 'Wants', percentage: 30, amount: 0, userId: defaultUserId),
    );
    await categoryBox.add(
      Category(name: 'Save', percentage: 20, amount: 0, userId: defaultUserId),
    );
  }

  // Migrate existing categories: fill in userId if missing
  for (final category in categoryBox.values) {
    if (category.userId == null || category.userId!.isEmpty) {
      final defaultUserId =
          userBox.values.where((user) => user.type == 'default').firstOrNull?.id ??
              userBox.values.firstOrNull?.id;
      category.userId = defaultUserId;
      await category.save();
    }
  }

  // Migrate existing transactions: fill in userId if missing
  final transactionBox = Hive.box<TransactionModel>('transactions');
  for (final tx in transactionBox.values) {
    if (tx.userId == null || tx.userId!.isEmpty) {
      final defaultUserId =
          userBox.values.where((user) => user.type == 'default').firstOrNull?.id ??
              userBox.values.firstOrNull?.id;
      tx.userId = defaultUserId;
      await tx.save();
    }
  }

  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SplitWise',
      initialRoute: '/',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        brightness: Brightness.light,
        scaffoldBackgroundColor: Colors.white,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: ThemeColor.background,
        appBarTheme: const AppBarTheme(
          backgroundColor: ThemeColor.background,
        ),
        inputDecorationTheme: const InputDecorationTheme(
          filled: true,
          fillColor: Colors.black12,
          border: OutlineInputBorder(),
          labelStyle: TextStyle(color: Colors.white70),
        ),
      ),
      routes: {
        '/': (_) => const LoginPage(),
        '/dashboard': (_) => const DashboardPage(),
        '/new-expense': (_) => const NewTransactionPage(isIncome: false),
        '/new-income': (_) => const NewTransactionPage(isIncome: true),
        '/transactions': (_) => const AllTransactionsPage(), // ✅ New route
        '/account': (_) => const AccountPage(), // ✅ New route
        '/budget-rule': (_) => const BudgetRuleInfo(),
      },
    );
  }
}
