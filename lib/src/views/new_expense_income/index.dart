import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';

import 'package:hive_flutter/hive_flutter.dart';
import '../../models/category.dart';
import '../../models/transaction_model.dart';

// import '../models/category.dart';
// import '../models/transaction_model.dart';

class NewTransactionPage extends StatefulWidget {
  final bool isIncome;
  const NewTransactionPage({super.key, required this.isIncome});

  @override
  State<NewTransactionPage> createState() => _NewTransactionPageState();
}

class _NewTransactionPageState extends State<NewTransactionPage> {
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  Category? _selectedCategory;

  @override
  Widget build(BuildContext context) {
    final categoriesBox = Hive.box<Category>('categories');

    return Scaffold(
      appBar:
          AppBar(title: Text(widget.isIncome ? 'Add Income' : 'Add Expense')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Amount',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TypeAheadField<String>(
              textFieldConfiguration: TextFieldConfiguration(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
              ),
              suggestionsCallback: (pattern) async {
                if (pattern.isEmpty) {
                  return []; // Return empty list when search is empty
                }

                // Get all transactions from Hive
                final txBox = Hive.box<TransactionModel>('transactions');
                final allTransactions = txBox.values.toList();

                // Filter based on both income/expense type and description pattern
                final filteredDescriptions = allTransactions
                    .where((tx) =>
                        tx.isNewIncome ==
                            widget.isIncome && // Match income/expense type
                        tx.description
                            .toLowerCase()
                            .contains(pattern.toLowerCase()))
                    .map((tx) => tx.description)
                    .toSet() // Remove duplicates
                    .take(7) // Limit to 7 items
                    .toList();

                return filteredDescriptions; // Will return empty list if no matches
              },
              itemBuilder: (context, suggestion) {
                return ListTile(
                  title: Text(suggestion),
                );
              },
              onSuggestionSelected: (suggestion) {
                _descriptionController.text = suggestion;
              },
              noItemsFoundBuilder: (context) =>
                  const SizedBox.shrink(), // Show nothing when no results
            ),
            const SizedBox(height: 16),
            if (!widget.isIncome)
              ValueListenableBuilder(
                valueListenable: categoriesBox.listenable(),
                builder: (context, Box<Category> box, _) {
                  final categories = box.values.toList();

                  if (categories.isEmpty) {
                    return const Text('No categories available');
                  }

                  return Column(
                    children: categories.map((category) {
                      return RadioListTile<Category>(
                        title: Text(category.name),
                        value: category,
                        groupValue: _selectedCategory,
                        onChanged: (val) =>
                            setState(() => _selectedCategory = val),
                      );
                    }).toList(),
                  );
                },
              )
            else
              const SizedBox.shrink(), // Empty widget when isIncome is true
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () async {
                final amountText = _amountController.text.trim();
                final description = _descriptionController.text.trim();

                if (amountText.isEmpty ||
                    description.isEmpty ||
                    (!widget.isIncome && _selectedCategory == null)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Fill all fields')),
                  );
                  return;
                }

                final double? amount = double.tryParse(amountText);
                if (amount == null || amount <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Enter a valid amount')),
                  );
                  return;
                }

                final transactionBox =
                    Hive.box<TransactionModel>('transactions');
                final categoryBox = Hive.box<Category>('categories');

                if (widget.isIncome) {
                  // Split into categories
                  for (final category in categoryBox.values) {
                    final splitAmount = (category.percentage / 100) * amount;
                    final tx = TransactionModel(
                      categoryId: category.key as int,
                      amount: splitAmount,
                      description: description,
                      isNewIncome: true,
                      createdAt: DateTime.now(),
                    );
                    await transactionBox.add(tx);
                  }
                } else {
                  // Expense: just one category
                  final tx = TransactionModel(
                    categoryId: _selectedCategory!.key as int,
                    amount: amount,
                    description: description,
                    isNewIncome: false,
                    createdAt: DateTime.now(),
                  );
                  await transactionBox.add(tx);
                }

                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}
