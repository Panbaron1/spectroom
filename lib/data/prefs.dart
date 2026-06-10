import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Tiny key/value flags. On-device only.
class Prefs {
  static const _kSeen = 'onboarding_seen_v1';
  static const _kLang = 'lang_v1';
  static const _kKidVocative = 'kid_vocative_v1';
  static const _kLastDonePrefix = 'last_done_';

  /// Fires whenever any challenge's last-done time is updated.
  static final lastDoneNotifier = ValueNotifier<int>(0);

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

  static Future<String> kidVocative() async {
    final p = await SharedPreferences.getInstance();
    return p.getString(_kKidVocative) ?? '';
  }

  static Future<void> setKidVocative(String v) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_kKidVocative, v);
  }

  static Future<DateTime?> lastDone(String id) async {
    final p = await SharedPreferences.getInstance();
    final s = p.getString('$_kLastDonePrefix$id');
    return s == null ? null : DateTime.tryParse(s);
  }

  static Future<void> setLastDone(String id) async {
    final p = await SharedPreferences.getInstance();
    await p.setString('$_kLastDonePrefix$id', DateTime.now().toIso8601String());
    lastDoneNotifier.value++;
  }

  static const _kTimerSec = 'standalone_timer_sec_v1';
  static const _kCountdownN = 'standalone_countdown_n_v1';

  static Future<int> standaloneTimerSec() async {
    final p = await SharedPreferences.getInstance();
    return p.getInt(_kTimerSec) ?? 300;
  }

  static Future<void> setStandaloneTimerSec(int s) async {
    final p = await SharedPreferences.getInstance();
    await p.setInt(_kTimerSec, s);
  }

  static Future<int> standaloneCountdownN() async {
    final p = await SharedPreferences.getInstance();
    return p.getInt(_kCountdownN) ?? 10;
  }

  static Future<void> setStandaloneCountdownN(int n) async {
    final p = await SharedPreferences.getInstance();
    await p.setInt(_kCountdownN, n);
  }
}
