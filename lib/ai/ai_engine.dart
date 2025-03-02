import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
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
      
      if (_config!.apiType == 'openai') {
        await _processOpenAiBlock(block, onProgress);
      } else {
        await _processCustomApiBlock(block, onProgress);
      }
    } catch (e) {
      debugPrint('处理 AI 块时出错: $e');
      rethrow;
    } finally {
      _client?.close();
      _client = null;
    }
  }

  /// 处理OpenAI兼容的API请求
  Future<void> _processOpenAiBlock(AiBlock block, Function(String)? onProgress) async {
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
      await _handleOpenAiStream(response, block, onProgress);
    } else {
      throw Exception('API 调用失败: ${response.statusCode}');
    }
  }

  /// 处理自定义API请求
  Future<void> _processCustomApiBlock(AiBlock block, Function(String)? onProgress) async {
    String code = _config!.customRequestTemplate;
    
    // 替换模板中的变量
    code = code
        .replaceAll('{instruction}', block.instruction)
        .replaceAll('{originalContent}', block.originalContent ?? '');
    
    // 检测是curl命令还是Python代码
    if (code.trim().startsWith('curl')) {
      await _processCurlCommand(code, block, onProgress);
    } else if (code.contains('import requests') || code.contains('requests.')) {
      await _processPythonCode(code, block, onProgress);
    } else {
      // 尝试作为JSON请求模板处理
      await _processJsonTemplate(code, block, onProgress);
    }
  }

  /// 处理curl命令
  Future<void> _processCurlCommand(String curlCommand, AiBlock block, Function(String)? onProgress) async {
    try {
      // 解析curl命令
      final url = _extractUrlFromCurl(curlCommand);
      final headers = _extractHeadersFromCurl(curlCommand);
      final data = _extractDataFromCurl(curlCommand);
      
      // 发送HTTP请求
      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: data,
      );
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        // 尝试解析响应
        _handleApiResponse(response.body, block, onProgress);
      } else {
        throw Exception('API 调用失败: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('处理curl命令时出错: $e');
      rethrow;
    }
  }

  /// 处理Python代码
  Future<void> _processPythonCode(String pythonCode, AiBlock block, Function(String)? onProgress) async {
    try {
      // 从Python代码中提取URL、headers和data
      final url = _extractUrlFromPython(pythonCode);
      final headers = _extractHeadersFromPython(pythonCode);
      final data = _extractDataFromPython(pythonCode);
      
      // 发送HTTP请求
      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: data,
      );
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        // 尝试解析响应
        _handleApiResponse(response.body, block, onProgress);
      } else {
        throw Exception('API 调用失败: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('处理Python代码时出错: $e');
      rethrow;
    }
  }

  /// 处理JSON模板
  Future<void> _processJsonTemplate(String jsonTemplate, AiBlock block, Function(String)? onProgress) async {
    try {
      // 尝试解析为JSON
      final request = http.Request('POST', Uri.parse(_config!.baseUrl));
      
      request.headers.addAll({
        'Content-Type': 'application/json',
      });
      
      // 如果有API Key，添加Authorization头
      if (_config!.apiKey.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer ${_config!.apiKey}';
      }
      
      request.body = jsonTemplate;
      
      final response = await _client!.send(request);
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final responseBody = await response.stream.bytesToString();
        _handleApiResponse(responseBody, block, onProgress);
      } else {
        throw Exception('API 调用失败: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('处理JSON模板时出错: $e');
      rethrow;
    }
  }

  /// 处理API响应
  void _handleApiResponse(String responseBody, AiBlock block, Function(String)? onProgress) {
    try {
      // 尝试解析为JSON
      final jsonResponse = jsonDecode(responseBody);
      
      // 尝试从不同的常见响应格式中提取内容
      String? content;
      
      // 尝试OpenAI格式
      content ??= jsonResponse['choices']?[0]?['message']?['content'];
      
      // 尝试直接content字段
      content ??= jsonResponse['content'];
      
      // 尝试text或response字段
      content ??= jsonResponse['text'] ?? jsonResponse['response'];
      
      // 尝试data字段
      content ??= jsonResponse['data'];
      
      // 尝试result字段
      content ??= jsonResponse['result'];
      
      if (content != null) {
        if (content is Map || content is List) {
          // 如果内容是对象或数组，转换为格式化的JSON字符串
          block.aiResult = const JsonEncoder.withIndent('  ').convert(content);
        } else {
          block.aiResult = content.toString();
        }
        onProgress?.call(block.aiResult!);
      } else {
        // 如果无法提取特定字段，使用整个响应
        block.aiResult = const JsonEncoder.withIndent('  ').convert(jsonResponse);
        onProgress?.call(block.aiResult!);
      }
    } catch (e) {
      // 如果JSON解析失败，直接使用原始响应
      block.aiResult = responseBody;
      onProgress?.call(responseBody);
    }
  }

  // 辅助方法：从curl命令中提取URL
  String _extractUrlFromCurl(String curlCommand) {
    final urlRegex = RegExp(r"curl\s+.*?(?:--request|-X)\s+\w+\s+'([^']+)'");
    final match = urlRegex.firstMatch(curlCommand);
    if (match != null && match.groupCount >= 1) {
      return match.group(1)!;
    }
    
    // 尝试另一种格式
    final altUrlRegex = RegExp(r"curl\s+(?:--location\s+)?'([^']+)'");
    final altMatch = altUrlRegex.firstMatch(curlCommand);
    if (altMatch != null && altMatch.groupCount >= 1) {
      return altMatch.group(1)!;
    }
    
    throw Exception('无法从curl命令中提取URL');
  }

  // 辅助方法：从curl命令中提取headers
  Map<String, String> _extractHeadersFromCurl(String curlCommand) {
    final headers = <String, String>{};
    final headerRegex = RegExp(r"--header\s+'([^:]+):\s*([^']+)'");
    final matches = headerRegex.allMatches(curlCommand);
    
    for (final match in matches) {
      if (match.groupCount >= 2) {
        final key = match.group(1)!.trim();
        final value = match.group(2)!.trim();
        headers[key] = value;
      }
    }
    
    return headers;
  }

  // 辅助方法：从curl命令中提取data
  String _extractDataFromCurl(String curlCommand) {
    final dataRegex = RegExp(r"--data-raw\s+'(.*?)'", dotAll: true);
    final match = dataRegex.firstMatch(curlCommand);
    if (match != null && match.groupCount >= 1) {
      return match.group(1)!;
    }
    
    // 尝试另一种格式
    final altDataRegex = RegExp(r"--data\s+'(.*?)'", dotAll: true);
    final altMatch = altDataRegex.firstMatch(curlCommand);
    if (altMatch != null && altMatch.groupCount >= 1) {
      return altMatch.group(1)!;
    }
    
    return '';
  }

  // 辅助方法：从Python代码中提取URL
  String _extractUrlFromPython(String pythonCode) {
    // 先尝试寻找单引号形式的URL
    final singleQuoteRegex = RegExp(r"url\s*=\s*'(.*?)'");
    final singleMatch = singleQuoteRegex.firstMatch(pythonCode);
    if (singleMatch != null && singleMatch.groupCount >= 1) {
      return singleMatch.group(1)!;
    }
    
    // 再尝试寻找双引号形式的URL
    final doubleQuoteRegex = RegExp(r'url\s*=\s*"(.*?)"');
    final doubleMatch = doubleQuoteRegex.firstMatch(pythonCode);
    if (doubleMatch != null && doubleMatch.groupCount >= 1) {
      return doubleMatch.group(1)!;
    }
    
    throw Exception('无法从Python代码中提取URL');
  }

  // 辅助方法：从Python代码中提取headers
  Map<String, String> _extractHeadersFromPython(String pythonCode) {
    final headers = <String, String>{};
    
    // 尝试提取headers字典
    final headersBlockRegex = RegExp(r'headers\s*=\s*\{(.*?)\}', dotAll: true);
    final blockMatch = headersBlockRegex.firstMatch(pythonCode);
    
    if (blockMatch != null && blockMatch.groupCount >= 1) {
      final headersBlock = blockMatch.group(1)!;
      
      // 分别处理单引号和双引号的情况
      _extractKeyValuePairs(headersBlock, headers);
    }
    
    return headers;
  }

  // 辅助方法：从Python代码中提取data
  String _extractDataFromPython(String pythonCode) {
    // 尝试提取data字典
    final Map<String, dynamic> dataMap = {};
    
    // 匹配多种可能的参数名
    for (final param in ['data', 'params', 'json']) {
      final dataBlockRegex = RegExp('$param\\s*=\\s*\\{(.*?)\\}', dotAll: true);
      final blockMatch = dataBlockRegex.firstMatch(pythonCode);
      
      if (blockMatch != null && blockMatch.groupCount >= 1) {
        final dataBlock = blockMatch.group(1)!;
        
        // 提取键值对
        _extractKeyValuePairs(dataBlock, dataMap);
        
        if (dataMap.isNotEmpty) {
          return jsonEncode(dataMap);
        }
      }
    }
    
    return '';
  }

  // 辅助方法：从字符串中提取键值对
  void _extractKeyValuePairs(String text, Map<String, dynamic> result) {
    try {
      // 处理单引号键和单引号值
      var singleQuoteRegex = RegExp("'([^']*)'\\s*:\\s*'([^']*)'");
      var singleMatches = singleQuoteRegex.allMatches(text);
      for (var match in singleMatches) {
        if (match.groupCount >= 2) {
          var key = match.group(1)!.trim();
          var value = match.group(2)!.trim();
          result[key] = value;
        }
      }
      
      // 处理单引号键和双引号值
      var mixedQuote1Regex = RegExp("'([^']*)'\\s*:\\s*\"([^\"]*)\"");
      var mixedMatches1 = mixedQuote1Regex.allMatches(text);
      for (var match in mixedMatches1) {
        if (match.groupCount >= 2) {
          var key = match.group(1)!.trim();
          var value = match.group(2)!.trim();
          result[key] = value;
        }
      }
      
      // 处理双引号键和单引号值
      var mixedQuote2Regex = RegExp("\"([^\"]*)\"\\s*:\\s*'([^']*)'");
      var mixedMatches2 = mixedQuote2Regex.allMatches(text);
      for (var match in mixedMatches2) {
        if (match.groupCount >= 2) {
          var key = match.group(1)!.trim();
          var value = match.group(2)!.trim();
          result[key] = value;
        }
      }
      
      // 处理双引号键和双引号值
      var doubleQuoteRegex = RegExp("\"([^\"]*)\"\\s*:\\s*\"([^\"]*)\"");
      var doubleMatches = doubleQuoteRegex.allMatches(text);
      for (var match in doubleMatches) {
        if (match.groupCount >= 2) {
          var key = match.group(1)!.trim();
          var value = match.group(2)!.trim();
          result[key] = value;
        }
      }
      
      // 处理非字符串值（如数字、布尔值）
      // 使用单独的正则表达式处理单引号和双引号情况
      var nonStringSingleRegex = RegExp("'([^']*)'\\s*:\\s*([^,}\\s][^,}]*)");
      var nonStringDoubleRegex = RegExp("\"([^\"]*)\"\\s*:\\s*([^,}\\s][^,}]*)");
      
      for (var regex in [nonStringSingleRegex, nonStringDoubleRegex]) {
        var matches = regex.allMatches(text);
        for (var match in matches) {
          if (match.groupCount >= 2) {
            var key = match.group(1)!.trim();
            var value = match.group(2)!.trim();
            // 避免重复已处理的键
            if (!result.containsKey(key)) {
              result[key] = value;
            }
          }
        }
      }
    } catch (e) {
      debugPrint('提取键值对时出错: $e');
    }
  }

  /// 处理OpenAI流式响应
  Future<void> _handleOpenAiStream(
    http.StreamedResponse response, 
    AiBlock block, 
    Function(String)? onProgress
  ) async {
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