import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

part 'user.g.dart';

@HiveType(typeId: 2)
class User extends HiveObject {
  @HiveField(0)
  String name;

  @HiveField(1)
  String password;

  @HiveField(2)
  bool isLogin;

  User({
    required this.name,
    required this.password,
    this.isLogin = false, // default to logged out
  });

  static void updateData(BuildContext context, user, updatedName, updatedPassword) {
     if (user != null) {
      user!.name = updatedName;
      user!.password = updatedPassword;
      user!.save();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Account updated successfully')),
      );
    }
  }
}
