import 'package:shared_preferences/shared_preferences.dart';

class UserPrefsService {
  static const String _displayNameKey = 'user_display_name';

  static Future<String> getDisplayName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_displayNameKey)?.trim() ?? '';
  }

  static Future<void> saveDisplayName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    final cleaned = name.trim();
    if (cleaned.isEmpty) {
      await prefs.remove(_displayNameKey);
    } else {
      await prefs.setString(_displayNameKey, cleaned);
    }
  }
  static String getTimeGreeting() {
  final hour = DateTime.now().hour;
  return switch (hour) {
    >= 5 && < 12 => 'Chào buổi sáng',
    >= 12 && < 18 => 'Chào buổi chiều',
    _ => 'Chào buổi tối',
  };
}

  static String buildGreeting(String displayName) {
    final hour = DateTime.now().hour;
    final prefix = switch (hour) {
      >= 5 && < 12 => 'Chào buổi sáng',
      >= 12 && < 18 => 'Chào buổi chiều',
      _ => 'Chào buổi tối',
    };
    final cleaned = displayName.trim();
    return cleaned.isEmpty ? '$prefix!' : '$prefix, $cleaned!';
  }
}