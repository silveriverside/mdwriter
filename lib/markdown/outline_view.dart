import 'package:flutter/material.dart';
import 'heading_tree.dart';

/// 大纲视图组件，用于显示文档的标题结构
class OutlineView extends StatelessWidget {
  final HeadingTree headingTree;
  final int currentLine;
  final Function(int) onHeadingTap;

  const OutlineView({
    super.key,
    required this.headingTree,
    required this.currentLine,
    required this.onHeadingTap,
  });

  @override
  Widget build(BuildContext context) {
    // 获取当前主题
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    // 背景颜色 - 如果是暗色模式则使用主题的surface色调
    final backgroundColor = isDark 
        ? theme.colorScheme.surface 
        : Colors.grey[200];
    final textColor = theme.textTheme.bodyMedium?.color;
    
    // 高亮颜色 - 暗色模式下使用主色调的暗变体，不含蓝色
    final highlightColor = isDark
        ? theme.colorScheme.primaryContainer.withOpacity(0.4)
        : Colors.blue.withOpacity(0.2);
    
    return Container(
      color: backgroundColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 添加标题
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Text(
              '大纲视图',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: textColor,
                fontFamily: 'FangSong',
              ),
            ),
          ),
          // 添加分隔线
          Divider(color: theme.dividerColor),
          // 大纲内容
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(8.0),
              itemCount: headingTree.allNodes.length,
              itemBuilder: (context, index) {
                final node = headingTree.allNodes[index];
                final isSelected = node.lineNumber == currentLine;
                
                return InkWell(
                  onTap: () => onHeadingTap(node.lineNumber),
                  child: Container(
                    padding: EdgeInsets.only(
                      left: (node.level - 1) * 16.0 + 8.0,
                      top: 4.0,
                      bottom: 4.0,
                    ),
                    color: isSelected ? highlightColor : null,
                    child: Text(
                      node.text,
                      style: TextStyle(
                        fontSize: 14.0,
                        color: textColor,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// 可展开/折叠的大纲视图组件
class ExpandableOutlineView extends StatefulWidget {
  final HeadingTree headingTree;
  final int currentLine;
  final Function(int) onHeadingTap;

  const ExpandableOutlineView({
    super.key,
    required this.headingTree,
    required this.currentLine,
    required this.onHeadingTap,
  });

  @override
  State<ExpandableOutlineView> createState() => _ExpandableOutlineViewState();
}

class _ExpandableOutlineViewState extends State<ExpandableOutlineView> {
  late HeadingTree _tree;

  @override
  void initState() {
    super.initState();
    _tree = widget.headingTree;
  }

  @override
  void didUpdateWidget(ExpandableOutlineView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.headingTree != widget.headingTree) {
      _tree = widget.headingTree;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).brightness == Brightness.light 
          ? Colors.white 
          : Colors.grey[800],
      child: ListView(
        padding: const EdgeInsets.all(8.0),
        children: _buildHeadingList(_tree.roots),
      ),
    );
  }

  /// 构建标题列表
  List<Widget> _buildHeadingList(List<HeadingNode> nodes) {
    final List<Widget> widgets = [];

    for (var node in nodes) {
      // 检查当前节点是否是活动节点
      final bool isActive = _isNodeActive(node);

      widgets.add(
        InkWell(
          onTap: () => widget.onHeadingTap(node.lineNumber),
          child: Container(
            padding: EdgeInsets.only(
              left: (node.level - 1) * 16.0 + 8.0,
              top: 4.0,
              bottom: 4.0,
            ),
            decoration: BoxDecoration(
              color: isActive ? Colors.blue.withOpacity(0.2) : null,
              borderRadius: BorderRadius.circular(4.0),
            ),
            child: Row(
              children: [
                if (node.children.isNotEmpty)
                  IconButton(
                    icon: Icon(
                      node.isExpanded ? Icons.expand_more : Icons.chevron_right,
                      size: 16.0,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () {
                      setState(() {
                        // 切换展开/折叠状态
                        final index = _tree.allNodes.indexOf(node);
                        if (index >= 0) {
                          _tree.allNodes[index] = node.copyWith(
                            isExpanded: !node.isExpanded,
                          );
                        }
                      });
                    },
                  )
                else
                  const SizedBox(width: 16.0),
                const SizedBox(width: 4.0),
                Expanded(
                  child: Text(
                    node.text,
                    style: TextStyle(
                      fontSize: 14.0,
                      fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                      color: isActive ? Colors.blue : null,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      // 如果节点展开且有子节点，则递归构建子节点
      if (node.isExpanded && node.children.isNotEmpty) {
        widgets.addAll(_buildHeadingList(node.children));
      }
    }

    return widgets;
  }

  /// 检查节点是否是当前活动节点
  bool _isNodeActive(HeadingNode node) {
    // 找到当前行所属的标题节点
    final HeadingNode? activeNode = _tree.findNodeByLineNumber(widget.currentLine);
    return activeNode != null && activeNode.lineNumber == node.lineNumber;
  }
}