import 'package:flutter/material.dart';
import 'package:moneyrule/src/helpers/helper.dart';
import 'package:moneyrule/src/utils/theme_color.dart';
import 'package:moneyrule/src/utils/theme_front.dart';

class CardExpenses extends StatelessWidget {
  final String title;
  final double total;
  final double needs;
  final double wants;
  final double save;
  final int transactions;

  const CardExpenses({
    super.key, 
    required this.title,
    required this.total,
    required this.needs,
    required this.wants,
    required this.save,
    required this.transactions,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(child: Card(color: ThemeColor.background, 
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: const BorderSide(color: Color.fromARGB(172, 39, 39, 39), width: 1)), 
    child: Padding(padding: const EdgeInsets.all(16),child: 
    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(title.toUpperCase(), style: const TextStyle(fontSize: ThemeFont.bodySmall, fontWeight: FontWeight.bold, color: ThemeColor.textSecondary)),
        Text('$transactions TX', style: const TextStyle(fontSize: ThemeFont.bodySmall, color: ThemeColor.textSecondary)),
      ],),
      const SizedBox(height: 4),
      Text(Helper.currencyFormatter(total, '-'), style: const TextStyle(fontWeight: FontWeight.bold)),

      const SizedBox(height: 14),

      Row(crossAxisAlignment: CrossAxisAlignment.center, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(Helper.currencyFormatter(needs, '-'), style: const TextStyle(color: ThemeColor.textSecondary, fontSize: ThemeFont.bodySmall)),
        const Text('N', style: TextStyle(color: ThemeColor.textTertiary, fontSize: ThemeFont.bodySmall)),
      ],),
      Row(crossAxisAlignment: CrossAxisAlignment.center, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(Helper.currencyFormatter(wants, '-'), style: const TextStyle(color: ThemeColor.textSecondary, fontSize: ThemeFont.bodySmall)),
        const Text('W', style: TextStyle(color: ThemeColor.textTertiary, fontSize: ThemeFont.bodySmall)),
      ],),
      Row(crossAxisAlignment: CrossAxisAlignment.center, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(Helper.currencyFormatter(save, '-'), style: const TextStyle(color: ThemeColor.textSecondary, fontSize: ThemeFont.bodySmall)),
        const Text('S', style: TextStyle(color: ThemeColor.textTertiary, fontSize: ThemeFont.bodySmall)),
      ],),
    ],))));
  }
}