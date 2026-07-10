import 'package:hive_flutter/hive_flutter.dart';
import 'package:moneyrule/src/models/user.dart';

class NotesService {
  Future<User?> saveNotes(String noteText) async {
    final userBox = Hive.box<User>('users');
    User? currentUser;
    
    try {
      currentUser = userBox.values.firstWhere((user) => user.isLogin == true);
    } catch (e) {
      currentUser = null;
    }
    
    if (currentUser != null) {
      currentUser.notes = noteText;
      await currentUser.save();
      return currentUser;
    }

    return null;
  }
}