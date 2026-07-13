import 'package:hive/hive.dart';

part 'transaction_model.g.dart';

@HiveType(typeId: 1)
class TransactionModel extends HiveObject {
  @HiveField(0)
  int categoryId;

  @HiveField(1)
  double amount;

  @HiveField(2)
  String description;

  @HiveField(3)
  bool isNewIncome;

  @HiveField(4)
  DateTime createdAt;

  @HiveField(5)
  String? userId;

  TransactionModel({
    required this.categoryId,
    required this.amount,
    required this.description,
    required this.isNewIncome,
    required this.createdAt,
    this.userId,
  });
}
