import 'package:flutter/material.dart';import 'package:flutter/services.dart';import 'package:provider/provider.dart';
import 'file_manager/recent_files_provider.dart';import 'file_manager/file_manager.dart';
import 'markdown/heading_tree.dart';import 'markdown/markdown_parser.dart';import 'markdown/outline_view.dart';
import 'markdown/styled_text_controller.dart';import 'markdown/adjust_subheadings_dialog.dart';import 'ai/ai_state.dart';import 'ai/ai_result_view.dart';
import 'ai/model_config.dart';
void main() {  runApp(const MyApp());}
class MyApp extends StatelessWidget {  const MyApp({super.key});
  @override  Widget build(BuildContext context) {    return MultiProvider(      providers: [        ChangeNotifierProvider(create: (_) => RecentFilesProvider()),        ChangeNotifierProvider(create: (_) => ModelConfigProvider()),        ChangeNotifierProvider(create: (_) => AiState()),
      ],      child: Builder(        builder: (context) {
          // 初始化时加载模型配置          final configProvider = context.read<ModelConfigProvider>();          final aiState = context.read<AiState>();
          configProvider.loadConfig().then((_) {            if (configProvider.config != null) {              aiState.setModelConfig(configProvider.config!);
            }          });
          return MaterialApp(            title: 'MDWriter',            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
              brightness: Brightness.light,              primaryColor: Colors.deepPurple,              primarySwatch: Colors.deepPurple,              useMaterial3: true,            ),
            home: const HomePage(title: 'MDWriter'),          );
        },      ),    );
  }}
class HomePage extends StatefulWidget {  const HomePage({super.key, required this.title});
  final String title;
  @override  State<HomePage> createState() => _HomePageState();}
class _HomePageState extends State<HomePage> {  String _currentFilePath = '';  late final StyledTextEditingController _textController;  final FocusNode _focusNode = FocusNode();  // 当前光标位置  int _currentLine = 0;
  // 标题树
  HeadingTree _headingTree = HeadingTree(roots: []);  // 是否显示大纲视图  final bool _showOutline = true; // 默认显示大纲视图
  // 是否显示AI结果视图  final bool _showAiResultView = true;

  @override  void initState() {
    super.initState();    // 初始化文本控制器，传入AI处理回调    _textController = StyledTextEditingController(
      onAiProcess: () {        final aiState = context.read<AiState>();        if (!aiState.isProcessing) {          aiState.processText(_textController.text);        }      },    );    _textController.addListener(_onTextChanged);  }

  void _onTextChanged() {    // 当文本变化时，重新解析Markdown    _parseMarkdown();    // 更新当前行
    _updateCurrentLineFromCursor();  }

  // 从光标位置更新当前行  void _updateCurrentLineFromCursor() {    final text = _textController.text;    if (text.isEmpty) {      setState(() {        _currentLine = 0;      });      return;    }
    final selection = _textController.selection;    if (!selection.isValid) return;
    final cursorPosition = selection.baseOffset;    final textBeforeCursor = text.substring(0, cursorPosition);
    final linesBefore = '\n'.allMatches(textBeforeCursor).length;
    setState(() {
      _currentLine = linesBefore;
    });  }
  // 获取当前行文本  String _getCurrentLineText() {    final lines = _textController.text.split('\n');    if (_currentLine >= 0 && _currentLine < lines.length) {      return lines[_currentLine];    }    return '';  }
  // 解析Markdown文本并生成标题树  void _parseMarkdown() {    setState(() {      _headingTree = MarkdownParser.parseHeadings(_textController.text);    });  }
  @override  void dispose() {    _textController.removeListener(_onTextChanged);    _textController.dispose();
    _focusNode.dispose();    super.dispose();  }
  // 显示模型配置对话框  void _showModelConfigDialog() {    showDialog(      context: context,      builder: (context) {        final configProvider = context.read<ModelConfigProvider>();        final currentConfig = configProvider.config;
        final baseUrlController = TextEditingController(          text: currentConfig?.baseUrl ?? '',        );        final apiKeyController = TextEditingController(
          text: currentConfig?.apiKey ?? '',        );        final modelController = TextEditingController(          text: currentConfig?.model ?? '',        );
        return AlertDialog(          title: const Text('模型配置'),          content: Column(            mainAxisSize: MainAxisSize.min,            children: [
              TextField(                controller: baseUrlController,                decoration: const InputDecoration(
                  labelText: 'Base URL',
                  hintText: 'https://api.example.com/v1',                ),              ),              const SizedBox(height: 8),
              TextField(                controller: apiKeyController,                decoration: const InputDecoration(
                  labelText: 'API Key',                ),                obscureText: true,              ),              const SizedBox(height: 8),              TextField(
                controller: modelController,                decoration: const InputDecoration(                  labelText: 'Model',                  hintText: 'gpt-3.5-turbo',                ),
              ),            ],          ),          actions: [            TextButton(              onPressed: () => Navigator.pop(context),              child: const Text('取消'),            ),            TextButton(
              onPressed: () {                final config = ModelConfig(                  baseUrl: baseUrlController.text,                  apiKey: apiKeyController.text,                  model: modelController.text,                );                configProvider.saveConfig(config);
                // 保存配置后立即更新AI状态                context.read<AiState>().setModelConfig(config);                Navigator.pop(context);              },              child: const Text('保存'),            ),          ],        );      },    );
  }
  // 保存文件  Future<void> _saveFile() async {    if (_currentFilePath.isEmpty) return;    await FileManager.saveFile(_currentFilePath, _textController.text);
  }
  // 打开文件  Future<void> _openFile() async {    final result = await FileManager.openFile(context);    if (result != null) {      setState(() {        _currentFilePath = result.path;        _textController.text = result.content;      });

      // 添加到最近文件列表      if (mounted) {        Provider.of<RecentFilesProvider>(context, listen: false)            .addRecentFile(result.path);      }
    }  }
  // 创建新文件
  Future<void> _createNewFile() async {    final file = await FileManager.createFile('new_document.md');    setState(() {      _currentFilePath = file.path;      _textController.text = '';    });
    if (mounted) {      Provider.of<RecentFilesProvider>(context, listen: false)          .addRecentFile(file.path);    }  }

  // 更新当前行
  void _updateCurrentLine(String newLine) {    final lines = _textController.text.split('\n');    if (_currentLine >= 0 && _currentLine < lines.length) {      lines[_currentLine] = newLine;      setState(() {        _textController.text = lines.join('\n');      });
    }  }
  // 跳转到指定行  void _jumpToLine(int line) {    final lines = _textController.text.split('\n');    if (line >= 0 && line < lines.length) {
      int offset = 0;

      for (int i = 0; i < line; i++) {
        offset += lines[i].length + 1; // +1 for newline character      }
      _textController.selection = TextSelection.fromPosition(        TextPosition(offset: offset),      );
      setState(() {
        _currentLine = line;      });

      _focusNode.requestFocus();    }  }
  // 处理键盘事件
  bool _handleRawKeyEvent(RawKeyEvent event) {    if (event is RawKeyDownEvent && event.logicalKey == LogicalKeyboardKey.tab) {      return _textController.handleKeyEvent(event);
    }    return false;  }

  @override  Widget build(BuildContext context) {    final aiState = context.watch<AiState>();

    return Scaffold(      appBar: AppBar(        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
        actions: [          IconButton(
            icon: const Icon(Icons.settings),            onPressed: _showModelConfigDialog,            tooltip: '模型配置',          ),          IconButton(            icon: const Icon(Icons.save),            onPressed: _currentFilePath.isNotEmpty ? _saveFile : null,            tooltip: '保存文件',          ),          IconButton(            icon: const Icon(Icons.folder_open),            onPressed: _openFile,            tooltip: '打开文件',          ),
          IconButton(            icon: const Icon(Icons.create_new_folder),            onPressed: _createNewFile,            tooltip: '新建文件',          ),        ],
      ),      body: Column(
        children: [          Expanded(
            child: Row(              crossAxisAlignment: CrossAxisAlignment.start,
              children: [                // 大纲视图
                if (_showOutline)                  Expanded(                    flex: 1,                    child: OutlineView(                      headingTree: _headingTree,                      onHeadingTap: _jumpToLine,
                      currentLine: _currentLine,
                    ),                  ),                // 编辑器                Expanded(                  flex: 3,
                  child: Padding(                    padding: const EdgeInsets.all(8.0),                    child: RawKeyboardListener(                      focusNode: _focusNode,                      onKey: (RawKeyEvent event) {
                        if (_handleRawKeyEvent(event)) {                          // 如果事件被处理，阻止事件继续传播                          return;                        }                      },
                      child: TextField(                        controller: _textController,                        focusNode: _focusNode,                        maxLines: null,                        expands: true,                        decoration: InputDecoration(                          hintText: '在这里输入或编辑文本...',                          border: OutlineInputBorder(                            borderRadius: BorderRadius.circular(8.0),
                          ),                          filled: true,
                          fillColor: Colors.white,
                        ),                        style: const TextStyle(                          fontSize: 16.0,                          fontFamily: 'monospace',                        ),                      ),                    ),                  ),
                ),                // AI 结果视图                if (_showAiResultView && aiState.blocks.isNotEmpty)                  Expanded(                    flex: 3,                    child: AiResultView(                      blocks: aiState.blocks,                      onReplace: (block) {                        final newText = aiState.replaceBlock(
                          _textController.text,
                          block,                        );
                        if (newText != _textController.text) {                          setState(() {
                            _textController.text = newText;                          });                        }
                      },                    ),                  ),              ],            ),          ),
          if (_currentFilePath.isNotEmpty)            Padding(              padding: const EdgeInsets.all(8.0),              child: Text(                '当前文件: $_currentFilePath',                style: const TextStyle(fontSize: 12.0),                overflow: TextOverflow.ellipsis,              ),            ),        ],      ),
    );  }}
