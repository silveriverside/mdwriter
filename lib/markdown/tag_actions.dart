import 'package:flutter/material.dart';
import 'markdown_parser.dart';
import 'styled_text_controller.dart';
import 'markdown_styled_controller.dart';

/// 标签操作类，提供标签相关的操作功能
class TagActions {
  /// 插入AI标签
  static void insertAiTag(
    BuildContext context,
    TextEditingController controller,
    VoidCallback onChanged,
  ) {
    final TextSelection selection = controller.selection;
    final String text = controller.text;
    final String newText;
    int newCursorPosition;
    
    // 检查光标是否在AI标签内
    final inAiTag = _isInsideAiTag(text, selection);
    
    if (inAiTag != null) {
      // 如果在AI标签内，则删除标签
      newText = _removeAiTag(text, inAiTag.start, inAiTag.end, selection);
      newCursorPosition = selection.baseOffset - 4; // 调整光标位置（去掉<ai>标记）
    } else if (selection.isValid && !selection.isCollapsed) {
      // 有选中文本，在选中文本两侧插入AI标签
      newText = MarkdownParser.insertAiTagAroundSelection(
        text,
        selection.start,
        selection.end,
      );
      newCursorPosition = selection.end + 4; // 将光标移动到</ai>之前
    } else {
      // 无选中文本，在光标位置插入AI标签对
      final int cursorPosition = selection.baseOffset;
      newText = MarkdownParser.insertAiTagAtCursor(
        text,
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
    TextEditingController controller,
    VoidCallback onChanged,
  ) {
    final TextSelection selection = controller.selection;
    final String text = controller.text;
    final String newText;
    int newCursorPosition;
    
    // 检查光标是否在原文标签内
    final inOriginTextTag = _isInsideOriginTextTag(text, selection);
    // 检查光标是否在AI标签内（用于第3种情况）
    final inAiTag = _isInsideAiTag(text, selection);
    
    if (inOriginTextTag != null) {
      // 如果在原文标签内，则只删除原文标签
      newText = _removeOriginTextTag(text, inOriginTextTag.start, inOriginTextTag.end, selection);
      newCursorPosition = selection.baseOffset - 11; // 调整光标位置（去掉<origintext>标记）
    } else if (selection.isValid && !selection.isCollapsed && inAiTag != null) {
      // 如果有选中文本，且在AI标签内，则只添加origintext标签
      newText = _addOriginTextTagToSelection(
        text,
        selection.start,
        selection.end,
      );
      newCursorPosition = selection.end + 12; // 将光标移动到</origintext>之后
    } else if (selection.isValid && !selection.isCollapsed) {
      // 有选中文本，但不在AI标签内，则同时添加AI和原文标签
      newText = MarkdownParser.wrapWithAiAndOriginTextTag(
        text,
        selection.start,
        selection.end,
      );
      newCursorPosition = selection.end + 27; // 将光标移动到</origintext>和</ai>之间
    } else {
      // 无选中文本，在光标位置插入原文标签对
      final int cursorPosition = selection.baseOffset;
      newText = MarkdownParser.insertOriginTextTagAtCursor(
        text,
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
  
  /// 检查光标是否在AI标签内
  static _AiTagRange? _isInsideAiTag(String text, TextSelection selection) {
    // 查找光标之前最近的<ai>标签
    int startTagIndex = text.lastIndexOf('<ai>', selection.baseOffset);
    if (startTagIndex == -1) return null;
    
    // 查找光标之后最近的</ai>标签
    int endTagIndex = text.indexOf('</ai>', selection.baseOffset);
    if (endTagIndex == -1) return null;
    
    // 确保这对标签是匹配的（中间没有其他未闭合的<ai>标签）
    int nestedCount = 0;
    int searchStart = startTagIndex + 4;
    while (searchStart < selection.baseOffset) {
      int nextStart = text.indexOf('<ai>', searchStart);
      int nextEnd = text.indexOf('</ai>', searchStart);
      
      if (nextStart == -1 || (nextEnd != -1 && nextEnd < nextStart)) {
        if (nextEnd != -1 && nextEnd < selection.baseOffset) {
          nestedCount--;
          searchStart = nextEnd + 5;
        } else {
          break;
        }
      } else if (nextStart != -1 && nextStart < selection.baseOffset) {
        nestedCount++;
        searchStart = nextStart + 4;
      } else {
        break;
      }
    }
    
    // 如果嵌套计数为0，说明光标位于有效的AI标签对内
    if (nestedCount == 0) {
      return _AiTagRange(startTagIndex, endTagIndex + 5);
    }
    
    return null;
  }
  
  /// 检查光标是否在原文标签内
  static _AiTagRange? _isInsideOriginTextTag(String text, TextSelection selection) {
    // 查找光标之前最近的<origintext>标签
    int startTagIndex = text.lastIndexOf('<origintext>', selection.baseOffset);
    if (startTagIndex == -1) return null;
    
    // 查找光标之后最近的</origintext>标签
    int endTagIndex = text.indexOf('</origintext>', selection.baseOffset);
    if (endTagIndex == -1) return null;
    
    // 确保这对标签是匹配的（中间没有其他未闭合的<origintext>标签）
    int nestedCount = 0;
    int searchStart = startTagIndex + 11;
    while (searchStart < selection.baseOffset) {
      int nextStart = text.indexOf('<origintext>', searchStart);
      int nextEnd = text.indexOf('</origintext>', searchStart);
      
      if (nextStart == -1 || (nextEnd != -1 && nextEnd < nextStart)) {
        if (nextEnd != -1 && nextEnd < selection.baseOffset) {
          nestedCount--;
          searchStart = nextEnd + 13;
        } else {
          break;
        }
      } else if (nextStart != -1 && nextStart < selection.baseOffset) {
        nestedCount++;
        searchStart = nextStart + 11;
      } else {
        break;
      }
    }
    
    // 如果嵌套计数为0，说明光标位于有效的原文标签对内
    if (nestedCount == 0) {
      return _AiTagRange(startTagIndex, endTagIndex + 13);
    }
    
    return null;
  }
  
  /// 删除AI标签（并且如果存在嵌套的原文标签，也一并删除）
  static String _removeAiTag(String text, int aiStart, int aiEnd, TextSelection selection) {
    // 获取整个文本段
    String fullText = text.substring(aiStart, aiEnd);
    // 直接使用正则表达式删除所有标签
    String contentOnly = fullText
        .replaceFirst('<ai>', '')
        .replaceFirst('</ai>', '')
        .replaceAll('<origintext>', '')
        .replaceAll('</origintext>', '');
    
    // 返回完全处理后的文本
    return text.substring(0, aiStart) + contentOnly + text.substring(aiEnd);
  }
  
  /// 删除原文标签（保留外层AI标签）
  static String _removeOriginTextTag(String text, int originStart, int originEnd, TextSelection selection) {
    // 检查标签边界
    final String openTag = '<origintext>';
    final String closeTag = '</origintext>';
    
    // 确保我们真的在处理origintext标签
    if (text.substring(originStart, originStart + openTag.length) == openTag &&
        text.substring(originEnd - closeTag.length, originEnd) == closeTag) {
      
      // 提取标签内的内容
      String content = text.substring(originStart + openTag.length, originEnd - closeTag.length);
      
      // 替换整个标签
      return text.substring(0, originStart) + content + text.substring(originEnd);
    }
    
    // 如果标签不匹配，返回原文本
    return text;
  }
  
  /// 在AI标签内的选中文本前后添加原文标签
  static String _addOriginTextTagToSelection(String text, int selectionStart, int selectionEnd) {
    return text.substring(0, selectionStart) + 
           '<origintext>' + 
           text.substring(selectionStart, selectionEnd) + 
           '</origintext>' + 
           text.substring(selectionEnd);
  }

  /// 创建标签操作按钮
  static List<Widget> buildTagActionButtons(
    BuildContext context,
    TextEditingController controller,
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

/// 用于表示标签范围的帮助类
class _AiTagRange {
  final int start;
  final int end;
  
  _AiTagRange(this.start, this.end);
}