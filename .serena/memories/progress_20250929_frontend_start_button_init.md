时间：2025-09-29 00:00Z
任务：前端新增“开始”按钮以初始化玩家信息（触发后端 /profile 设置 Cookie）。
变更文件：
- app/lib/src/features/home/presentation/home_page.dart
变更摘要：
1) AppBar 新增 IconButton（play_circle_outline），点击时调用 `api.fetchProfile()` 并刷新 `playerProfileProvider`，完成玩家初始化；加入中文注释。
2) 在 HomePage.build 内新增 `_initializePlayer()` 方法（局部函数，含轻量 Snackbar 提示）。
3) 错误态面板 `_ErrorPane` 支持自定义动作文案（actionLabel），在首页使用时改为“开始”，引导用户完成初始化；保持原默认“重试”。
4) 新增网络层导入：`api_client.dart`，以便读取 `apiClientProvider`。
验证建议：
- 运行 App，首页 AppBar 右侧应出现“开始修行”按钮；错误态时卡片按钮文案显示“开始”。
- 点击后应看到 Snackbar “玩家已初始化”，后续地图/指令等接口可用。回滚方案：还原文件至变更前版本。