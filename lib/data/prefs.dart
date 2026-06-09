import 'package:shared_preferences/shared_preferences.dart';

/// Tiny key/value flags. On-device only.
class Prefs {
  static const _kSeen = 'onboarding_seen_v1';
  static const _kLang = 'lang_v1';

  static Future<bool> seenOnboarding() async {
    final p = await SharedPreferences.getInstance();
    return p.getBool(_kSeen) ?? false;
  }

  static Future<void> setSeen() async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_kSeen, true);
  }

  static Future<String> lang() async {
    final p = await SharedPreferences.getInstance();
    return p.getString(_kLang) ?? 'cs';
  }

  static Future<void> setLang(String l) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_kLang, l);
  }

  static const _kKidName = 'kid_name_v1';

  static Future<String> kidName() async {
    final p = await SharedPreferences.getInstance();
    return p.getString(_kKidName) ?? '';
  }

  static Future<void> setKidName(String name) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_kKidName, name.trim());
  }
}
