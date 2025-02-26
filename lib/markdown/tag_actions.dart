import 'package:flutter/material.dart';
import 'markdown_parser.dart';
import 'styled_text_controller.dart';

/// 标签操作类，提供标签相关的操作功能
class TagActions {
  /// 插入AI标签
  static void insertAiTag(
    BuildContext context,
    StyledTextEditingController controller,
    VoidCallback onChanged,
  ) {
    final TextSelection selection = controller.selection;
    final String newText;
    int newCursorPosition;

    if (selection.isValid && !selection.isCollapsed) {
      // 有选中文本，在选中文本两侧插入AI标签
      newText = MarkdownParser.insertAiTagAroundSelection(
        controller.text,
        selection.start,
        selection.end,
      );
      newCursorPosition = selection.end + 4; // 将光标移动到</ai>之前
    } else {
      // 无选中文本，在光标位置插入AI标签对
      final int cursorPosition = selection.baseOffset;
      newText = MarkdownParser.insertAiTagAtCursor(
        controller.text,
        cursorPosition,
      );
      newCursorPosition = cursorPosition + 4; // 将光标移动到<ai></ai>中间
    }

    // 更新文本并设置光标位置
    controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newCursorPosition),
    );

    onChanged();
  }

  /// 插入原文标签
  static void insertOriginTextTag(
    BuildContext context,
    StyledTextEditingController controller,
    VoidCallback onChanged,
  ) {
    final TextSelection selection = controller.selection;
    final String newText;
    int newCursorPosition;

    if (selection.isValid && !selection.isCollapsed) {
      // 有选中文本，在选中文本外包裹AI和原文标签
      newText = MarkdownParser.wrapWithAiAndOriginTextTag(
        controller.text,
        selection.start,
        selection.end,
      );
      newCursorPosition = selection.end + 27; // 将光标移动到</origintext>和</ai>之间
    } else {
      // 无选中文本，在光标位置插入原文标签对并提示
      final int cursorPosition = selection.baseOffset;
      newText = MarkdownParser.insertOriginTextTagAtCursor(
        controller.text,
        cursorPosition,
      );
      newCursorPosition = cursorPosition + 11; // 将光标移动到<origintext></origintext>中间
      
      // 显示提示
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('未选中文本'),
          duration: Duration(seconds: 2),
        ),
      );
    }

    // 更新文本并设置光标位置
    controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newCursorPosition),
    );

    onChanged();
  }

  /// 创建标签操作按钮
  static List<Widget> buildTagActionButtons(
    BuildContext context,
    StyledTextEditingController controller,
    VoidCallback onChanged,
  ) {
    return [
      // AI标签按钮
      IconButton(
        icon: const Icon(Icons.smart_toy_outlined),
        tooltip: '插入AI标签',
        onPressed: () => insertAiTag(context, controller, onChanged),
      ),
      // 原文标签按钮
      IconButton(
        icon: const Icon(Icons.format_quote),
        tooltip: '插入原文标签',
        onPressed: () => insertOriginTextTag(context, controller, onChanged),
      ),
    ];
  }
}