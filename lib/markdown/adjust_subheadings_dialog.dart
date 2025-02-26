import 'package:flutter/material.dart';

/// 批量调整子标题对话框
class AdjustSubheadingsDialog extends StatelessWidget {
  final String currentLine;
  final Function(String) onConfirm;

  const AdjustSubheadingsDialog({
    super.key,
    required this.currentLine,
    required this.onConfirm,
  });

  void _adjustHeadingLevel(int delta) {
    if (currentLine.trim().startsWith('#')) {
      final parts = currentLine.split(' ');
      final currentLevel = parts[0].length;
      final newLevel = (currentLevel + delta).clamp(1, 6);
      
      if (newLevel != currentLevel) {
        final newHeading = '${'#' * newLevel} ${parts.sublist(1).join(' ')}';
        onConfirm(newHeading);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('调整子标题级别'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.arrow_upward),
            title: const Text('提升一级'),
            onTap: () {
              _adjustHeadingLevel(-1);
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.arrow_downward),
            title: const Text('降低一级'),
            onTap: () {
              _adjustHeadingLevel(1);
              Navigator.pop(context);
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
      ],
    );
  }
}