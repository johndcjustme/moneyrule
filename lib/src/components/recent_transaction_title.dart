import 'package:flutter/material.dart';
import 'package:moneyrule/src/utils/theme_front.dart';

class RecentTransactionTitle  extends StatelessWidget {
  const RecentTransactionTitle({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16, top: 32), 
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'RECENT',
            style: TextStyle(
              fontSize: ThemeFont.titleMedium,
              fontWeight: FontWeight.bold
            ),
          ),
          IconButton(
            onPressed: () {
              Navigator.pushNamed(context, '/transactions');
            },
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      )
    );
  }
} 