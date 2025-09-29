# 2025-XX-XX 实时通道占位功能
- 首页 `HomePage` 集成 `homeLiveUpdatesProvider`，展示连接状态、最近事件，并将日志列表改造为 `AsyncValue` 支持加载/错误态。
- 新增 `ChronicleLogsController` 使用 `StateNotifier` 管理事件日志，可刷新、插入与出错回退。
- 日志与个人档案页根据 `AsyncValue` 显示加载与错误提示。
- 新增测试：`home_command_controller_test.dart`、`log_filter_controller_test.dart`、`chronicle_logs_controller_test.dart` 验证指令历史、筛选器与日志控制器行为。