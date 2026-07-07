import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/category.dart';
import '../models/transaction_model.dart';

Future<void> showEditTransactionSheet(
    BuildContext context, TransactionModel tx) async {
  final amountController = TextEditingController(text: tx.amount.toString());
  final descriptionController = TextEditingController(text: tx.description);
  Category? selectedCategory;
  if (!tx.isNewIncome) {
    selectedCategory = Hive.box<Category>('categories').get(tx.categoryId);
  }

  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (ctx, setSheetState) {
          final categoriesBox = Hive.box<Category>('categories');

          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
              left: 16,
              right: 16,
              top: 16,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  tx.isNewIncome ? 'Edit Income' : 'Edit Expense',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Amount',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                if (!tx.isNewIncome)
                  ValueListenableBuilder(
                    valueListenable: categoriesBox.listenable(),
                    builder: (c, Box<Category> box, _) {
                      final categories = box.values.whereType<Category>().toList();
                      return DropdownButtonFormField<Category>(
                        value: selectedCategory,
                        items: categories.map((category) {
                          return DropdownMenuItem(
                            value: category,
                            child: Text(category.name),
                          );
                        }).toList(),
                        onChanged: (val) =>
                            setSheetState(() => selectedCategory = val),
                        decoration: const InputDecoration(
                          labelText: 'Category',
                          border: OutlineInputBorder(),
                        ),
                      );
                    },
                  ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    final amountText = amountController.text.trim();
                    final description = descriptionController.text.trim();

                    if (amountText.isEmpty ||
                        description.isEmpty ||
                        (!tx.isNewIncome && selectedCategory == null)) {
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        const SnackBar(content: Text('Fill all fields')),
                      );
                      return;
                    }

                    final double? amount = double.tryParse(amountText);
                    if (amount == null || amount <= 0) {
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        const SnackBar(content: Text('Enter a valid amount')),
                      );
                      return;
                    }

                    tx.amount = amount;
                    tx.description = description;
                    if (!tx.isNewIncome) {
                      tx.categoryId = selectedCategory!.key as int;
                    }
                    tx.save();

                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Transaction updated successfully')),
                    );
                  },
                  child: const Text('Save'),
                ),
                const SizedBox(height: 16),
              ],
            ),
          );
        },
      );
    },
  );
}
