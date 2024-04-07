import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DarkProvider extends ChangeNotifier {
  bool _isDark;

  DarkProvider(this._isDark);

  bool get isDark => _isDark;

  set isDark(bool value) {
    _isDark = value;
    notifyListeners();

    SharedPreferences.getInstance().then((prefs) {
      prefs.setBool('isDark', value);
    });
  }

  void toggleDark() {
    _isDark = !_isDark;
    notifyListeners();

    SharedPreferences.getInstance().then((prefs) {
      prefs.setBool('isDark', _isDark);
    });
  }
}
