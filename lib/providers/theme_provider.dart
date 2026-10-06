// lib/providers/theme_provider.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  static const _prefsKey = 'isDarkMode';

  ThemeMode themeMode = ThemeMode.dark;
  bool get isDark => themeMode == ThemeMode.dark;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final isDarkStored = prefs.getBool(_prefsKey) ?? true;
    themeMode = isDarkStored ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }

  Future<void> toggle() async {
    themeMode = isDark ? ThemeMode.light : ThemeMode.dark;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsKey, isDark);
  }
}
