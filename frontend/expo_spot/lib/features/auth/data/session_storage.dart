import 'package:shared_preferences/shared_preferences.dart';

abstract final class SessionKeys {
  static const userId = 'session_user_id';
  static const userName = 'session_user_name';
  static const userEmail = 'session_user_email';
}

class SessionStorage {
  Future<void> saveSession({
    required int userId,
    required String userName,
    required String userEmail,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(SessionKeys.userId, userId);
    await prefs.setString(SessionKeys.userName, userName);
    await prefs.setString(SessionKeys.userEmail, userEmail);
  }

  Future<int?> readUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(SessionKeys.userId);
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(SessionKeys.userId);
    await prefs.remove(SessionKeys.userName);
    await prefs.remove(SessionKeys.userEmail);
  }
}
