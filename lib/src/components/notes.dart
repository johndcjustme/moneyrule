import 'package:flutter/material.dart';
import 'package:moneyrule/src/utils/theme_color.dart';
import 'package:moneyrule/src/utils/theme_front.dart';

class Notes extends StatelessWidget {
  final String text;

  const Notes({
    super.key,
    required this.text
  });

  @override
  Widget build(BuildContext context) {
    return Padding(padding: const EdgeInsets.all(16), child: Text(
      text,
      style: const TextStyle(
        color: ThemeColor.textSecondary,
        fontSize: ThemeFont.bodyMedium,
      ),
    ));
  }
}