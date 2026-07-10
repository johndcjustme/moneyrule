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
      side: const BorderSide(color: ThemeColor.expense, width: 1)), 
    child: Padding(padding: const EdgeInsets.all(16),child: 
    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title.toUpperCase(), style: const TextStyle(fontSize: ThemeFont.bodySmall, fontWeight: FontWeight.bold, color: ThemeColor.textSecondary)),
          Text(Helper.currencyFormatter(total, '-'), style: const TextStyle(fontSize: ThemeFont.bodyLarge, fontWeight: FontWeight.bold)),
        ],),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text('$transactions TX', style: const TextStyle(fontSize: ThemeFont.bodySmall)),
          // Text('Trnsctns', style: TextStyle(fontSize: ThemeFont.bodySmall))
        ],)
      ],),

      const SizedBox(height: 16),

      // Row(children: [
      //   Expanded(child: Column(children: [
      //     Text('N', style: TextStyle(color: ThemeColor.textTertiary, fontSize: ThemeFont.bodySmall)),
      //     Text('-50,500.00', style: TextStyle(color: ThemeColor.textSecondary, fontSize: ThemeFont.bodySmall))
      //   ],)),
      //   SizedBox(width: 5),
      //     Expanded(child: Column(children: [
      //     Text('W', style: TextStyle(color: ThemeColor.textTertiary, fontSize: ThemeFont.bodySmall)),
      //     Text('-500.00', style: TextStyle(color: ThemeColor.textSecondary, fontSize: ThemeFont.bodySmall))
      //   ],)),
      //   SizedBox(width: 5),
      //   Expanded(child: Column(children: [
      //     Text('S', style: TextStyle(color: ThemeColor.textTertiary, fontSize: ThemeFont.bodySmall)),
      //     Text('-500.00', style: TextStyle(color: ThemeColor.textSecondary, fontSize: ThemeFont.bodySmall))
      //   ],)),
      // ],),
      
      Row(crossAxisAlignment: CrossAxisAlignment.center, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(Helper.currencyFormatter(needs, '-'), style: const TextStyle(color: ThemeColor.textSecondary)),
        const Text('N', style: TextStyle(color: ThemeColor.textTertiary)),
      ],),
      Row(crossAxisAlignment: CrossAxisAlignment.center, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(Helper.currencyFormatter(wants, '-'), style: const TextStyle(color: ThemeColor.textSecondary)),
        const Text('W', style: TextStyle(color: ThemeColor.textTertiary)),
      ],),
      Row(crossAxisAlignment: CrossAxisAlignment.center, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(Helper.currencyFormatter(save, '-'), style: const TextStyle(color: ThemeColor.textSecondary)),
        const Text('S', style: TextStyle(color: ThemeColor.textTertiary)),
      ],),
    ],))));
  }
}