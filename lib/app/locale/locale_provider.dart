import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleProvider extends ChangeNotifier {
  Locale _locale = const Locale('ko'); // 기본값

  Locale get locale => _locale;

  LocaleProvider() {
    _loadLocaleFromPrefs();
  }

  void setLocale(Locale locale) {
    _locale = locale;
    _saveLocaleToPrefs();
    notifyListeners();
  }

  Future<void> _loadLocaleFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString('localeCode');
    if (code != null) {
      _locale = Locale(code);
      notifyListeners();
    }
  }

  Future<void> _saveLocaleToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('localeCode', _locale.languageCode);
  }
}
