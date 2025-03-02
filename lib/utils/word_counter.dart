class WordCounter {
  /// 计算文本总字数
  static int countWords(String text) {
    if (text.isEmpty) return 0;
    
    // 去除标签后计算字数
    String cleanText = text
        .replaceAll(RegExp(r'<ai>|</ai>|<origintext>|</origintext>'), '')
        .trim();
    
    // 中英文混合字数统计
    // 英文按空格分词，中文每个字符算一个词
    List<String> words = cleanText.split(RegExp(r'\s+'));
    int wordCount = 0;
    
    for (String word in words) {
      if (word.isEmpty) continue;
      
      // 中文字符计数
      int chineseChars = RegExp(r'[\u4e00-\u9fa5]').allMatches(word).length;
      // 其他字符按一个单词计算
      int otherChars = word.length - chineseChars;
      
      wordCount += chineseChars + (otherChars > 0 ? 1 : 0);
    }
    
    return wordCount;
  }
  
  /// 获取标题层级
  static int getHeadingLevel(String line) {
    final match = RegExp(r'^(#{1,6})\s').firstMatch(line);
    return match != null ? match.group(1)!.length : 0;
  }
  
  /// 获取当前标题所在段落（包含子标题）的字数
  static int countSectionWords(String text, int cursorPosition) {
    final lines = text.split('\n');
    int currentLine = 0;
    int charCount = 0;
    
    // 找到光标所在行
    for (int i = 0; i < lines.length; i++) {
      charCount += lines[i].length + 1; // +1 是换行符
      if (charCount > cursorPosition) {
        currentLine = i;
        break;
      }
    }
    
    // 检查当前行是否是标题
    String currentLineText = lines[currentLine];
    int headingLevel = getHeadingLevel(currentLineText);
    
    if (headingLevel == 0) {
      // 不是标题行，返回总字数
      return countWords(text);
    }
    
    // 查找该标题的范围（到下一个同级或更高级标题之前）
    int startLine = currentLine;
    int endLine = lines.length - 1;
    
    for (int i = currentLine + 1; i < lines.length; i++) {
      int level = getHeadingLevel(lines[i]);
      if (level > 0 && level <= headingLevel) {
        endLine = i - 1;
        break;
      }
    }
    
    // 提取此部分文本
    String sectionText = lines.sublist(startLine, endLine + 1).join('\n');
    return countWords(sectionText);
  }
} 