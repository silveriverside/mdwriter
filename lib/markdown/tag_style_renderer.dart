import 'package:flutter/material.dart';
import 'markdown_parser.dart';

/// AI标签样式渲染器
class TagStyleRenderer {
  /// AI标签文本样式
  static const TextStyle aiTagStyle = TextStyle(
    color: Colors.grey,
    fontSize: 12,
  );

  /// AI内容样式
  static const TextStyle aiContentStyle = TextStyle(
    backgroundColor: Color(0x40FFD700), // 淡黄色背景
    color: Colors.black87,
  );

  /// 原文标签样式
  static const TextStyle originTagStyle = TextStyle(
    color: Colors.grey,
    fontSize: 12,
  );

  /// 原文内容样式
  static const TextStyle originTextStyle = TextStyle(
    backgroundColor: Color(0x40FFC0CB), // 淡粉色背景
    color: Colors.black87,
  );

  /// 渲染带有标签的文本
  static TextSpan renderTaggedText(String text) {
    final List<InlineSpan> spans = [];

    // 处理空文本情况
    if (text.isEmpty) {
      return const TextSpan(text: '');
    }

    int currentPosition = 0;
    // 查找所有AI标签
    final aiMatches = MarkdownParser.aiTagRegex.allMatches(text).toList();

    for (final aiMatch in aiMatches) {
      // 验证匹配有效性
      if (aiMatch.start < 0 || aiMatch.end > text.length || aiMatch.start >= aiMatch.end) {
        continue;
      }

      // 添加AI标签前的普通文本
      if (aiMatch.start > currentPosition) {
        spans.add(TextSpan(
          text: text.substring(currentPosition, aiMatch.start),
        ));
      }

      // 添加开始AI标签
      spans.add(TextSpan(
        text: '<ai>',
        style: aiTagStyle,
      ));

      // 获取AI标签内的内容
      final aiContent = aiMatch.group(1) ?? '';

      // 检查AI内容中是否包含原文标签
      final originMatches = MarkdownParser.originTextRegex.allMatches(aiContent).toList();

      if (originMatches.isEmpty) {
        // 如果没有原文标签，直接添加AI内容
        spans.add(TextSpan(
          text: aiContent,
          style: aiContentStyle,
        ));
      } else {
        // 如果有原文标签，处理嵌套标签
        int aiContentPosition = 0;
        for (final originMatch in originMatches) {
          // 验证匹配有效性
          if (originMatch.start < 0 || originMatch.end > aiContent.length || originMatch.start >= originMatch.end) {
            continue;
          }

          // 添加原文标签前的AI内容
          if (originMatch.start > aiContentPosition) {
            spans.add(TextSpan(
              text: aiContent.substring(aiContentPosition, originMatch.start),
              style: aiContentStyle,
            ));
          }

          // 添加原文标签
          spans.add(TextSpan(
            text: '<origintext>',
            style: originTagStyle,
          ));

          // 添加原文内容
          final originContent = originMatch.group(1) ?? '';
          spans.add(TextSpan(
            text: originContent,
            style: originTextStyle,
          ));

          // 添加结束原文标签
          spans.add(TextSpan(
            text: '</origintext>',
            style: originTagStyle,
          ));

          aiContentPosition = originMatch.end;
        }
        // 添加最后一个原文标签后的AI内容
        if (aiContentPosition < aiContent.length) {
          spans.add(TextSpan(
            text: aiContent.substring(aiContentPosition),
            style: aiContentStyle,
          ));
        }
      }
      // 添加结束AI标签
      spans.add(TextSpan(
        text: '</ai>',
        style: aiTagStyle,
      ));

      currentPosition = aiMatch.end;
    }
    // 添加剩余的普通文本
    if (currentPosition < text.length) {
      spans.add(TextSpan(
        text: text.substring(currentPosition),
      ));
    }
    // 确保spans不为空，避免渲染问题
    if (spans.isEmpty) {
      return const TextSpan(text: '');
    }

    return TextSpan(children: spans);
  }
}