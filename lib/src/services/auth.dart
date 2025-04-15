import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/user.dart';

class Auth {
  static Future<void> login(
    BuildContext context,
    String name,
    String password,
  ) async {
    final userBox = Hive.box<User>('users');
    User? user;

    try {
      user = userBox.values.firstWhere(
        (user) => user.name == name && user.password == password,
      );
    } catch (e) {
      user = null;
    }

    if (user != null) {
      user.isLogin = true;
      await user.save();
      
      if (!context.mounted) return;
      await isLoggedIn(context);
    } else {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid username or password')),
      );
    }
  }

  static Future<void> isLoggedIn(BuildContext context) async {
    final userBox = Hive.box<User>('users');

    var isLoggedIn = userBox.values.any((user) => user.isLogin == true);

    if (isLoggedIn) {
      Future.microtask(() {
        if (!context.mounted) return;
        Navigator.pushReplacementNamed(context, '/dashboard');
      });
    }
  }

  static Future<void> logout(BuildContext context) async {
    final userBox = Hive.box<User>('users');

    User? currentUser;

    try {
      currentUser = userBox.values.firstWhere((user) => user.isLogin == true);
    } catch (e) {
      currentUser = null;
    }

    if (currentUser != null) {
      currentUser.isLogin = false;
      await currentUser.save();
    }

    if (!context.mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
  }
}
