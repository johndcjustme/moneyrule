import 'dart:math';

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

  @HiveField(3)
  String? notes;

  @HiveField(4)
  String? id;

  @HiveField(5)
  String? type;

  User({
    required this.name,
    required this.password,
    this.isLogin = false, // default to logged out
    this.notes,
    this.id,
    this.type,
  });

  static String generateId() {
    final random = Random();
    final timestamp = DateTime.now().microsecondsSinceEpoch;
    final randomPart = random.nextInt(0x7fffffff).toRadixString(16).padLeft(8, '0');
    return '$timestamp$randomPart';
  }

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

  static void updateNotes(BuildContext context, user, updatedNotes) {
    if (user != null) {
      user!.notes = updatedNotes;
      user!.save();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Notes saved successfully')),
      );
    }
  }
}
