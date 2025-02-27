import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'styled_text_controller.dart';
import 'tag_style_renderer.dart';

/// 支持Markdown和自定义标签样式渲染的文本编辑控制器
class MarkdownStyledTextEditingController extends StyledTextEditingController {
  /// Markdown语法样式
  final Map<String, TextStyle> markdownStyles;

  MarkdownStyledTextEditingController({
    VoidCallback? onAiProcess,
    Map<String, TextStyle>? markdownStyles,
  }) : this.markdownStyles = markdownStyles ?? _defaultMarkdownStyles(),
       super(onAiProcess: onAiProcess);

  /// 默认的Markdown样式
  static Map<String, TextStyle> _defaultMarkdownStyles() {
    return {
      'h1': const TextStyle(
        fontSize: 24.0,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
      'h2': const TextStyle(
        fontSize: 22.0,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
      'h3': const TextStyle(
        fontSize: 20.0,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
      'h4': const TextStyle(
        fontSize: 18.0,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
      'h5': const TextStyle(
        fontSize: 16.0,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
      'h6': const TextStyle(
        fontSize: 14.0,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
      'strong': const TextStyle(
        fontWeight: FontWeight.bold,
      ),
      'em': const TextStyle(
        fontStyle: FontStyle.italic,
      ),
      'code': const TextStyle(
        fontFamily: 'monospace',
        backgroundColor: Color(0xFFEEEEEE),
      ),
      'link': const TextStyle(
        color: Colors.blue,
        decoration: TextDecoration.underline,
      ),
    };
  }

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    // 首先调用父类方法处理自定义标签
    final TextSpan taggedSpan = super.buildTextSpan(
      context: context,
      style: style,
      withComposing: withComposing,
    );
    
    // 如果没有子元素，说明没有自定义标签，直接应用Markdown渲染
    if (taggedSpan.children == null || taggedSpan.children!.isEmpty) {
      return _applyMarkdownStyling(super.text, style);
    }
    
    // 处理带有自定义标签的文本，只对非标签部分应用Markdown渲染
    List<InlineSpan> newChildren = [];
    
    for (var child in taggedSpan.children!) {
      if (child is TextSpan) {
        // 检查是否是自定义标签
        if (child.style == TagStyleRenderer.aiTagStyle ||
            child.style == TagStyleRenderer.originTagStyle) {
          // 是标签，保持原样
          newChildren.add(child);
        } else if (child.style == TagStyleRenderer.aiContentStyle ||
                  child.style == TagStyleRenderer.originTextStyle) {
          // 是标签内容，保持原样
          newChildren.add(child);
        } else {
          // 非标签部分，应用Markdown渲染
          final String plainText = child.text ?? '';
          final TextSpan markdownSpan = _applyMarkdownStyling(plainText, style);
          
          if (markdownSpan.children != null && markdownSpan.children!.isNotEmpty) {
            newChildren.addAll(markdownSpan.children!);
          } else {
            newChildren.add(TextSpan(text: plainText, style: style));
          }
        }
      } else {
        newChildren.add(child);
      }
    }
    
    return TextSpan(
      style: style,
      children: newChildren,
    );
  }
  
  /// 应用Markdown样式
  TextSpan _applyMarkdownStyling(String text, TextStyle? baseStyle) {
    // 简单实现，只处理标题和粗体
    List<InlineSpan> spans = [];
    
    // 处理标题
    final headingRegex = RegExp(r'^(#{1,6})\s+(.+)$', multiLine: true);
    final matches = headingRegex.allMatches(text);
    
    if (matches.isEmpty) {
      // 处理粗体
      return _processBold(text, baseStyle);
    }
    
    int currentPosition = 0;
    
    for (final match in matches) {
      // 添加标题前的文本
      if (match.start > currentPosition) {
        final beforeText = text.substring(currentPosition, match.start);
        final beforeSpan = _processBold(beforeText, baseStyle);
        if (beforeSpan.children != null && beforeSpan.children!.isNotEmpty) {
          spans.addAll(beforeSpan.children!);
        } else if (beforeSpan.text != null && beforeSpan.text!.isNotEmpty) {
          spans.add(beforeSpan);
        }
      }
      
      // 处理标题
      final level = match.group(1)!.length;
      final headingText = match.group(2)!;
      final headingStyle = markdownStyles['h$level']?.merge(baseStyle) ?? baseStyle;
      
      spans.add(TextSpan(
        text: headingText,
        style: headingStyle,
      ));
      
      // 添加换行符
      spans.add(TextSpan(text: '\n', style: baseStyle));
      
      currentPosition = match.end;
    }
    
    // 添加剩余的文本
    if (currentPosition < text.length) {
      final afterText = text.substring(currentPosition);
      final afterSpan = _processBold(afterText, baseStyle);
      if (afterSpan.children != null && afterSpan.children!.isNotEmpty) {
        spans.addAll(afterSpan.children!);
      } else if (afterSpan.text != null && afterSpan.text!.isNotEmpty) {
        spans.add(afterSpan);
      }
    }
    
    return TextSpan(children: spans);
  }
  
  /// 处理粗体
  TextSpan _processBold(String text, TextStyle? baseStyle) {
    List<InlineSpan> spans = [];
    
    // 处理粗体
    final boldRegex = RegExp(r'\*\*(.*?)\*\*');
    final boldMatches = boldRegex.allMatches(text);
    
    if (boldMatches.isEmpty) {
      // 处理斜体
      return _processItalic(text, baseStyle);
    }
    
    int currentPosition = 0;
    
    for (final match in boldMatches) {
      // 添加粗体前的文本
      if (match.start > currentPosition) {
        final beforeText = text.substring(currentPosition, match.start);
        final beforeSpan = _processItalic(beforeText, baseStyle);
        if (beforeSpan.children != null && beforeSpan.children!.isNotEmpty) {
          spans.addAll(beforeSpan.children!);
        } else if (beforeSpan.text != null && beforeSpan.text!.isNotEmpty) {
          spans.add(beforeSpan);
        }
      }
      
      // 处理粗体
      final boldText = match.group(1)!;
      final boldStyle = markdownStyles['strong']?.merge(baseStyle) ??
                        baseStyle?.copyWith(fontWeight: FontWeight.bold) ??
                        const TextStyle(fontWeight: FontWeight.bold);
      
      spans.add(TextSpan(
        text: boldText,
        style: boldStyle,
      ));
      
      currentPosition = match.end;
    }
    
    // 添加剩余的文本
    if (currentPosition < text.length) {
      final afterText = text.substring(currentPosition);
      final afterSpan = _processItalic(afterText, baseStyle);
      if (afterSpan.children != null && afterSpan.children!.isNotEmpty) {
        spans.addAll(afterSpan.children!);
      } else if (afterSpan.text != null && afterSpan.text!.isNotEmpty) {
        spans.add(afterSpan);
      }
    }
    
    return TextSpan(children: spans);
  }
  
  /// 处理斜体
  TextSpan _processItalic(String text, TextStyle? baseStyle) {
    // 简单实现，只返回普通文本
    return TextSpan(text: text, style: baseStyle);
  }
}
