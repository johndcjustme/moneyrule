import 'package:flutter/material.dart';
import 'package:moneyrule/src/utils/theme_color.dart';

class NoRecentTransactions extends StatelessWidget {

  const NoRecentTransactions({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: 
      Padding(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16), 
        child: Text('No recent transactions', style: TextStyle(color: ThemeColor.textTertiary),)
      )
    );
  }
}