import 'package:shared_preferences/shared_preferences.dart';

/// Tiny key/value flags. On-device only.
class Prefs {
  static const _kSeen = 'onboarding_seen_v1';

  static Future<bool> seenOnboarding() async {
    final p = await SharedPreferences.getInstance();
    return p.getBool(_kSeen) ?? false;
  }

  static Future<void> setSeen() async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_kSeen, true);
  }
}
