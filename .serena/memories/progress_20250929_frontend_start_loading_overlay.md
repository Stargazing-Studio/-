时间：2025-09-29 00:40Z
任务：为“开始修行”流程增加加载动画，直到玩家档案与初试事件生成完成。
变更文件：
- app/lib/src/features/home/presentation/home_page.dart
变更摘要：
- 在 `_initializePlayer()` 中加入 `showDialog` 模态加载遮罩（barrierDismissible=false），调用 `/profile` 完成 AI 初始化后才关闭；
- 初始化完成后刷新 `playerProfileProvider` 并触发 `chronicleLogsProvider.notifier.refresh()`，保证时间线可见；
- 成功/失败通过 SnackBar 轻量提示。
验证：
- 点击“开始修行”会出现加载对话框，约数秒后关闭并看到时间线出现“初试事件”。
备注：
- 后端若返回 400（未初始化）或 503（AI 未就绪）时会在前端提示；
- 如需按钮态禁用/骨架屏，可后续加在 AppBar/主体区域。