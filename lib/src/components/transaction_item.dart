import 'package:flutter/material.dart';
import 'package:moneyrule/src/helpers/helper.dart';

class TransactionItem extends StatelessWidget {
  final String title;
  final String? subtitle;
  final bool isNewIncome;
  final double amount;
  final void Function(String item)? onTap;
  final VoidCallback? onLongPress;

  const TransactionItem({
    super.key,
    required this.title,
    required this.amount,
    this.subtitle,
    this.isNewIncome = false,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(title),
      subtitle: Text(
        '${isNewIncome ? 'Income' : 'Expense'} • ${subtitle ?? 'Unknown'}',
        style: const TextStyle(color: Colors.grey, fontSize: 12),
      ),
      trailing: Text(
        Helper.currencyFormatter(amount),
        style: TextStyle(
          color: isNewIncome ? Colors.green : Colors.orange,
          fontWeight: FontWeight.bold,
        ),
      ),
      onLongPress: onLongPress,
    );
  }
}
