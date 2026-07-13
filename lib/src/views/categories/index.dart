import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../models/category.dart';
import '../../models/user.dart';

class CategoriesPage extends StatefulWidget {
  const CategoriesPage({super.key});

  @override
  State<CategoriesPage> createState() => _CategoriesPageState();
}

class _CategoryDraft {
  int? key;
  final TextEditingController nameController;
  final TextEditingController percentageController;
  double amount;

  _CategoryDraft({
    this.key,
    required String name,
    required double percentage,
    this.amount = 0,
  })  : nameController = TextEditingController(text: name),
        percentageController = TextEditingController(text: percentage.toString());

  void dispose() {
    nameController.dispose();
    percentageController.dispose();
  }
}

class _CategoriesPageState extends State<CategoriesPage> {
  final List<_CategoryDraft> _drafts = [];
  final _catBox = Hive.box<Category>('categories');

  @override
  void initState() {
    super.initState();
    final currentUserId = User.currentUserId();
    _drafts.addAll(
      _catBox.values
          .where((c) => c.userId == currentUserId)
          .map((c) => _CategoryDraft(
                key: c.key as int,
                name: c.name,
                percentage: c.percentage,
                amount: c.amount,
              )),
    );
  }

  @override
  void dispose() {
    for (final d in _drafts) {
      d.dispose();
    }
    super.dispose();
  }

  void _addCategory() {
    setState(() {
      _drafts.add(_CategoryDraft(name: '', percentage: 0));
    });
  }

  void _deleteDraft(int index) {
    final draft = _drafts.removeAt(index);
    draft.dispose();
    setState(() {});
  }

  Future<void> _save() async {
    final navigator = Navigator.of(context);
    final parsed = <_CategoryDraft, ({String name, double percentage, double amount})>{};
    var total = 0.0;
    var valid = true;

    for (final draft in _drafts) {
      final name = draft.nameController.text.trim();
      final percentage = double.tryParse(draft.percentageController.text.trim());
      if (name.isEmpty || percentage == null || percentage < 0) {
        valid = false;
        break;
      }
      total += percentage;
      parsed[draft] = (
        name: name,
        percentage: percentage,
        amount: draft.amount,
      );
    }

    if (!valid || (total - 100).abs() > 0.01) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Total percentage must equal 100% (currently ${total.toStringAsFixed(1)}%)',
          ),
        ),
      );
      return;
    }

    final currentUserId = User.currentUserId();

    // Delete categories that were removed from the list
    final keptKeys =
        parsed.keys.where((d) => d.key != null).map((d) => d.key).toSet();
    for (final category in _catBox.values.where((c) => c.userId == currentUserId)) {
      if (!keptKeys.contains(category.key)) {
        await category.delete();
      }
    }

    // Add or update the remaining categories
    for (final entry in parsed.entries) {
      final draft = entry.key;
      final value = entry.value;
      if (draft.key == null) {
        await _catBox.add(
          Category(
            name: value.name,
            percentage: value.percentage,
            amount: value.amount,
            userId: currentUserId,
          ),
        );
      } else {
        final category = _catBox.get(draft.key);
        if (category != null) {
          category.name = value.name;
          category.percentage = value.percentage;
          category.amount = value.amount;
          await category.save();
        }
      }
    }

    if (!mounted) return;
    navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Categories'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _save,
          ),
        ],
      ),
      body: _drafts.isEmpty
          ? const Center(
              child: Text(
                'No categories yet. Tap + to add one.',
                style: TextStyle(color: Colors.white70),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _drafts.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final draft = _drafts[index];
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: draft.nameController,
                            decoration: const InputDecoration(
                              labelText: 'Name',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        SizedBox(
                          width: 110,
                          child: TextField(
                            controller: draft.percentageController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: const InputDecoration(
                              labelText: 'Percent',
                              border: OutlineInputBorder(),
                              suffixText: '%',
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteDraft(index),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addCategory,
        child: const Icon(Icons.add),
      ),
    );
  }
}
