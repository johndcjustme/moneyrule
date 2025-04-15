import 'package:hive/hive.dart';

part 'category.g.dart';

@HiveType(typeId: 0)
class Category extends HiveObject {
  @HiveField(0)
  String name;

  @HiveField(1)
  double percentage;

  @HiveField(2)
  double amount;

  Category({
    required this.name,
    required this.percentage,
    required this.amount,
  });
}
