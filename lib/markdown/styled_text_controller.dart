import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'tag_style_renderer.dart';

/// 支持样式渲染的文本编辑控制器
class StyledTextEditingController extends TextEditingController {
  /// AI处理回调函数
  final VoidCallback? onAiProcess;

  StyledTextEditingController({this.onAiProcess});

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    // 使用标签渲染器处理文本
    final TextSpan taggedSpan = TagStyleRenderer.renderTaggedText(text);

    // 合并基础样式
    if (style != null) {
      return TextSpan(
        style: style,
        text: taggedSpan.text, // 添加text属性，确保不丢失文本内容
        children: taggedSpan.children,
      );
    }
    return taggedSpan;
  }

  /// 处理键盘事件
  bool handleKeyEvent(RawKeyEvent event) {
    if (event is RawKeyDownEvent && event.logicalKey == LogicalKeyboardKey.tab) {
      final currentPosition = selection.baseOffset;
      if (currentPosition < 0) return false;

      // 获取当前行的信息
      final beforeCursor = text.substring(0, currentPosition);
      final lineStart = beforeCursor.lastIndexOf('\n') + 1;
      final currentLine = text.substring(lineStart, currentPosition);

      // 判断光标是否在行首
      if (currentLine.trim().isEmpty) {
        // 在行首，插入两个空格作为缩进
        final newText = text.replaceRange(currentPosition, currentPosition, '  ');
        value = value.copyWith(
          text: newText,
          selection: TextSelection.collapsed(offset: currentPosition + 2),
        );
      } else {
        // 不在行首，将整行用<ai>标签包裹
        final lineEnd = text.indexOf('\n', currentPosition);
        final endPosition = lineEnd == -1 ? text.length : lineEnd;
        final fullLine = text.substring(lineStart, endPosition);

        // 如果行已经被<ai>标签包裹，不做处理
        if (!fullLine.trim().startsWith('<ai>')) {
          final newText = text.replaceRange(
            lineStart,
            endPosition,
            '<ai>${fullLine.trim()}</ai>',
          );
          value = value.copyWith(
            text: newText,
            selection: TextSelection.collapsed(
              offset: lineStart + '<ai>${fullLine.trim()}</ai>'.length,
            ),
          );

          // 触发AI处理
          onAiProcess?.call();
        }
      }
      return true; // 表示已处理Tab键
    }
    return false; // 未处理的键盘事件
  }
}