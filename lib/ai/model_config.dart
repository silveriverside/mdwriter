import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 模型配置
class ModelConfig {
  final String baseUrl;
  final String apiKey;
  final String model;
  final String name; // 配置名称
  final String apiType; // API类型: 'openai', 'custom'
  final String customRequestTemplate; // 自定义请求模板
  final Map<String, String> customHeaders; // 自定义请求头

  ModelConfig({
    required this.baseUrl,
    required this.apiKey,
    required this.model,
    this.name = '默认配置',
    this.apiType = 'openai',
    this.customRequestTemplate = '',
    this.customHeaders = const {},
  });

  // 从 JSON 创建配置
  factory ModelConfig.fromJson(Map<String, dynamic> json) {
    return ModelConfig(
      baseUrl: json['baseUrl'] ?? '',
      apiKey: json['apiKey'] ?? '',
      model: json['model'] ?? '',
      name: json['name'] ?? '默认配置',
      apiType: json['apiType'] ?? 'openai',
      customRequestTemplate: json['customRequestTemplate'] ?? '',
      customHeaders: Map<String, String>.from(json['customHeaders'] ?? {}),
    );
  }

  // 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'baseUrl': baseUrl,
      'apiKey': apiKey,
      'model': model,
      'name': name,
      'apiType': apiType,
      'customRequestTemplate': customRequestTemplate,
      'customHeaders': customHeaders,
    };
  }
}

/// 模型配置管理器
class ModelConfigProvider extends ChangeNotifier {
  static const String _configKey = 'model_config';
  ModelConfig? _config;
  List<ModelConfig> _savedConfigs = [];

  ModelConfig? get config => _config;
  List<ModelConfig> get savedConfigs => _savedConfigs;

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

    // 加载所有保存的配置
    await loadSavedConfigs();
  }

  Future<void> loadSavedConfigs() async {
    final prefs = await SharedPreferences.getInstance();
    final configsJson = prefs.getStringList('saved_configs') ?? [];
    
    _savedConfigs = configsJson
        .map((json) => ModelConfig.fromJson(jsonDecode(json)))
        .toList();
    
    notifyListeners();
  }

  // 保存配置
  Future<void> saveConfig(ModelConfig config) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_configKey, jsonEncode(config.toJson()));
    _config = config;
    
    // 更新或添加到已保存配置列表
    final existingIndex = _savedConfigs.indexWhere((c) => c.name == config.name);
    if (existingIndex >= 0) {
      _savedConfigs[existingIndex] = config;
    } else {
      _savedConfigs.add(config);
    }
    
    // 保存所有配置
    await saveSavedConfigs();
    
    notifyListeners();
  }

  Future<void> saveSavedConfigs() async {
    final prefs = await SharedPreferences.getInstance();
    final configsJson = _savedConfigs
        .map((config) => jsonEncode(config.toJson()))
        .toList();
    
    await prefs.setStringList('saved_configs', configsJson);
  }

  // 清除配置
  Future<void> clearConfig() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_configKey);
    _config = null;
    notifyListeners();
  }

  Future<void> deleteConfig(String name) async {
    _savedConfigs.removeWhere((c) => c.name == name);
    await saveSavedConfigs();
    notifyListeners();
  }

  Future<void> switchConfig(ModelConfig config) async {
    await saveConfig(config);
    _config = config;
    notifyListeners();
  }
}