import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/constants.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.dark;
  ThemeMode get themeMode => _themeMode;
  bool get isDark => _themeMode == ThemeMode.dark;

  ThemeProvider() { _loadTheme(); }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final theme = prefs.getString(AppConstants.prefTheme) ?? 'dark';
    _themeMode = theme == 'light' ? ThemeMode.light : theme == 'system' ? ThemeMode.system : ThemeMode.dark;
    notifyListeners();
  }

  Future<void> setTheme(String theme) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.prefTheme, theme);
    _themeMode = theme == 'light' ? ThemeMode.light : theme == 'system' ? ThemeMode.system : ThemeMode.dark;
    notifyListeners();
  }
}
