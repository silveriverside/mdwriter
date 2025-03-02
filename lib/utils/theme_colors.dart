import 'package:flutter/material.dart';

/// 主题颜色工具类，提供暗黑模式无蓝色配色方案
class ThemeColors {
  /// 获取背景颜色（主背景）
  static Color getBackgroundColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? const Color(0xFF050500) : Colors.white;
  }
  
  /// 获取表面颜色（卡片、对话框背景）
  static Color getSurfaceColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? const Color(0xFF101000) : Colors.grey[50]!;
  }
  
  /// 获取文本颜色
  static Color getTextColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? const Color(0xFFEAE0C0) : Colors.black87;
  }
  
  /// 获取强调色（按钮、链接）
  static Color getAccentColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? const Color(0xFFFF5500) : Colors.blue;
  }
  
  /// 获取高亮背景颜色
  static Color getHighlightColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark 
        ? const Color(0xFF552200).withOpacity(0.3) 
        : Colors.blue.withOpacity(0.2);
  }
  
  /// 获取错误颜色
  static Color getErrorColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? const Color(0xFFFF3300) : Colors.red;
  }
  
  /// 获取成功颜色
  static Color getSuccessColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? const Color(0xFF996600) : Colors.green;
  }
  
  /// 获取警告颜色
  static Color getWarningColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? const Color(0xFFFFAA00) : Colors.amber;
  }
} 