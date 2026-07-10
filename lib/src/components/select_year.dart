import 'package:flutter/material.dart';

class SelectYear extends StatelessWidget {
  final int? value;
  final ValueChanged<int?>? onChanged;

  const SelectYear({
    super.key,
    this.value,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return  DropdownButton<int>(
      value: value,
      underline: const SizedBox(),
      items: List.generate(10, (i) => DateTime.now().year - 5 + i)
          .map((y) => DropdownMenuItem(
                value: y,
                child: Text(y.toString()),
              ))
          .toList(),
      onChanged: onChanged,
    );
  }
}