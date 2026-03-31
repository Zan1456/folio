import 'package:flutter/material.dart';
import 'package:folio/flavor.dart';
import 'package:shake_flutter/models/shake_theme.dart';
import 'package:shake_flutter/shake_flutter.dart';

class ThemeModeObserver extends ChangeNotifier {
  ThemeMode _themeMode;
  bool _updateNavbarColor;
  ThemeMode get themeMode => _themeMode;
  bool get updateNavbarColor => _updateNavbarColor;

  ThemeModeObserver(
      {ThemeMode initialTheme = ThemeMode.system,
      bool updateNavbarColor = true})
      : _themeMode = initialTheme,
        _updateNavbarColor = updateNavbarColor;

  void changeTheme(ThemeMode mode, {bool updateNavbarColor = true}) {
    _themeMode = mode;
    _updateNavbarColor = updateNavbarColor;
    notifyListeners();

    if (!kIsPlayStore) {
      // change shake theme as well
      ShakeTheme darkTheme = ShakeTheme();
      darkTheme.accentColor = "#FFFFFF";
      ShakeTheme lightTheme = ShakeTheme();
      lightTheme.accentColor = "#000000";
      Shake.setShakeTheme(mode == ThemeMode.dark ? darkTheme : lightTheme);
    }
  }
}
