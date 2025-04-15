import 'package:flutter/material.dart';

class BudgetRuleInfo extends StatelessWidget {
  const BudgetRuleInfo({super.key});

  Color withShade() {
    return Colors.grey.shade700;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 30),
        Text(
          'The 50/30/20 rule is a popular and simple budgeting method to help manage your money effectively. It breaks your after-tax income into three categories:',
          style: TextStyle(fontSize: 16, color: withShade()),
        ),
        const SizedBox(height: 20),

        Text(
          '💸 50% — Needs',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue.shade700),
        ),
        const SizedBox(height: 8),
        Text('These are essentials you must pay for to live and work, like:', style: TextStyle(color: withShade())),
        const SizedBox(height: 4),
        BulletList(items: const [
          'Rent or mortgage',
          'Utilities',
          'Groceries',
          'Transportation (gas, transit, etc.)',
          'Insurance',
          'Minimum debt payments',
        ], color: withShade()),
        const SizedBox(height: 4),
        Text('✅ Aim to keep all "needs" within 50% of your take-home pay.', style: TextStyle(color: withShade())),
        const SizedBox(height: 20),

        Text(
          '🎉 30% — Wants',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.orange.shade700),
        ),
        const SizedBox(height: 8),
        Text('These are non-essential expenses — things you enjoy but can live without:', style: TextStyle(color: withShade())),
        const SizedBox(height: 4),
        BulletList(items: const [
          'Dining out',
          'Subscriptions (Netflix, Spotify)',
          'Travel and vacations',
          'Hobbies and entertainment',
          'Shopping (clothes, gadgets)',
        ], color: withShade()),
        const SizedBox(height: 4),
        Text('✅ This is your “fun” money — just don’t let it eat into the other categories.', style: TextStyle(color: withShade())),
        const SizedBox(height: 20),

        Text(
          '💰 20% — Savings & Debt Repayment',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green.shade700),
        ),
        const SizedBox(height: 8),
        Text('This portion goes toward building your future and financial security:', style: TextStyle(color: withShade())),
        const SizedBox(height: 4),
        BulletList(items: const [
          'Emergency fund',
          'Investments',
          'Retirement savings (401k, IRA, etc.)',
          'Extra debt payments (on top of the minimum)',
        ], color: withShade()),
        const SizedBox(height: 4),
        Text('✅ The goal here is long-term financial growth and debt freedom', style: TextStyle(color: withShade())),
        const SizedBox(height: 20),
      ],
    );
  }
}

class BulletList extends StatelessWidget {
  final List<String> items;
  final Color color;

  const BulletList({super.key, required this.items, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items.map(
        (item) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('• ', style: TextStyle(fontSize: 16)),
              Expanded(child: Text(item, style: TextStyle(color: color))),
            ],
          ),
        ),
      ).toList(),
    );
  }
}
