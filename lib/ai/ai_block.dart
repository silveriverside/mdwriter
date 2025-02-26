/// AI 块的数据结构，用于存储和处理 AI 相关的文本块
class AiBlock {
  /// 原始的完整文本（包含标签）
  final String originalText;
  
  /// 起始位置
  final int start;
  
  /// 结束位置
  final int end;
  
  /// 用户指令（除去原文部分的其他文本）
  final String instruction;
  
  /// 原文内容（如果有的话）
  final String? originalContent;
  
  /// AI 生成的结果
  String? aiResult;

  AiBlock({
    required this.originalText,
    required this.start,
    required this.end,
    required this.instruction,
    this.originalContent,
    this.aiResult,
  });

  /// 创建替换后的文本
  String createReplacementText() {
    if (aiResult == null) return originalText;
    // 保持原有的换行格式
    final lines = aiResult!.split('\n');
    final formattedResult = lines.map((line) => line.trim()).join('\n');
    return '<ai>$formattedResult</ai>';
  }

  /// 从文本范围创建 AI 块
  static AiBlock? fromTextRange(String text, int start, int end) {
    if (start < 0 || end > text.length || start >= end) return null;

    final blockText = text.substring(start, end);
    final originalTextMatch = RegExp(r'<origintext>(.*?)</origintext>', dotAll: true)
        .firstMatch(blockText);

    String instruction;
    String? originalContent;

    if (originalTextMatch != null) {
      originalContent = originalTextMatch.group(1);
      // 移除原文部分，剩下的就是指令
      instruction = blockText
          .replaceAll(originalTextMatch.group(0)!, '')
          .replaceAll(RegExp(r'<ai>|</ai>'), '')
          .trim();
    } else {
      instruction = blockText
          .replaceAll(RegExp(r'<ai>|</ai>'), '')
          .trim();
    }

    return AiBlock(
      originalText: blockText,
      start: start,
      end: end,
      instruction: instruction,
      originalContent: originalContent,
    );
  }
}