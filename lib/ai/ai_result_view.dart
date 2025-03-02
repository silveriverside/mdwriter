import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'ai_block.dart';
import 'ai_state.dart';

/// AI 结果显示组件
class AiResultView extends StatefulWidget {
  final List<AiBlock> blocks;
  final Function(AiBlock) onReplace;
  final double width;

  const AiResultView({
    super.key,
    required this.blocks,
    required this.onReplace,
    this.width = 300,
  });

  @override
  State<AiResultView> createState() => _AiResultViewState();
}

class _AiResultViewState extends State<AiResultView> {
  // 存储每个块的编辑状态和编辑器控制器
  final Map<int, bool> _editingStates = {};
  final Map<int, TextEditingController> _editControllers = {};
  // 存储每个块的原始文本折叠状态
  final Map<int, bool> _collapsedStates = {};

  @override
  void dispose() {
    // 清理所有文本编辑器控制器
    for (var controller in _editControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  // 获取或创建文本编辑器控制器
  TextEditingController _getController(int blockIndex, String? initialText) {
    if (!_editControllers.containsKey(blockIndex)) {
      _editControllers[blockIndex] = TextEditingController(text: initialText ?? '');
    }
    return _editControllers[blockIndex]!;
  }

  @override
  Widget build(BuildContext context) {
    final aiState = context.watch<AiState>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: widget.width,
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(
            color: Theme.of(context).dividerColor,
          ),
        ),
      ),
      child: Column(
        children: [
          // 标题栏
          Container(
            padding: const EdgeInsets.all(8.0),
            color: isDark 
                ? const Color(0xFF332200).withOpacity(0.3) // 深棕色，无蓝色
                : Theme.of(context).primaryColor.withOpacity(0.1),
            child: const Row(
              children: [
                Icon(Icons.auto_awesome),
                SizedBox(width: 8),
                Text('AI 生成结果'),
              ],
            ),
          ),
          // 内容区域
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // 错误信息显示
                  if (aiState.error != null)
                    Container(
                      padding: const EdgeInsets.all(16.0),
                      margin: const EdgeInsets.all(8.0),
                      decoration: BoxDecoration(
                        color: isDark 
                            ? const Color(0xFF330000).withOpacity(0.3)
                            : Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8.0),
                        border: Border.all(
                          color: isDark 
                              ? const Color(0xFF550000).withOpacity(0.3)
                              : Colors.red.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.error_outline, 
                            color: isDark ? const Color(0xFFFF3300) : Colors.red,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              aiState.error!,
                              style: TextStyle(
                                color: isDark ? const Color(0xFFFF3300) : Colors.red,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  // AI 块列表
                  if (widget.blocks.isNotEmpty)
                    ...widget.blocks.asMap().entries.map((entry) {
                      return _buildResultCard(context, entry.value, entry.key);
                    }).toList(),
                  // 空状态提示
                  if (widget.blocks.isEmpty && aiState.error == null)
                    Container(
                      padding: const EdgeInsets.all(32.0),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.info_outline,
                              size: 48,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              '暂无 AI 处理结果',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '使用 <ai></ai> 标签标记需要处理的内容',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultCard(BuildContext context, AiBlock block, int index) {
    final isEditing = _editingStates[index] ?? false;
    final controller = _getController(index, block.aiResult);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      margin: const EdgeInsets.all(8.0),
      color: isDark ? Theme.of(context).colorScheme.surface : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题栏
          Container(
            padding: const EdgeInsets.all(8.0),
            color: isDark 
                ? const Color(0xFF332200).withOpacity(0.3) // 深棕色，无蓝色
                : Theme.of(context).primaryColor.withOpacity(0.1),
            child: Row(
              children: [
                Text('块 #${index + 1}'),
                const Spacer(),
                if (block.aiResult != null)
                  if (isEditing)
                    Flexible(
                      child: Wrap(
                        spacing: 4.0,
                        runSpacing: 4.0,
                        alignment: WrapAlignment.end,
                        children: [
                          TextButton.icon(
                            icon: const Icon(Icons.save, size: 16),
                            label: const Text('保存', style: TextStyle(fontSize: 12)),
                            onPressed: () {
                              setState(() {
                                _editingStates[index] = false;
                                // 更新block的结果并触发替换
                                block.aiResult = controller.text;
                                widget.onReplace(block);
                              });
                            },
                          ),
                          TextButton.icon(
                            icon: const Icon(Icons.cancel, size: 16),
                            label: const Text('取消', style: TextStyle(fontSize: 12)),
                            onPressed: () {
                              setState(() {
                                _editingStates[index] = false;
                                // 恢复原始内容
                                controller.text = block.aiResult ?? '';
                              });
                            },
                          ),
                        ],
                      ),
                    )
                  else
                    Flexible(
                      child: Wrap(
                        spacing: 4.0,
                        runSpacing: 4.0,
                        alignment: WrapAlignment.end,
                        children: [
                          TextButton.icon(
                            icon: const Icon(Icons.edit, size: 16),
                            label: const Text('编辑', style: TextStyle(fontSize: 12)),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                              foregroundColor: isDark 
                                  ? const Color(0xFFEAA500) // 黄橙色，无蓝色
                                  : null,
                            ),
                            onPressed: () {
                              setState(() {
                                _editingStates[index] = true;
                              });
                            },
                          ),
                          TextButton.icon(
                            icon: const Icon(Icons.sync_alt, size: 16),
                            label: const Text('替换', style: TextStyle(fontSize: 12)),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                              foregroundColor: isDark 
                                  ? const Color(0xFFFFAA00) // 亮橙色，无蓝色
                                  : null,
                            ),
                            onPressed: () => widget.onReplace(block),
                          ),
                        ],
                      ),
                    ),
              ],
            ),
          ),
          // 指令
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '指令:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(block.instruction),
              ],
            ),
          ),

          // 原文（如果有）
          if (block.originalContent != null)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        '原文:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const Spacer(),
                      // 添加展开/折叠按钮
                      TextButton.icon(
                        icon: Icon(
                          (_collapsedStates[index] ?? true) 
                              ? Icons.expand_more 
                              : Icons.expand_less,
                          size: 16,
                        ),
                        label: Text(
                          (_collapsedStates[index] ?? true) ? '展开' : '折叠',
                          style: const TextStyle(fontSize: 12),
                        ),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                        ),
                        onPressed: () {
                          setState(() {
                            // 切换折叠状态
                            _collapsedStates[index] = !(_collapsedStates[index] ?? true);
                          });
                        },
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.all(8.0),
                    color: isDark 
                        ? const Color(0xFF221100).withOpacity(0.3) // 深褐色，无蓝色
                        : Colors.grey.withOpacity(0.1),
                    child: Text(
                      // 根据折叠状态显示部分或全部内容
                      (_collapsedStates[index] ?? true)
                          ? _getFirstLineWithEllipsis(block.originalContent!)
                          : block.originalContent!,
                    ),
                  ),
                ],
              ),
            ),

          // AI 结果
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'AI 生成结果:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                if (block.aiResult != null)
                  Container(
                    padding: const EdgeInsets.all(8.0),
                    color: isDark 
                        ? const Color(0xFF332200).withOpacity(0.2) // 深黄褐色，无蓝色
                        : Colors.yellow.withOpacity(0.1),
                    child: isEditing
                      ? TextField(
                          controller: controller,
                          maxLines: null,
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                          style: const TextStyle(
                            fontSize: 14.0,
                            height: 1.5,
                          ),
                        )
                      : MarkdownBody(
                          data: block.aiResult!,
                          selectable: true,
                          styleSheet: MarkdownStyleSheet(
                            p: const TextStyle(fontSize: 14.0, height: 1.5),
                            h1: const TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold),
                            h2: const TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
                            h3: const TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
                            h4: const TextStyle(fontSize: 15.0, fontWeight: FontWeight.bold),
                            h5: const TextStyle(fontSize: 14.0, fontWeight: FontWeight.bold),
                            h6: const TextStyle(fontSize: 14.0, fontWeight: FontWeight.bold, fontStyle: FontStyle.italic),
                            code: TextStyle(
                              backgroundColor: isDark 
                                  ? const Color(0xFF221100) // 深褐色，无蓝色
                                  : const Color(0xFFEEEEEE),
                              fontFamily: 'monospace',
                              fontSize: 13.0,
                              color: isDark ? const Color(0xFFFFCC00) : null, // 暗模式下的代码文本颜色
                            ),
                            blockquote: const TextStyle(
                              color: Colors.grey,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                  )
                else
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: CircularProgressIndicator(),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 获取文本的第一行并添加省略号（如果需要）
  String _getFirstLineWithEllipsis(String text) {
    if (!text.contains('\n')) return text;
    
    final firstLine = text.split('\n').first;
    return '$firstLine${text.length > firstLine.length ? '...' : ''}';
  }
}
