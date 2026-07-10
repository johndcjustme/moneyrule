import 'package:flutter/material.dart';

class GraphColumnItem extends StatelessWidget {
  
  final double height;
  final Color color;
  final BorderRadiusGeometry? borderRadius;

  const GraphColumnItem({
    super.key,
    required this.height,
    required this.color,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
        width: 14,
        height: height,
        decoration: BoxDecoration(
          color: color,
          borderRadius: borderRadius,
        ),
      );
  }
}