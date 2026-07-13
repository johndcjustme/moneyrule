import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../models/category.dart';
import '../../models/transaction_model.dart';
import '../../models/user.dart';

class AccountPage extends StatefulWidget {
  const AccountPage({super.key});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  final _nameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true; // Add this in your State

  User? _user;

  @override
  void initState() {
    super.initState();
    final userBox = Hive.box<User>('users');
    final currentUserId = User.currentUserId();
    try {
      _user = userBox.values.firstWhere((user) => user.id == currentUserId);
    } catch (e) {
      _user = userBox.getAt(0);
    }
    if (_user != null) {
      _nameController.text = _user!.name;
      _passwordController.text = _user!.password;
    }
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
          'This will permanently delete your account, categories, and transactions. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () async {
              final navigator = Navigator.of(context);
              final userBox = Hive.box<User>('users');
              final categoryBox = Hive.box<Category>('categories');
              final transactionBox = Hive.box<TransactionModel>('transactions');
              final userId = _user!.id;

              final ownedCategories =
                  categoryBox.values.where((c) => c.userId == userId).toList();
              for (final c in ownedCategories) {
                await c.delete();
              }

              final ownedTransactions = transactionBox.values
                  .where((t) => t.userId == userId)
                  .toList();
              for (final t in ownedTransactions) {
                await t.delete();
              }

              await _user!.delete();

              // Switch to the default user and log them in
              try {
                final defaultUser = userBox.values
                    .firstWhere((user) => user.type == 'default');
                defaultUser.isLogin = true;
                await defaultUser.save();
              } catch (e) {
                // No default user available; stay logged out
              }

              navigator.pop();
              navigator.pushReplacementNamed('/dashboard');
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDefault = _user?.type == 'default';

    return Scaffold(
      appBar: AppBar(title: const Text('Account Settings')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Username',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(
                labelText: 'Password',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),
              ),
              obscureText: _obscurePassword,
            ),
            const SizedBox(height: 24),
            if (_user != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('User ID: ${_user!.id ?? '-'}', style: const TextStyle(color: Colors.white70)),
                  const SizedBox(height: 4),
                  Text('Type: ${_user!.type ?? 'default'}', style: const TextStyle(color: Colors.white70)),
                  const SizedBox(height: 24),
                ],
              ),
            ElevatedButton(
              onPressed: () {
                User.updateData(context, _user, _nameController.text.trim(), _passwordController.text);
              },
              child: const Text('Save Changes'),
            ),
            if (!isDefault && _user != null) ...[
              const SizedBox(height: 24),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: _confirmDelete,
                child: const Text('Delete Account'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
