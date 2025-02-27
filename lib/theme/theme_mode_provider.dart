import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeModeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  
  ThemeMode get themeMode => _themeMode;
  
  // 构造函数，初始化时加载保存的主题模式
  ThemeModeProvider() {
    _loadThemeMode();
  }
  
  // 从SharedPreferences加载主题模式
  Future<void> _loadThemeMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedThemeMode = prefs.getString('themeMode');
      
      if (savedThemeMode != null) {
        switch (savedThemeMode) {
          case 'light':
            _themeMode = ThemeMode.light;
            break;
          case 'dark':
            _themeMode = ThemeMode.dark;
            break;
          default:
            _themeMode = ThemeMode.system;
        }
        notifyListeners();
      }
    } catch (e) {
      // 如果加载失败，使用系统默认主题
      _themeMode = ThemeMode.system;
    }
  }
  
  // 设置主题模式
  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;
    
    _themeMode = mode;
    notifyListeners();
    
    // 保存主题模式到SharedPreferences
    try {
      final prefs = await SharedPreferences.getInstance();
      String themeModeString;
      
      switch (mode) {
        case ThemeMode.light:
          themeModeString = 'light';
          break;
        case ThemeMode.dark:
          themeModeString = 'dark';
          break;
        default:
          themeModeString = 'system';
      }
      
      await prefs.setString('themeMode', themeModeString);
    } catch (e) {
      // 保存失败时的处理
      print('保存主题模式失败: $e');
    }
  }
  
  // 切换到亮色主题
  void setLightMode() {
    setThemeMode(ThemeMode.light);
  }
  
  // 切换到暗色主题
  void setDarkMode() {
    setThemeMode(ThemeMode.dark);
  }
  
  // 切换到系统主题
  void setSystemMode() {
    setThemeMode(ThemeMode.system);
  }
  
  // 切换主题（在当前主题和暗黑主题之间切换）
  void toggleTheme() {
    if (_themeMode == ThemeMode.dark) {
      setThemeMode(ThemeMode.light);
    } else {
      setThemeMode(ThemeMode.dark);
    }
  }
}