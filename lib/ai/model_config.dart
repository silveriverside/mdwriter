import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 模型配置
class ModelConfig {
  String baseUrl;
  String apiKey;
  String model;

  ModelConfig({
    required this.baseUrl,
    required this.apiKey,
    required this.model,
  });

  // 从 JSON 创建配置
  factory ModelConfig.fromJson(Map<String, dynamic> json) {
    return ModelConfig(
      baseUrl: json['baseUrl'] as String,
      apiKey: json['apiKey'] as String,
      model: json['model'] as String,
    );
  }

  // 转换为 JSON
  Map<String, dynamic> toJson() => {
    'baseUrl': baseUrl,
    'apiKey': apiKey,
    'model': model,
  };
}

/// 模型配置管理器
class ModelConfigProvider extends ChangeNotifier {
  static const String _configKey = 'model_config';
  ModelConfig? _config;

  ModelConfig? get config => _config;

  // 加载配置
  Future<void> loadConfig() async {
    final prefs = await SharedPreferences.getInstance();
    final String? jsonStr = prefs.getString(_configKey);
    if (jsonStr != null) {
      try {
        final json = jsonDecode(jsonStr);
        _config = ModelConfig.fromJson(json);
        notifyListeners();
      } catch (e) {
        debugPrint('加载模型配置失败: $e');
      }
    }
  }

  // 保存配置
  Future<void> saveConfig(ModelConfig config) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = jsonEncode(config.toJson());
    await prefs.setString(_configKey, jsonStr);
    _config = config;
    notifyListeners();
  }

  // 清除配置
  Future<void> clearConfig() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_configKey);
    _config = null;
    notifyListeners();
  }
}