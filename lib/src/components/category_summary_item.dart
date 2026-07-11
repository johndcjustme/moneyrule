import 'package:flutter/material.dart';
import 'package:moneyrule/src/helpers/helper.dart';
import 'package:moneyrule/src/utils/theme_color.dart';
import 'package:moneyrule/src/utils/theme_front.dart';
import 'package:pie_chart/pie_chart.dart';

class CategorySummaryItem extends StatelessWidget {
  
  final String title;
  final double subtitle;
  final double expense;
  final double balance;

  const CategorySummaryItem({
    super.key,
    required this.title,
    required this.subtitle,
    required this.expense,
    required this.balance,
  });

  @override
  Widget build(BuildContext context) {

    return Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
         PieChart(
          dataMap: {
            "Remaining":
                balance < 0 ? 0 : balance,
            "Expenses": expense,
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

        Padding(padding: const EdgeInsets.symmetric(vertical: 6),child: Text(title.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: ThemeFont.bodySmall)),),
       
        
         Text(
            Helper.currencyFormatter(expense, '-'),
            style: const TextStyle(
              color: ThemeColor.textSecondary,
              fontSize: ThemeFont.bodySmall,
              height: 1.2,
            ),
          ),
          Text(
            Helper.currencyFormatter(balance, balance >= 0 ? '+' : ''),
            style: TextStyle(
              color: balance < 0
                  ? ThemeColor.danger
                  : ThemeColor.income,
              fontSize: ThemeFont.bodySmall,
              height: 1.2,
            ),
          ),
      ],));
    // return ListTile(
    //           trailing: SizedBox(
    //             width: 175, // ⬅️ Increased width for better layout
    //             child: Row(
    //               mainAxisAlignment: MainAxisAlignment.end,
    //               crossAxisAlignment: CrossAxisAlignment.center,
    //               children: [
    //                 Expanded(
    //                   child: Column(
    //                     crossAxisAlignment: CrossAxisAlignment.end,
    //                     mainAxisAlignment: MainAxisAlignment.center,
    //                     children: [
    //                       Text(
    //                         Helper.currencyFormatter(expense, '-'),
    //                         style: const TextStyle(
    //                           color: ThemeColor.textSecondary,
    //                           fontSize: ThemeFont.bodySmall,
    //                           height: 1.2,
    //                         ),
    //                       ),
    //                       Text(
    //                         Helper.currencyFormatter(balance, balance >= 0 ? '+' : ''),
    //                         style: TextStyle(
    //                           color: balance < 0
    //                               ? ThemeColor.danger
    //                               : ThemeColor.income,
    //                           fontSize: ThemeFont.bodySmall,
    //                           height: 1.2,
    //                         ),
    //                       ),
    //                     ],
    //                   ),
    //                 ),
    //                 const SizedBox(
    //                     width:
    //                         8), // ⬅️ spacing between text and chart
    //                 PieChart(
    //                   dataMap: {
    //                     "Remaining":
    //                         balance < 0 ? 0 : balance,
    //                     "Expenses": expense,
    //                   },
    //                   colorList: const [
    //                     ThemeColor.income,
    //                     ThemeColor.expense
    //                   ],
    //                   chartType: ChartType.ring,
    //                   chartRadius: 30,
    //                   ringStrokeWidth: 4,
    //                   legendOptions:
    //                       const LegendOptions(showLegends: false),
    //                   chartValuesOptions: const ChartValuesOptions(
    //                       showChartValues: false),
    //                 ),
    //               ],
    //             ),
    //           ),
    //           title: Text(title, style: const TextStyle(fontSize: ThemeFont.bodyMedium, fontWeight: FontWeight.bold)),
    //           // subtitle: Text(
    //           //     Helper.currencyFormatter(subtitle),
    //           //     style: const TextStyle(
    //           //         color: ThemeColor.textSecondary, fontSize: ThemeFont.bodySmall))
    //         );
  }
}