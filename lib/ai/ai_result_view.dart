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
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            child: const Row(
              children: [
                Icon(Icons.auto_awesome),
                SizedBox(width: 8),
                Text('AI 生成结果'),
              ],
            ),
          ),
          // 错误信息显示
          if (aiState.error != null)
            Container(
              padding: const EdgeInsets.all(16.0),
              margin: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8.0),
                border: Border.all(color: Colors.red.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.red),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      aiState.error!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              ),
            ),
          // 结果列表
          Expanded(
            child: ListView.builder(
              itemCount: widget.blocks.length,
              itemBuilder: (context, index) {
                final block = widget.blocks[index];
                return _buildResultCard(context, block, index);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultCard(BuildContext context, AiBlock block, int index) {
    final isEditing = _editingStates[index] ?? false;
    final controller = _getController(index, block.aiResult);

    return Card(
      margin: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题栏
          Container(
            padding: const EdgeInsets.all(8.0),
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            child: Row(
              children: [
                Text('块 #${index + 1}'),
                const Spacer(),
                if (block.aiResult != null)
                  if (isEditing)
                    Row(
                      children: [
                        TextButton.icon(
                          icon: const Icon(Icons.save),
                          label: const Text('保存'),
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
                          icon: const Icon(Icons.cancel),
                          label: const Text('取消'),
                          onPressed: () {
                            setState(() {
                              _editingStates[index] = false;
                              // 恢复原始内容
                              controller.text = block.aiResult ?? '';
                            });
                          },
                        ),
                      ],
                    )
                  else
                    Row(
                      children: [
                        TextButton.icon(
                          icon: const Icon(Icons.edit),
                          label: const Text('编辑'),
                          onPressed: () {
                            setState(() {
                              _editingStates[index] = true;
                            });
                          },
                        ),
                        TextButton.icon(
                          icon: const Icon(Icons.sync_alt),
                          label: const Text('替换'),
                          onPressed: () => widget.onReplace(block),
                        ),
                      ],
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
                  const Text(
                    '原文:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Container(
                    padding: const EdgeInsets.all(8.0),
                    color: Colors.grey.withOpacity(0.1),
                    child: Text(block.originalContent!),
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
                    color: Colors.yellow.withOpacity(0.1),
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
                            code: const TextStyle(
                              backgroundColor: Color(0xFFEEEEEE),
                              fontFamily: 'monospace',
                              fontSize: 13.0,
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
}
