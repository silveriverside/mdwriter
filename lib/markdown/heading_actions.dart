import 'package:flutter/material.dart';
import 'markdown_parser.dart';
import 'styled_text_controller.dart';

/// 标题操作按钮组件
class HeadingActions extends StatelessWidget {
  final String currentLine;
  final Function(String) onLineChanged;
  final VoidCallback onPromoteHeading;
  final VoidCallback onDemoteHeading;
  final VoidCallback onToggleHeading;
  final VoidCallback onAdjustSubheadings;

  const HeadingActions({
    super.key,
    required this.currentLine,
    required this.onLineChanged,
    required this.onPromoteHeading,
    required this.onDemoteHeading,
    required this.onToggleHeading,
    required this.onAdjustSubheadings,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.arrow_upward),
          tooltip: '提升标题级别',
          onPressed: () {
            final newLine = MarkdownParser.promoteHeading(currentLine);
            onLineChanged(newLine);
            onPromoteHeading();
          },
        ),
        IconButton(
          icon: const Icon(Icons.arrow_downward),
          tooltip: '降低标题级别',
          onPressed: () {
            final newLine = MarkdownParser.demoteHeading(currentLine);
            onLineChanged(newLine);
            onDemoteHeading();
          },
        ),
        IconButton(
          icon: const Icon(Icons.format_clear),
          tooltip: '切换标题/正文',
          onPressed: () {
            final newLine = MarkdownParser.toggleHeading(currentLine);
            onLineChanged(newLine);
            onToggleHeading();
          },
        ),
        IconButton(
          icon: const Icon(Icons.format_indent_increase),
          tooltip: '批量调整子标题',
          onPressed: onAdjustSubheadings,
        ),
      ],
    );
  }
}