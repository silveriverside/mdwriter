import 'package:flutter/foundation.dart';
import 'ai_block.dart';
import 'ai_engine.dart';
import 'model_config.dart';

/// AI 处理状态管理器
class AiState extends ChangeNotifier {
  /// AI 引擎实例
  final AiEngine _engine = AiEngine();
  
  /// 当前的 AI 块列表
  List<AiBlock> _blocks = [];
  
  /// 是否正在处理
  bool _isProcessing = false;

  /// 错误信息
  String? _error;

  /// 获取当前的 AI 块列表
  List<AiBlock> get blocks => _blocks;

  /// 获取处理状态
  bool get isProcessing => _isProcessing;

  /// 获取错误信息
  String? get error => _error;

  /// 设置模型配置
  void setModelConfig(ModelConfig config) {
    _engine.setConfig(config);
    _error = null;
    notifyListeners();
  }

  /// 开始处理文本
  Future<void> processText(String text) async {
    if (_isProcessing) return;

    try {
      _error = null;
      _isProcessing = true;
      notifyListeners();

      // 提取所有AI块
      _blocks = _engine.extractAiBlocks(text);
      if (_blocks.isEmpty) {
        throw Exception('未找到需要处理的AI块，请使用<ai></ai>标签标记需要处理的内容');
      }
      notifyListeners();

      // 逐个处理AI块，支持流式更新
      for (final block in _blocks) {
        if (!_isProcessing) break; // 如果已停止，则退出循环
        
        await _engine.processBlock(block, onProgress: (content) {
          // 每次收到新的内容时通知监听器更新UI
          notifyListeners();
        });
      }
      
    } catch (e) {
      _error = e.toString();
      debugPrint('处理文本时出错: $e');
      _blocks = []; // 清空块列表
      notifyListeners();
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  /// 停止处理
  void stopProcessing() {
    if (!_isProcessing) return;
    
    _engine.stopProcessing();
    _isProcessing = false;
    notifyListeners();
  }

  /// 替换指定的 AI 块
  String replaceBlock(String text, AiBlock block) {
    try {
      // 重新查找AI块的位置
      final pattern = RegExp(r'<ai>.*?</ai>', dotAll: true);
      final matches = pattern.allMatches(text);
      
      // 找到匹配的块
      for (final match in matches) {
        final matchText = text.substring(match.start, match.end);
        if (matchText == block.originalText) {
          // 找到原始块，使用新位置替换
          return text.replaceRange(match.start, match.end, block.createReplacementText());
        }
      }
      
      // 如果没找到匹配的块，返回原文
      return text;
    } catch (e) {
      debugPrint('替换AI块时出错: $e');
      return text;
    }
  }

  /// 替换所有 AI 块
  String replaceAllBlocks(String text) {
    String newText = text;
    // 从后向前替换，以避免位置变化
    for (final block in _blocks.reversed) {
      newText = replaceBlock(newText, block);
    }
    return newText;
  }

  /// 清除所有块
  void clear() {
    _blocks = [];
    _error = null;
    notifyListeners();
  }
}