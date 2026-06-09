import 'package:flutter/foundation.dart';
import 'prefs.dart';

/// Holds the user's chosen language ('cs' or 'en').
/// Screens listen via AnimatedBuilder / Listenable.merge.
class LangStore extends ChangeNotifier {
  static final instance = LangStore._();
  LangStore._();

  String _lang = 'cs';
  String get lang => _lang;

  Future<void> load() async {
    _lang = await Prefs.lang();
  }

  Future<void> setLang(String l) async {
    if (_lang == l) return;
    _lang = l;
    await Prefs.setLang(l);
    notifyListeners();
  }
}
