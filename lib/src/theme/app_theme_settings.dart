import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../widgets/app_bottom_navigation.dart';

class AppThemeSettings extends ChangeNotifier {
  AppThemeSettings._();

  static final AppThemeSettings instance = AppThemeSettings._();

  static const _prefsKey = 'cocha_is_dark';

  var isDark = true;
  var _userOverride = false;

  void resetForTests({bool dark = true}) {
    _userOverride = false;
    isDark = dark;
    applyPalette();
  }

  void applyPalette() {
    if (isDark) {
      applyDarkAppPalette();
    } else {
      applyLightAppPalette();
    }
  }

  Future<void> load() async {
    var next = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_userOverride) return;
      next = prefs.getBool(_prefsKey) ?? true;
    } catch (_) {
      if (_userOverride) return;
      next = true;
    }
    if (isDark == next) {
      applyPalette();
      return;
    }
    isDark = next;
    applyPalette();
    notifyListeners();
  }

  Future<void> setDark(bool dark) async {
    _userOverride = true;
    if (isDark == dark) return;
    isDark = dark;
    applyPalette();
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefsKey, dark);
    } catch (_) {}
  }
}
