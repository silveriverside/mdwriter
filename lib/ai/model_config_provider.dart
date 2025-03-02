import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class ModelConfigProvider extends ChangeNotifier {
  ModelConfig? _config;
  List<ModelConfig> _savedConfigs = [];
  String _configKey = 'model_config';

  ModelConfig? get config => _config;
  List<ModelConfig> get savedConfigs => _savedConfigs;

  Future<void> saveConfig(ModelConfig config) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_configKey, jsonEncode(config.toJson()));
    _config = config;
    
    // 防止重复，移除同名配置
    _savedConfigs.removeWhere((c) => c.name == config.name);
    _savedConfigs.add(config);
    
    // 保存所有配置
    await saveSavedConfigs();
    
    notifyListeners();
  }

  Future<void> loadSavedConfigs() async {
    final prefs = await SharedPreferences.getInstance();
    final configsJson = prefs.getStringList('saved_configs') ?? [];
    
    // 使用Map确保名称唯一
    final Map<String, ModelConfig> uniqueConfigs = {};
    
    for (final json in configsJson) {
      try {
        final config = ModelConfig.fromJson(jsonDecode(json));
        uniqueConfigs[config.name] = config;
      } catch (e) {
        debugPrint('加载配置出错: $e');
      }
    }
    
    _savedConfigs = uniqueConfigs.values.toList();
    notifyListeners();
  }

  Future<void> saveSavedConfigs() async {
    final prefs = await SharedPreferences.getInstance();
    final configsJson = _savedConfigs.map((c) => jsonEncode(c.toJson())).toList();
    await prefs.setStringList('saved_configs', configsJson);
  }
} 