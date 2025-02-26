import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'ai_block.dart';
import 'model_config.dart';

/// AI 处理引擎，负责处理 AI 相关的操作
class AiEngine {
  /// 单例实例
  static final AiEngine _instance = AiEngine._internal();

  /// 工厂构造函数
  factory AiEngine() {
    return _instance;
  }

  /// 私有构造函数
  AiEngine._internal();

  /// 当前的模型配置
  ModelConfig? _config;

  /// HTTP客户端
  http.Client? _client;

  /// 设置模型配置
  void setConfig(ModelConfig config) {
    _config = config;
  }

  /// 从文本中提取所有 AI 块
  List<AiBlock> extractAiBlocks(String text) {
    final List<AiBlock> blocks = [];
    final matches = RegExp(r'<ai>.*?</ai>', dotAll: true).allMatches(text);

    for (final match in matches) {
      final block = AiBlock.fromTextRange(text, match.start, match.end);
      if (block != null) {
        blocks.add(block);
      }
    }

    return blocks;
  }

  /// 停止所有处理
  void stopProcessing() {
    _client?.close();
    _client = null;
  }

  /// 处理单个 AI 块
  Future<void> processBlock(AiBlock block, {Function(String)? onProgress}) async {
    if (_config == null) {
      throw Exception('未配置模型');
    }

    try {
      _client = http.Client();
      final request = http.Request('POST', Uri.parse('${_config!.baseUrl}/chat/completions'));
      
      request.headers.addAll({
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${_config!.apiKey}',
      });

      request.body = jsonEncode({
        'model': _config!.model,
        'messages': [
          {
            'role': 'system',
            'content': '你是一个专业的文本优化助手，负责根据用户的要求修改和优化文本。',
          },
          {
            'role': 'user',
            'content': _buildPrompt(block),
          },
        ],
        'stream': true, // 启用流式响应
      });

      final response = await _client!.send(request);

      if (response.statusCode == 200) {
        StringBuffer contentBuffer = StringBuffer();
        StringBuffer lineBuffer = StringBuffer();
        
        await for (var chunk in response.stream.transform(utf8.decoder)) {
          // 如果客户端已关闭，停止处理
          if (_client == null) {
            break;
          }

          // 将新的chunk添加到行缓冲区
          lineBuffer.write(chunk);
          String bufferedData = lineBuffer.toString();
          
          // 处理完整的行
          while (bufferedData.contains('\n')) {
            final splitIndex = bufferedData.indexOf('\n');
            final line = bufferedData.substring(0, splitIndex).trim();
            bufferedData = bufferedData.substring(splitIndex + 1);

            if (line.startsWith('data: ')) {
              final dataContent = line.substring(6);
              if (dataContent == '[DONE]') {
                continue;
              }

              try {
                final data = jsonDecode(dataContent);
                final content = data['choices']?[0]?['delta']?['content'] ?? '';
                if (content.isNotEmpty) {
                  contentBuffer.write(content);
                  block.aiResult = contentBuffer.toString();
                  onProgress?.call(block.aiResult!);
                }
              } catch (e) {
                debugPrint('解析JSON数据时出错: $e\n数据内容: $dataContent');
                // 继续处理下一行，不中断整个流程
              }
            }
          }
          
          // 保存剩余的不完整数据
          lineBuffer.clear();
          lineBuffer.write(bufferedData);
        }
      } else {
        throw Exception('API 调用失败: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('处理 AI 块时出错: $e');
      rethrow;
    } finally {
      _client?.close();
      _client = null;
    }
  }

  /// 构建提示词
  String _buildPrompt(AiBlock block) {
    if (block.originalContent != null) {
      return '''
请根据以下要求修改文本：

指令：${block.instruction}

原文：${block.originalContent}

请保持文本的基本结构和格式，专注于内容的优化。
''';
    } else {
      return '''
请根据以下要求生成内容：

指令：${block.instruction}

请生成符合要求的内容。
''';
    }
  }

  /// 处理所有 AI 块
  Future<List<AiBlock>> processAllBlocks(String text, {Function(AiBlock, String)? onBlockProgress}) async {
    final blocks = extractAiBlocks(text);
    for (final block in blocks) {
      await processBlock(block, onProgress: (content) {
        onBlockProgress?.call(block, content);
      });
    }
    return blocks;
  }

  /// 替换文本中的 AI 块
  String replaceAiBlock(String text, AiBlock block) {
    if (block.aiResult == null) return text;
    return text.replaceRange(
      block.start,
      block.end,
      block.createReplacementText(),
    );
  }

  /// 替换所有 AI 块
  String replaceAllBlocks(String text, List<AiBlock> blocks) {
    String newText = text;
    // 从后向前替换，以避免位置变化
    for (final block in blocks.reversed) {
      newText = replaceAiBlock(newText, block);
    }
    return newText;
  }
}