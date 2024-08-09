import 'package:basic_social_media_app/theme/dark_theme.dart';
import 'package:basic_social_media_app/theme/light_theme.dart';
import 'package:flutter/material.dart';

class ThemeNotifier with ChangeNotifier {
  bool _isLightMode = true;

  bool get isLightMode => _isLightMode;

  ThemeData get currentTheme => _isLightMode ? lightTheme : darkTheme;

  void toggleTheme() {
    _isLightMode = !_isLightMode;
    notifyListeners();
  }
}
