import 'package:flutter/material.dart';
import 'model_config.dart';
import 'ai_state.dart';

class ModelConfigDialogWidget extends StatefulWidget {
  final ModelConfigProvider configProvider;
  final AiState aiState;

  const ModelConfigDialogWidget({
    Key? key,
    required this.configProvider,
    required this.aiState,
  }) : super(key: key);

  @override
  State<ModelConfigDialogWidget> createState() => _ModelConfigDialogWidgetState();
}

class _ModelConfigDialogWidgetState extends State<ModelConfigDialogWidget> {
  late TextEditingController _nameController;
  late TextEditingController _baseUrlController;
  late TextEditingController _apiKeyController;
  late TextEditingController _modelController;
  late TextEditingController _customRequestTemplateController;
  String _selectedConfigName = '';
  String _apiType = 'openai'; // 默认为OpenAI兼容API

  ModelConfigProvider get configProvider => widget.configProvider;
  AiState get aiState => widget.aiState;

  @override
  void initState() {
    super.initState();
    
    // 初始化控制器
    _nameController = TextEditingController();
    _baseUrlController = TextEditingController();
    _apiKeyController = TextEditingController();
    _modelController = TextEditingController();
    _customRequestTemplateController = TextEditingController();
    
    // 设置默认选中的配置为当前使用的配置
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // 确保配置已加载
      if (configProvider.savedConfigs.isNotEmpty) {
        // 优先选择当前正在使用的配置
        final currentConfig = aiState.modelConfig;
        
        if (currentConfig != null) {
          // 查找当前配置是否在已保存的配置列表中
          final exists = configProvider.savedConfigs
              .any((config) => config.name == currentConfig.name);
          
          if (exists) {
            setState(() {
              _selectedConfigName = currentConfig.name;
              _selectConfig(_selectedConfigName);
            });
          } else {
            // 如果当前配置不在列表中，选择第一个
            setState(() {
              _selectedConfigName = configProvider.savedConfigs.first.name;
              _selectConfig(_selectedConfigName);
            });
          }
        } else {
          // 如果没有当前配置，选择第一个
          setState(() {
            _selectedConfigName = configProvider.savedConfigs.first.name;
            _selectConfig(_selectedConfigName);
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _baseUrlController.dispose();
    _apiKeyController.dispose();
    _modelController.dispose();
    _customRequestTemplateController.dispose();
    super.dispose();
  }

  // 选择配置
  void _selectConfig(String name) {
    final config = configProvider.savedConfigs
        .firstWhere((c) => c.name == name, orElse: () => ModelConfig(
          baseUrl: '',
          apiKey: '',
          model: '',
          name: '新配置',
        ));
    
    _nameController.text = config.name;
    _baseUrlController.text = config.baseUrl;
    _apiKeyController.text = config.apiKey;
    _modelController.text = config.model;
    _customRequestTemplateController.text = config.customRequestTemplate;
    _apiType = config.apiType;
  }

  // 保存配置
  void _saveConfig() {
    // 获取表单数据
    final name = _nameController.text.trim();
    
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('配置名称不能为空'))
      );
      return;
    }
    
    // 创建配置对象
    final config = ModelConfig(
      name: name,
      baseUrl: _baseUrlController.text.trim(),
      apiKey: _apiKeyController.text.trim(),
      model: _modelController.text.trim(),
      apiType: _apiType,
      customRequestTemplate: _customRequestTemplateController.text.trim(),
    );
    
    // 检查是否修改现有配置还是创建新配置
    final isUpdating = name == _selectedConfigName && 
        configProvider.savedConfigs.any((c) => c.name == name);
    
    if (!isUpdating) {
      // 创建新配置，检查名称是否已存在
      if (configProvider.savedConfigs.any((c) => c.name == name)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('配置名称"$name"已存在，请使用其他名称'))
        );
        return;
      }
    }
    
    // 保存配置
    configProvider.saveConfig(config);
    aiState.setModelConfig(config);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(isUpdating ? '已更新配置: $name' : '已创建新配置: $name'))
    );
    
    Navigator.of(context).pop();
  }

  // 删除配置
  void _deleteConfig() {
    // 不允许删除最后一个配置
    if (configProvider.savedConfigs.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('无法删除唯一的配置'))
      );
      return;
    }
    
    // 确认删除
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除配置"$_selectedConfigName"吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              
              // 删除配置
              configProvider.deleteConfig(_selectedConfigName);
              
              // 选择另一个配置
              if (configProvider.savedConfigs.isNotEmpty) {
                setState(() {
                  _selectedConfigName = configProvider.savedConfigs.first.name;
                  _selectConfig(_selectedConfigName);
                });
              }
            },
            child: Text('删除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // 切换到选中的配置
  void _switchToSelectedConfig() {
    final selectedConfig = configProvider.savedConfigs
        .firstWhere((c) => c.name == _selectedConfigName);
    
    // 切换配置
    configProvider.switchConfig(selectedConfig);
    aiState.setModelConfig(selectedConfig);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('已切换到配置: $_selectedConfigName'))
    );
    
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    // 先确保我们有一个唯一配置名称的列表
    final List<String> uniqueConfigNames = [];
    final Map<String, ModelConfig> configMap = {};
    
    for (var config in configProvider.savedConfigs) {
      if (!uniqueConfigNames.contains(config.name)) {
        uniqueConfigNames.add(config.name);
        configMap[config.name] = config;
      }
    }
    
    // 确保选中的值在列表中存在
    bool selectedExists = uniqueConfigNames.contains(_selectedConfigName);
    
    // 如果选中值不存在，重置为第一个
    String dropdownValue = _selectedConfigName;
    if (!selectedExists && uniqueConfigNames.isNotEmpty) {
      dropdownValue = uniqueConfigNames.first;
      // 在下一帧更新状态
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          _selectedConfigName = dropdownValue;
          _selectConfig(dropdownValue);
        });
      });
    }

    return AlertDialog(
      title: const Text('模型配置'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('选择配置:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            
            // 配置选择器和使用按钮
            Row(
              children: [
                Expanded(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: selectedExists ? dropdownValue : null, // 如果值不存在则使用null
                    hint: const Text('选择配置'),
                    items: uniqueConfigNames.map<DropdownMenuItem<String>>((name) {
                      final config = configMap[name]!;
                      // 检查是否是当前活动配置
                      final bool isCurrentlyUsed = aiState.modelConfig?.name == config.name;
                      
                      return DropdownMenuItem<String>(
                        value: name,
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(name),
                            ),
                            // 为当前使用的配置添加标记
                            if (isCurrentlyUsed)
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  '当前使用',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.green,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setState(() {
                          _selectedConfigName = newValue;
                          _selectConfig(_selectedConfigName);
                        });
                      }
                    },
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.check_circle_outline),
                  tooltip: '使用此配置',
                  onPressed: _switchToSelectedConfig,
                  color: Colors.green,
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            const Text('配置详情:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            
            // 名称
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: '配置名称',
                hintText: '输入一个唯一的配置名称',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            
            // API类型选择
            const Text('API类型:'),
            Row(
              children: [
                Expanded(
                  child: RadioListTile<String>(
                    title: const Text('OpenAI兼容'),
                    value: 'openai',
                    groupValue: _apiType,
                    onChanged: (String? value) {
                      if (value != null) {
                        setState(() {
                          _apiType = value;
                        });
                      }
                    },
                  ),
                ),
                Expanded(
                  child: RadioListTile<String>(
                    title: const Text('自定义API'),
                    value: 'custom',
                    groupValue: _apiType,
                    onChanged: (String? value) {
                      if (value != null) {
                        setState(() {
                          _apiType = value;
                        });
                      }
                    },
                  ),
                ),
              ],
            ),
            
            // 根据API类型显示不同的字段
            if (_apiType == 'openai') ...[
              const SizedBox(height: 8),
              TextField(
                controller: _baseUrlController,
                decoration: const InputDecoration(
                  labelText: 'Base URL',
                  hintText: 'https://api.openai.com/v1',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _apiKeyController,
                decoration: const InputDecoration(
                  labelText: 'API Key',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _modelController,
                decoration: const InputDecoration(
                  labelText: '模型',
                  hintText: 'gpt-3.5-turbo',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
            
            if (_apiType == 'custom') ...[
              const SizedBox(height: 8),
              TextField(
                controller: _customRequestTemplateController,
                decoration: const InputDecoration(
                  labelText: '自定义请求模板',
                  hintText: '输入自定义的请求代码或JSON',
                  border: OutlineInputBorder(),
                ),
                maxLines: 10,
              ),
            ],
          ],
        ),
      ),
      actions: [
        // 删除按钮
        if (configProvider.savedConfigs.length > 1)
          TextButton(
            onPressed: _deleteConfig,
            child: const Text('删除'),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
          ),
        // 切换按钮
        TextButton(
          onPressed: _switchToSelectedConfig,
          child: const Text('切换到此配置'),
          style: TextButton.styleFrom(foregroundColor: Colors.green),
        ),
        // 取消按钮
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        // 保存按钮
        TextButton(
          onPressed: _saveConfig,
          child: const Text('保存修改'),
          style: TextButton.styleFrom(foregroundColor: Colors.blue),
        ),
      ],
    );
  }
} 