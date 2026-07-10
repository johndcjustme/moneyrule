import 'package:flutter/material.dart';
import 'package:moneyrule/src/utils/theme_front.dart';

class NotesTitle extends StatelessWidget {
  final VoidCallback? onPressed;

  const NotesTitle({super.key, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 48, left: 16, right: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('NOTES', style: TextStyle(fontSize: ThemeFont.titleMedium, fontWeight: FontWeight.bold)),
          IconButton(
            onPressed: onPressed,
            icon: const Icon(Icons.edit, size: 18),
          ),
        ],
      ),
    );
  }
}