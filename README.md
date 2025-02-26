# MDWriter
一个支持 Markdown 编辑的桌面应用程序，具有标题层级管理和 AI 辅助写作等特色功能。
## 功能特点

- 支持 Markdown 文件的创建、编辑和保存- 标题层级管理和大纲视图- AI 标签系统，支持 AI 内容和原文的可视化区分- AI 辅助写作，支持流式响应和实时预览- 跨平台支持（Windows、macOS、Linux）
## AI 功能亮点
- 一键式 AI 处理- 流式响应实时显示- 支持随时停止生成- 精确的文本替换
- 可视化的结果展示- 配置本地持久化
## 最近更新
- **2025-02-26**: 修复了保存按钮无法点击的问题和Tab键功能失效的问题。详见[更新记录](docs/更新记录.md)。
## 快速开始
1. 确保已安装 Flutter SDK
2. 克隆项目3. 安装依赖：
   ```bash   flutter pub get   ```4. 运行项目：   ```bash   flutter run   ```
## 使用指南
1. 配置 AI 功能   - 点击右上角设置图标   - 填写 API 配置信息   - 选择使用的模型
2. 编写文档   - 使用 <ai></ai> 标签标记需要处理的内容   - 可选使用 <origintext></origintext> 标记原文   - 在标签内编写清晰的指令
3. AI 处理   - 点击"开始"按钮开始处理   - 实时查看生成内容   - 可随时点击"停止"按钮   - 使用"替换"按钮应用更改
## 文档
- [功能说明](docs/功能说明.md)- [技术实现](docs/技术实现.md)- [AI功能配置](docs/AI功能配置.md)- [更新记录](docs/更新记录.md)
## 依赖
- flutter_markdown: Markdown 渲染- file_picker: 文件选择- path_provider: 路径管理- provider: 状态管理- http: 网络请求
- shared_preferences: 配置存储
## 开发环境
- Flutter 3.27.1- Dart 3.3.1- VS Code / Android Studio
## 注意事项
1. API 配置   - 需要有效的 API 密钥   - 确保网络连接正常   - 注意 API 调用限制
2. 内容处理   - 合理设置提示词   - 避免过长的输入   - 注意内容安全
3. 性能考虑   - 合理使用停止功能   - 避免同时处理过多内容   - 注意内存使用

## 许可证
MIT License
