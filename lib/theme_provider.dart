//theme_provider.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light;

  ThemeMode get themeMode => _themeMode;

  ThemeProvider() {
    // 생성자에서 테마 모드 초기화
    _loadThemeMode();
  }

  void setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    // 변경된 테마 모드 저장
    await _saveThemeMode(mode);
  }

  // 테마 모드 저장
  Future<void> _saveThemeMode(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('themeMode', mode.toString());
  }

  // 테마 모드 로드
  Future<void> _loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final themeModeString = prefs.getString('themeMode') ?? ThemeMode.light.toString();
    _themeMode = ThemeMode.values.firstWhere(
          (e) => e.toString() == themeModeString,
      orElse: () => ThemeMode.light,
    );
    notifyListeners(); // UI 갱신
  }
}
