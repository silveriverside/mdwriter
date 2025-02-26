import 'package:flutter/material.dart';

/// 表示Markdown文档中的标题节点
class HeadingNode {
  /// 标题文本
  final String text;

  /// 标题级别 (1-6)
  final int level;

  /// 在原文档中的行号
  final int lineNumber;

  /// 子标题
  List<HeadingNode> children;

  /// 是否展开显示子节点
  bool isExpanded;

  HeadingNode({
    required this.text,
    required this.level,
    required this.lineNumber,
    List<HeadingNode>? children,
    this.isExpanded = true,
  }) : children = children ?? [];

  /// 添加子节点
  void addChild(HeadingNode child) {
    children.add(child);
  }

  /// 深度复制节点
  HeadingNode copyWith({
    String? text,
    int? level,
    int? lineNumber,
    List<HeadingNode>? children,
    bool? isExpanded,
  }) {
    return HeadingNode(
      text: text ?? this.text,
      level: level ?? this.level,
      lineNumber: lineNumber ?? this.lineNumber,
      children: children ?? List.from(this.children),
      isExpanded: isExpanded ?? this.isExpanded,
    );
  }

  @override
  String toString() {
    return '${'#' * level} $text (行: $lineNumber)';
  }
}

/// 表示整个Markdown文档的标题树
class HeadingTree {
  /// 根节点列表
  List<HeadingNode> roots;

  /// 所有标题节点的平铺列表（按行号排序）
  List<HeadingNode> _allNodes = [];

  HeadingTree({List<HeadingNode>? roots}) : roots = roots ?? [];

  /// 获取所有标题节点的平铺列表
  List<HeadingNode> get allNodes {
    if (_allNodes.isEmpty && roots.isNotEmpty) {
      _buildAllNodesList();
    }
    return _allNodes;
  }

  /// 构建所有节点的平铺列表
  void _buildAllNodesList() {
    _allNodes = [];
    for (var root in roots) {
      _addNodeAndChildren(root);
    }
    _allNodes.sort((a, b) => a.lineNumber.compareTo(b.lineNumber));
  }

  /// 递归添加节点及其子节点到平铺列表
  void _addNodeAndChildren(HeadingNode node) {
    _allNodes.add(node);
    for (var child in node.children) {
      _addNodeAndChildren(child);
    }
  }

  /// 根据行号查找最近的标题节点
  HeadingNode? findNodeByLineNumber(int lineNumber) {
    if (allNodes.isEmpty) return null;
    
    // 二分查找最接近但不超过给定行号的节点
    int low = 0;
    int high = allNodes.length - 1;
    
    while (low <= high) {
      int mid = (low + high) ~/ 2;
      if (allNodes[mid].lineNumber > lineNumber) {
        high = mid - 1;
      } else {
        low = mid + 1;
      }
    }
    
    return high >= 0 ? allNodes[high] : null;
  }

  /// 清空树
  void clear() {
    roots.clear();
    _allNodes.clear();
  }
}