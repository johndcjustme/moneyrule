import 'package:flutter/material.dart';
import 'package:moneyrule/src/helpers/helper.dart';
import 'package:moneyrule/src/utils/theme_color.dart';

class TransactionItem extends StatelessWidget {
  final String title;
  final String? subtitle;
  final bool isNewIncome;
  final double amount;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onDelete;

  const TransactionItem({
    super.key,
    required this.title,
    required this.amount,
    this.subtitle,
    this.isNewIncome = false,
    this.onTap,
    this.onLongPress,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final tile = ListTile(
      title: Text(title, style: const TextStyle(color: ThemeColor.textPrimary),),
      // subtitle: Text(
      //   '${isNewIncome ? 'Income' : 'Expense'} • ${subtitle ?? 'Unknown'}',
      //   style: const TextStyle(color: Colors.grey, fontSize: 12),
      // ),
       subtitle: Text(
        subtitle ?? 'Unknown',
        style: const TextStyle(color: ThemeColor.textSecondary, fontSize: 12),
      ),
      trailing: Text(
        Helper.currencyFormatter(amount, isNewIncome ? '+' : '-'),
        style: TextStyle(
          color: isNewIncome ? ThemeColor.income : ThemeColor.textSecondary,
          // fontWeight: FontWeight.bold,
          fontSize: 14
        ),
      ),
      onLongPress: onLongPress,
      onTap: onTap,
    );

    if (onDelete == null) return tile;

    return Dismissible(
      key: key ?? ValueKey('$title-${amount.toString()}-${subtitle ?? ''}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        color: Colors.red,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        final confirm = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete Transaction'),
            content: const Text(
                'Are you sure you want to delete this transaction?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Delete', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        );
        return confirm ?? false;
      },
      onDismissed: (_) => onDelete!(),
      child: tile,
    );
  }
}
