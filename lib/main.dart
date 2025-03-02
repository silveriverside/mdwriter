import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'theme/theme_mode_provider.dart';
import 'file_manager/recent_files_provider.dart';
import 'file_manager/file_manager.dart';
import 'markdown/heading_tree.dart';
import 'markdown/markdown_parser.dart';
import 'markdown/outline_view.dart';
import 'markdown/markdown_styled_controller.dart';
import 'markdown/styled_text_controller.dart';
import 'markdown/adjust_subheadings_dialog.dart';
import 'ai/ai_state.dart';
import 'ai/ai_result_view.dart';
import 'ai/model_config.dart';
import 'markdown/heading_actions.dart';
import 'markdown/tag_actions.dart';
import 'ai/model_config_dialog.dart';
import 'utils/word_counter.dart';
import 'widgets/resizable_panel_layout.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => RecentFilesProvider()),
        ChangeNotifierProvider(create: (_) => ModelConfigProvider()),
        ChangeNotifierProvider(create: (_) => AiState()),
        ChangeNotifierProvider(create: (_) => ThemeModeProvider()),
      ],
      child: Builder(
        builder: (context) {
          // 初始化时加载模型配置
          final configProvider = Provider.of<ModelConfigProvider>(context, listen: false);
          final themeProvider = Provider.of<ThemeModeProvider>(context, listen: true);
          final aiState = Provider.of<AiState>(context, listen: false);

          configProvider.loadConfig().then((_) {
            if (configProvider.config != null) {
              aiState.setModelConfig(configProvider.config!);
            }
          });

          return MaterialApp(
            title: 'MDWriter',
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: Colors.deepPurple,
                brightness: Brightness.light,
              ),
              brightness: Brightness.light,
              primaryColor: Colors.deepPurple,
              primarySwatch: Colors.deepPurple,
              useMaterial3: true,
              fontFamily: 'FangSong',
            ),
            darkTheme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFF993300), // 深红棕色种子，不含蓝色
                brightness: Brightness.dark,
                // 定制深色背景
                background: const Color(0xFF0A0A00), // 几乎黑色，无蓝色
                surface: const Color(0xFF121200),    // 深色表面，无蓝色
                onBackground: const Color(0xFFEAE0C0), // 浅黄色文本
                onSurface: const Color(0xFFDAD0A0),    // 浅黄色表面文本
              ),
              brightness: Brightness.dark,
              primaryColor: const Color(0xFF993300), // 深红棕色
              scaffoldBackgroundColor: const Color(0xFF050500), // 非常深的背景，无蓝色
              appBarTheme: const AppBarTheme(
                backgroundColor: Color(0xFF201A00), // 深色应用栏，无蓝色
                foregroundColor: Color(0xFFEAE0C0), // 浅黄色文本
              ),
              useMaterial3: true,
              fontFamily: 'FangSong',
            ),
            themeMode: themeProvider.themeMode,
            home: const HomePage(title: 'MDWriter'),
          );
        },
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.title});

  final String title;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  String _currentFilePath = '';
  late final StyledTextEditingController _textController;
  final FocusNode _textFieldFocusNode = FocusNode();
  final FocusNode _keyboardListenerFocusNode = FocusNode();
  // 当前光标位置
  int _currentLine = 0;
  // 标题树
  HeadingTree _headingTree = HeadingTree(roots: []);
  // 是否显示大纲视图
  bool _showOutline = true; // 默认显示大纲视图
  // 是否显示AI结果视图
  bool _showAiResultView = true;
  // 是否有未保存的更改
  bool _hasUnsavedChanges = false;
  // 上次保存的内容
  String _lastSavedContent = '';
  // 字数统计信息
  String _wordCountInfo = "0 字";
  double? _savedLeftPanelWidth;
  double? _savedMiddlePanelWidth;
  double? _savedRightPanelWidth;

  @override
  void initState() {
    // 添加应用生命周期观察者
    WidgetsBinding.instance.addObserver(this);
    super.initState();
    // 初始化文本控制器，传入AI处理回调
    _textController = StyledTextEditingController(
      onAiProcess: () {
        final aiState = Provider.of<AiState>(context, listen: false);
        if (!aiState.isProcessing) {
          aiState.processText(_textController.text);
        }
      },
    );
    _textController.addListener(_onTextChanged);
    
    // 初始化字数统计
    _updateWordCount();
    
    // 加载保存的面板宽度
    _loadPanelLayout();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // 当应用即将关闭时，检查是否有未保存的更改
    if (state == AppLifecycleState.paused && _hasUnsavedChanges) {
      _saveFile(); // 自动保存
    }
  }

  void _onTextChanged() {
    // 当文本变化时，重新解析Markdown
    _parseMarkdown();
    // 更新当前行
    _updateCurrentLineFromCursor();
    // 更新字数统计
    _updateWordCount();
    // 检查是否有未保存的更改
    setState(() {
      _hasUnsavedChanges = _textController.text != _lastSavedContent;
    });
  }

  // 从光标位置更新当前行
  void _updateCurrentLineFromCursor() {
    final text = _textController.text;
    if (text.isEmpty) {
      setState(() {
        _currentLine = 0;
      });
      _updateWordCount(); // 更新字数统计
      return;
    }
    final selection = _textController.selection;
    if (!selection.isValid) return;
    final cursorPosition = selection.baseOffset;
    final textBeforeCursor = text.substring(0, cursorPosition);
    final linesBefore = '\n'.allMatches(textBeforeCursor).length;

    setState(() {
      _currentLine = linesBefore;
    });
    _updateWordCount(); // 更新字数统计
  }

  // 获取当前行文本
  String _getCurrentLineText() {
    final lines = _textController.text.split('\n');
    if (_currentLine >= 0 && _currentLine < lines.length) {
      return lines[_currentLine];
    }
    return '';
  }

  // 解析Markdown文本并生成标题树
  void _parseMarkdown() {
    setState(() {
      _headingTree = MarkdownParser.parseHeadings(_textController.text);
    });
  }

  @override
  void dispose() {
    // 移除应用生命周期观察者
    WidgetsBinding.instance.removeObserver(this);
    _textController.removeListener(_onTextChanged);
    _textController.dispose();
    _textFieldFocusNode.dispose();
    _keyboardListenerFocusNode.dispose();
    super.dispose();
  }

  // 显示模型配置对话框
  void _showThemeSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) {
        final themeProvider = Provider.of<ThemeModeProvider>(context);
        
        return AlertDialog(
          title: const Text('主题设置'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile<ThemeMode>(
                title: const Text('跟随系统'),
                value: ThemeMode.system,
                groupValue: themeProvider.themeMode,
                onChanged: (ThemeMode? value) {
                  if (value != null) {
                    themeProvider.setThemeMode(value);
                  }
                },
              ),
              RadioListTile<ThemeMode>(
                title: const Text('浅色模式'),
                value: ThemeMode.light,
                groupValue: themeProvider.themeMode,
                onChanged: (ThemeMode? value) {
                  if (value != null) {
                    themeProvider.setThemeMode(value);
                  }
                },
              ),
              RadioListTile<ThemeMode>(
                title: const Text('深色模式'),
                value: ThemeMode.dark,
                groupValue: themeProvider.themeMode,
                onChanged: (ThemeMode? value) {
                  if (value != null) {
                    themeProvider.setThemeMode(value);
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              child: const Text('关闭'),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        );
      },
    );
  }

  // 显示模型配置对话框
  void _showModelConfigDialog() {
    showDialog(
      context: context,
      barrierDismissible: false, // 防止点击外部关闭对话框
      builder: (context) {
        return ModelConfigDialogWidget(
          configProvider: Provider.of<ModelConfigProvider>(context, listen: false),
          aiState: Provider.of<AiState>(context, listen: false),
        );
      },
    );
  }

  // 显示"另存为"对话框
  void _showSaveAsDialog() {
    final TextEditingController fileNameController = TextEditingController(
      text: 'new_document.md',
    );
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('保存文件'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: fileNameController,
                decoration: const InputDecoration(
                  labelText: '文件名',
                  hintText: 'document.md',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              child: const Text('取消'),
              onPressed: () => Navigator.pop(context),
            ),
            TextButton(
              child: const Text('保存'),
              onPressed: () async {
                Navigator.pop(context);
                try {
                  final file = await FileManager.createFile(fileNameController.text);
                  setState(() {
                    _currentFilePath = file.path;
                  });
                  await _saveFile();
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('创建文件失败: ${e.toString()}'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }

  // 保存文件
  Future<void> _saveFile() async {
    if (_currentFilePath.isEmpty) {
      // 如果没有当前文件路径，提示用户先创建或打开文件
      _showSaveAsDialog();
      return;
    }
    
    try {
      await FileManager.saveFile(_currentFilePath, _textController.text);
    
  // 更新最后保存的内容
      _lastSavedContent = _textController.text;
      setState(() {
        _hasUnsavedChanges = false;
      });
      // 显示保存成功的提示
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('文件已保存'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      // 处理保存错误
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('保存失败: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  // 显示未保存更改对话框
  Future<bool?> _showUnsavedChangesDialog() async {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('未保存的更改'),
        content: const Text('您有未保存的更改，是否继续？'),
        actions: [
          TextButton(
            child: const Text('取消'),
            onPressed: () => Navigator.pop(context, false),
          ),
          TextButton(
            child: const Text('继续'),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );
  }

  // 打开文件
  Future<void> _openFile() async {
    // 如果有未保存的更改，先提示用户
    if (_hasUnsavedChanges) {
      final shouldProceed = await _showUnsavedChangesDialog();
      if (shouldProceed != true) {
        return;
      }
    }
    
    try {
      final result = await FileManager.openFile(context);
    if (result != null) {
      setState(() {
        _currentFilePath = result.path;
        _textController.text = result.content;
        _lastSavedContent = result.content;
        _hasUnsavedChanges = false;
      });
      // 添加到最近文件列表
      if (mounted) {
        if (context.mounted) {
          Provider.of<RecentFilesProvider>(context, listen: false)
              .addRecentFile(result.path);
        }
      }
    }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('打开文件失败: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // 创建新文件
  Future<void> _createNewFile() async {
    final file = await FileManager.createFile('new_document.md');
    setState(() {
      _currentFilePath = file.path;
      _textController.text = '';
      _lastSavedContent = '';
      _hasUnsavedChanges = false;
    });
    if (mounted) {
      Provider.of<RecentFilesProvider>(context, listen: false)
          .addRecentFile(file.path);
    }
  }

  // 更新当前行
  void _updateCurrentLine(String newLine) {
    final lines = _textController.text.split('\n');
    if (_currentLine >= 0 && _currentLine < lines.length) {
      lines[_currentLine] = newLine;
      setState(() {
        _textController.text = lines.join('\n');
      });
    }
  }

  // 获取当前行文本
  String _getCurrentLine() {
    final lines = _textController.text.split('\n');
    if (_currentLine >= 0 && _currentLine < lines.length) {
      return lines[_currentLine];
    }
    return '';
  }

  // 更新当前行文本
  void _updateCurrentLineText(String newLine) {
    _updateCurrentLine(newLine);
  }

  // 批量调整子标题级别
  void _adjustSubheadings(int levelChange) {
    // 获取当前文本的所有行
    final lines = _textController.text.split('\n');

    // 确保当前行在有效范围内
    if (_currentLine < 0 || _currentLine >= lines.length) {
      return;
    }

    // 检查当前行是否是标题
    final currentLevel = MarkdownParser.getHeadingLevel(lines[_currentLine]);
    if (currentLevel == 0) {
      // 如果不是标题，显示提示
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('当前行不是标题，无法调整子标题'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
  
    // 获取当前标题的子标题块范围
    final endLine = MarkdownParser.getHeadingBlockRange(lines, _currentLine);
    if (endLine < _currentLine) {
      // 如果没有子标题，显示提示
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('当前标题下没有子标题'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
  
    // 调用MarkdownParser的方法批量调整子标题
    final newLines = MarkdownParser.adjustSubheadings(
      lines, _currentLine, endLine, levelChange);

    // 更新文本内容
    setState(() {
      _textController.text = newLines.join('\n');
      // 重新解析Markdown以更新标题树
      _parseMarkdown();
    });
  }

  // 跳转到指定行
  void _jumpToLine(int line) {
    final lines = _textController.text.split('\n');
    if (line >= 0 && line < lines.length) {
      int offset = 0;
      for (int i = 0; i < line; i++) {
        offset += (lines[i].length + 1); // +1 for newline character
      }
      _textController.selection = TextSelection.fromPosition(
        TextPosition(offset: offset),
      );
      setState(() {
        _currentLine = line;
      });
      _textFieldFocusNode.requestFocus();
    }
  }

  // 处理键盘事件
  bool _handleRawKeyEvent(RawKeyEvent event) {
    if (event is RawKeyDownEvent && event.logicalKey == LogicalKeyboardKey.tab) {
      return _textController.handleKeyEvent(event);
    }
    return false;
  }

  // 更新字数统计的方法
  void _updateWordCount() {
    if (!mounted) return;
    
    final text = _textController.text;
    final cursorPosition = _textController.selection.baseOffset;
    
    if (cursorPosition >= 0) {
      final totalWords = WordCounter.countWords(text);
      final sectionWords = WordCounter.countSectionWords(text, cursorPosition);
      
      setState(() {
        // 如果总字数和段落字数不同，说明光标在标题上
        if (totalWords != sectionWords) {
          _wordCountInfo = "当前段落: $sectionWords 字 / 总计: $totalWords 字";
        } else {
          _wordCountInfo = "总计: $totalWords 字";
        }
      });
    }
  }

  // 保存面板布局
  void _savePanelLayout(double leftWidth, double middleWidth, double rightWidth) {
    print('保存面板布局: 左 $leftWidth, 中 $middleWidth, 右 $rightWidth');
    
    setState(() {
      _savedLeftPanelWidth = leftWidth;
      _savedMiddlePanelWidth = middleWidth;
      _savedRightPanelWidth = rightWidth;
    });
    
    SharedPreferences.getInstance().then((prefs) {
      prefs.setDouble('leftPanelWidth', leftWidth);
      prefs.setDouble('middlePanelWidth', middleWidth);
      prefs.setDouble('rightPanelWidth', rightWidth);
    });
  }

  // 加载面板布局
  void _loadPanelLayout() {
    SharedPreferences.getInstance().then((prefs) {
      final leftWidth = prefs.getDouble('leftPanelWidth');
      final middleWidth = prefs.getDouble('middlePanelWidth');
      final rightWidth = prefs.getDouble('rightPanelWidth');
      
      print('加载面板布局: 左 $leftWidth, 中 $middleWidth, 右 $rightWidth');
      
      if (leftWidth != null && middleWidth != null && rightWidth != null) {
        setState(() {
          _savedLeftPanelWidth = leftWidth;
          _savedMiddlePanelWidth = middleWidth;
          _savedRightPanelWidth = rightWidth;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final aiState = Provider.of<AiState>(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_applications),
            onPressed: _showModelConfigDialog,
            tooltip: '模型配置',
          ),
          // AI处理按钮
          IconButton(
            icon: const Icon(Icons.play_arrow),
            onPressed: () {
              final aiState = Provider.of<AiState>(context, listen: false);
              if (!aiState.isProcessing) {
                aiState.processText(_textController.text);
              }
            },
            tooltip: '开始AI处理',
          ),
          // 切换主题模式
          IconButton(
            icon: Icon(Theme.of(context).brightness == Brightness.light 
                ? Icons.dark_mode 
                : Icons.light_mode),
            onPressed: _showThemeSettingsDialog,
            tooltip: '主题设置',
          ),
          // 切换大纲视图
          IconButton(
            icon: Icon(_showOutline ? Icons.view_sidebar : Icons.view_headline),
            tooltip: _showOutline ? '隐藏大纲视图' : '显示大纲视图',
            onPressed: () {
              setState(() => _showOutline = !_showOutline);
            },
          ),
          // 切换AI结果视图
          IconButton(
            icon: Icon(_showAiResultView ? Icons.visibility : Icons.visibility_off),
            tooltip: _showAiResultView ? '隐藏AI结果视图' : '显示AI结果视图',
            onPressed: () => setState(() => _showAiResultView = !_showAiResultView),
          ),
          // 标题操作按钮
          HeadingActions(
            currentLine: _getCurrentLine(),
            onLineChanged: (String newLine) => _updateCurrentLineText(newLine),
            onPromoteHeading: () {
              setState(() {
                // final newLine = MarkdownParser.promoteHeading(_getCurrentLine());
                // _updateCurrentLineText(newLine);
                // _textController.text = _textController.text.replaceFirst(_getCurrentLine(), newLine);
                // _updateCurrentLineText已经在onLineChanged中被调用，不需要重复
                // 只需要重新解析Markdown以更新标题树
                _parseMarkdown(); // 重新解析Markdown以更新标题树
              });
            },
            onDemoteHeading: () {
              setState(() {
                // _updateCurrentLineText已经在onLineChanged中被调用，不需要重复
                // 只需要重新解析Markdown以更新标题树
                // final newLine = MarkdownParser.demoteHeading(_getCurrentLine());
                // _updateCurrentLineText(newLine);
                // _textController.text = _textController.text.replaceFirst(_getCurrentLine(), newLine);
                _parseMarkdown(); // 重新解析Markdown以更新标题树
              });
            },
            onToggleHeading: () {
              setState(() {
                // final newLine = MarkdownParser.toggleHeading(_getCurrentLine());
                // _updateCurrentLineText(newLine);
                // _textController.text = _textController.text.replaceFirst(_getCurrentLine(), newLine);
                _parseMarkdown(); // 重新解析Markdown以更新标题树
              });
            },
            onAdjustSubheadings: () {
              // 显示批量调整子标题对话框
              showDialog(
                context: context,
                builder: (context) {
                  // 定义级别变化变量
                  int levelChange = 0;
                  
                  return AlertDialog(
                    title: const Text('批量调整子标题级别'),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ListTile(
                          leading: const Icon(Icons.arrow_upward),
                          title: const Text('提升一级（减少#号）'),
                          onTap: () {
                            levelChange = -1;
                            Navigator.pop(context, levelChange);
                          },
                        ),
                        ListTile(
                          leading: const Icon(Icons.arrow_downward),
                          title: const Text('降低一级（增加#号）'),
                          onTap: () {
                            levelChange = 1;
                            Navigator.pop(context, levelChange);
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
                },
              ).then((levelChange) {
                // 如果用户选择了级别变化
                if (levelChange != null) {
                  _adjustSubheadings(levelChange);
                }
              });
            },
          ),
          IconButton(
            icon: Icon(
              Icons.save,
              // 如果有未保存的更改，使用不同的颜色
              color: _hasUnsavedChanges ? Colors.red : null,
            ),
            onPressed: _currentFilePath.isNotEmpty ? _saveFile : null,
            tooltip: _hasUnsavedChanges ? '保存文件 (有未保存更改)' : '保存文件',
          ),
          // 标签操作按钮
          ...TagActions.buildTagActionButtons(context, _textController, () {
            setState(() {}); // 刷新UI
          }),
          IconButton(
            icon: const Icon(Icons.folder_open),
            onPressed: _openFile,
            tooltip: '打开文件',
          ),
          IconButton(
            icon: const Icon(Icons.create_new_folder),
            onPressed: _createNewFile,
            tooltip: '新建文件',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ResizablePanelLayout(
              showLeftPanel: _showOutline,
              showRightPanel: _showAiResultView && aiState.blocks.isNotEmpty,
              initialLeftPanelWeight: 0.2,
              initialRightPanelWeight: 0.4,
              minLeftPanelWidth: 150.0,
              minMiddlePanelWidth: 300.0,
              minRightPanelWidth: 250.0,
              onLayoutChanged: _savePanelLayout,
              savedLeftPanelWidth: _savedLeftPanelWidth,
              savedMiddlePanelWidth: _savedMiddlePanelWidth,
              savedRightPanelWidth: _savedRightPanelWidth,
              
              // 大纲视图
              leftPanel: OutlineView(
                headingTree: _headingTree,
                onHeadingTap: _jumpToLine,
                currentLine: _currentLine,
              ),
              
              // 编辑器
              middlePanel: Padding(
                padding: const EdgeInsets.all(8.0),
                child: RawKeyboardListener(
                  focusNode: _keyboardListenerFocusNode,
                  onKey: (RawKeyEvent event) {
                    if (_handleRawKeyEvent(event)) {
                      return;
                    }
                  },
                  child: TextField(
                    controller: _textController,
                    focusNode: _textFieldFocusNode,
                    maxLines: null,
                    expands: true,
                    decoration: InputDecoration(
                      hintText: '在这里输入或编辑文本...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      filled: true,
                      fillColor: Theme.of(context).brightness == Brightness.dark 
                          ? const Color(0xFF050500) 
                          : Colors.white,
                    ),
                    style: TextStyle(
                      fontSize: 16.0,
                      fontFamily: 'monospace',
                      color: Theme.of(context).brightness == Brightness.dark 
                          ? const Color(0xFFEAE0C0) 
                          : null,
                    ),
                  ),
                ),
              ),
              
              // AI 结果视图
              rightPanel: AiResultView(
                blocks: aiState.blocks,
                onReplace: (block) {
                  final newText = aiState.replaceBlock(
                    _textController.text,
                    block,
                  );
                  if (newText != _textController.text) {
                    setState(() {
                      _textController.text = newText;
                    });
                  }
                },
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8.0),
            color: Theme.of(context).colorScheme.surfaceVariant,
            height: 30.0,
            child: Row(
              children: [
                // 字数统计信息
                Text(
                  _wordCountInfo,
                  style: TextStyle(
                    fontSize: 12.0,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 16),
                // 文件路径
                Expanded(
                  child: Text(
                    _currentFilePath.isEmpty ? "未打开文件" : "当前文件: $_currentFilePath",
                    style: TextStyle(
                      fontSize: 12.0,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                // 未保存标记
                if (_hasUnsavedChanges)
                  Text(
                    "(未保存)",
                    style: TextStyle(
                      fontSize: 12.0,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.red[300]
                          : Colors.red,
                      fontWeight: FontWeight.bold,
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
