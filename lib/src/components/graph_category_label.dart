import 'package:flutter/material.dart';
import 'package:moneyrule/src/utils/theme_color.dart';
import 'package:moneyrule/src/utils/theme_front.dart';

class GraphCategoryLabel extends StatelessWidget {
  
  final String value;
  final String title;
  final Color? color;

  const GraphCategoryLabel({
    super.key,
    required this.title,
    required this.value,
    this.color = ThemeColor.textTertiary,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
              Text(title,
                  style: const TextStyle(
                      color: ThemeColor.textTertiary,
                      fontSize: ThemeFont.bodySmall)),
              Text(value,
                  style: TextStyle(
                      color: color,
                      fontSize: ThemeFont.bodyMedium)),
        ],);
  }
}