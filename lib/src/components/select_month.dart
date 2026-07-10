import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class SelectMonth extends StatelessWidget {
  final int? value;
  final ValueChanged<int?>? onChanged;

  const SelectMonth({
    super.key,
    this.value,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButton<int>(
      value: value,
      underline: const SizedBox(),
      items: List.generate(12, (i) => i + 1)
          .map((m) => DropdownMenuItem(
                value: m,
                child: Text(DateFormat('MMM').format(DateTime(2024, m)).toUpperCase()),
              ))
          .toList(),
      onChanged: onChanged,
    );
  }
}