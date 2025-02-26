import 'heading_tree.dart';

/// Markdown解析器，用于解析文本并生成标题树
class MarkdownParser {
  /// AI标签正则表达式
  static final RegExp aiTagRegex = RegExp(r'<ai>(.*?)</ai>', dotAll: true);
  
  /// 原文标签正则表达式
  static final RegExp originTextRegex = RegExp(r'<origintext>(.*?)</origintext>', dotAll: true);

  /// 解析Markdown文本，提取标题并构建标题树
  static HeadingTree parseHeadings(String text) {
    final List<HeadingNode> roots = [];
    final List<String> lines = text.split('\n');
    final List<HeadingNode> stack = [];

    for (int i = 0; i < lines.length; i++) {
      final String line = lines[i].trim();
      final RegExp headingRegex = RegExp(r'^(#{1,6})\s+(.+)$');
      final match = headingRegex.firstMatch(line);

      if (match != null) {
        final int level = match.group(1)!.length;
        final String headingText = match.group(2)!.trim();
        final HeadingNode node = HeadingNode(
          text: headingText,
          level: level,
          lineNumber: i,
          children: [], // 显式创建一个新的可修改列表
        );

        // 清空栈中级别大于或等于当前标题的节点
        while (stack.isNotEmpty && stack.last.level >= level) {
          stack.removeLast();
        }

        if (stack.isEmpty) {
          // 如果栈为空，则将当前节点添加到根节点列表
          roots.add(node);
        } else {
          // 否则将当前节点添加为栈顶节点的子节点
          stack.last.children.add(node);
        }

        // 将当前节点压入栈
        stack.add(node);
      }
    }

    return HeadingTree(roots: roots);
  }

  /// 获取指定行的标题级别
  static int getHeadingLevel(String line) {
    final RegExp headingRegex = RegExp(r'^(#{1,6})\s+.+$');
    final match = headingRegex.firstMatch(line.trim());

    if (match != null) {
      return match.group(1)!.length;
    }

    return 0; // 不是标题
  }

  /// 修改标题级别
  static String changeHeadingLevel(String line, int newLevel) {
    if (newLevel < 0 || newLevel > 6) {
      return line; // 级别无效，不做修改
    }

    final String trimmedLine = line.trim();
    final RegExp headingRegex = RegExp(r'^(#{1,6})\s+(.+)$');
    final match = headingRegex.firstMatch(trimmedLine);

    if (match != null) {
      // 当前是标题
      final String headingText = match.group(2)!;

      if (newLevel == 0) {
        // 转换为普通文本
        return headingText;
      } else {
        // 修改标题级别
        return '${'#' * newLevel} $headingText';
      }
    } else if (newLevel > 0) {
      // 当前不是标题，但要转换为标题
      return '${'#' * newLevel} $trimmedLine';
    }

    return line; // 不做修改
  }

  /// 提升标题级别（减少#号）
  static String promoteHeading(String line) {
    final int currentLevel = getHeadingLevel(line);
    if (currentLevel > 1) {
      return changeHeadingLevel(line, currentLevel - 1);
    }
    return line;
  }

  /// 降低标题级别（增加#号）
  static String demoteHeading(String line) {
    final int currentLevel = getHeadingLevel(line);
    if (currentLevel > 0 && currentLevel < 6) {
      return changeHeadingLevel(line, currentLevel + 1);
    } else if (currentLevel == 0) {
      // 如果不是标题，转换为一级标题
      return changeHeadingLevel(line, 1);
    }
    return line;
  }

  /// 切换标题/正文模式
  static String toggleHeading(String line) {
    final int currentLevel = getHeadingLevel(line);
    if (currentLevel > 0) {
      // 如果是标题，转换为正文
      return changeHeadingLevel(line, 0);
    } else {
      // 如果是正文，转换为一级标题
      return changeHeadingLevel(line, 1);
    }
  }

  /// 获取当前行所在的标题块
  static int getHeadingBlockRange(List<String> lines, int currentLine) {
    if (currentLine < 0 || currentLine >= lines.length) {
      return -1;
    }

    final int currentLevel = getHeadingLevel(lines[currentLine]);
    if (currentLevel == 0) {
      return -1; // 不是标题
    }

    // 查找下一个相同或更高级别的标题
    for (int i = currentLine + 1; i < lines.length; i++) {
      final int level = getHeadingLevel(lines[i]);
      if (level > 0 && level <= currentLevel) {
        return i - 1; // 返回块的结束行
      }
    }

    return lines.length - 1; // 到文档末尾
  }

  /// 批量调整子标题级别
  static List<String> adjustSubheadings(
    List<String> lines,
    int startLine,
    int endLine,
    int levelChange
  ) {
    if (startLine < 0 || endLine >= lines.length || startLine > endLine || levelChange == 0) {
      return lines;
    }

    final List<String> result = List.from(lines);
    final int baseLevel = getHeadingLevel(lines[startLine]);

    if (baseLevel == 0) {
      return lines; // 起始行不是标题
    }

    // 调整起始标题
    result[startLine] = changeHeadingLevel(lines[startLine], baseLevel + levelChange);

    // 调整子标题
    for (int i = startLine + 1; i <= endLine; i++) {
      final int level = getHeadingLevel(lines[i]);
      if (level > baseLevel) {
        // 只调整级别比基准标题低的标题
        final int newLevel = level + levelChange;
        if (newLevel > 0 && newLevel <= 6) {
          result[i] = changeHeadingLevel(lines[i], newLevel);
        }
      } else if (level > 0 && level <= baseLevel) {
        // 遇到同级或更高级别的标题，停止处理
        break;
      }
    }

    return result;
  }

  /// 在选中文本两侧插入AI标签
  static String insertAiTagAroundSelection(String text, int start, int end) {
    if (start < 0 || end > text.length || start >= end) {
      return text;
    }
    return '${text.substring(0, start)}<ai>${text.substring(start, end)}</ai>${text.substring(end)}';
  }

  /// 在光标位置插入AI标签对
  static String insertAiTagAtCursor(String text, int cursorPosition) {
    if (cursorPosition < 0 || cursorPosition > text.length) {
      return text;
    }
    return '${text.substring(0, cursorPosition)}<ai></ai>${text.substring(cursorPosition)}';
  }

  /// 在选中文本外包裹AI和原文标签
  static String wrapWithAiAndOriginTextTag(String text, int start, int end) {
    if (start < 0 || end > text.length || start >= end) {
      return text;
    }
    return '${text.substring(0, start)}<ai><origintext>${text.substring(start, end)}</origintext></ai>${text.substring(end)}';
  }

  /// 在光标位置插入原文标签对
  static String insertOriginTextTagAtCursor(String text, int cursorPosition) {
    if (cursorPosition < 0 || cursorPosition > text.length) {
      return text;
    }
    return '${text.substring(0, cursorPosition)}<origintext></origintext>${text.substring(cursorPosition)}';
  }

  /// 检查文本是否包含AI标签
  static bool containsAiTag(String text) {
    return aiTagRegex.hasMatch(text);
  }

  /// 检查文本是否包含原文标签
  static bool containsOriginTextTag(String text) {
    return originTextRegex.hasMatch(text);
  }

  /// 获取所有AI标签的范围
  static List<({int start, int end})> getAiTagRanges(String text) {
    final List<({int start, int end})> ranges = [];
    for (final match in aiTagRegex.allMatches(text)) {
      ranges.add((start: match.start, end: match.end));
    }
    return ranges;
  }

  /// 获取所有原文标签的范围
  static List<({int start, int end})> getOriginTextTagRanges(String text) {
    final List<({int start, int end})> ranges = [];
    for (final match in originTextRegex.allMatches(text)) {
      ranges.add((start: match.start, end: match.end));
    }
    return ranges;
  }
}