import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Light or dark mode, remembered between launches. Until the user picks,
/// it follows the Windows setting.
class ThemeController extends ChangeNotifier {
  ThemeController([this._mode = ThemeMode.system]);

  static const _key = 'themeMode';

  ThemeMode _mode;
  ThemeMode get mode => _mode;

  static Future<ThemeController> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_key);
      return ThemeController(
        ThemeMode.values.firstWhere(
          (m) => m.name == saved,
          orElse: () => ThemeMode.system,
        ),
      );
    } catch (_) {
      return ThemeController();
    }
  }

  bool isDark(BuildContext context) => switch (_mode) {
    ThemeMode.dark => true,
    ThemeMode.light => false,
    ThemeMode.system =>
      MediaQuery.platformBrightnessOf(context) == Brightness.dark,
  };

  void toggle(BuildContext context) {
    _mode = isDark(context) ? ThemeMode.light : ThemeMode.dark;
    notifyListeners();
    SharedPreferences.getInstance()
        .then((prefs) => prefs.setString(_key, _mode.name))
        .ignore();
  }
}
