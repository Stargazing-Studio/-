# 2025-02-14 迭代交付
- 前端：审查文案并将指令历史与日志时间改为 `DateFormat('yyyy-MM-dd HH:mm')`，确保中文体验一致。
- 后端：`server/requirements.txt` 新增 websocket-client 以支撑集成冒烟脚本。
- 脚本：新增 `scripts/integration_smoke_test.py` 运行 REST + WebSocket 流程验证。
- 文档：重写 README 架构/CI 建议，新增 `docs/test-plan.md`（测试记录）与 `docs/iteration_plan.md`（后续两阶段里程碑）。
- 测试：`flutter analyze`、`flutter test`（7 项）与 `python -m pytest` 均通过；清理 `%LOCALAPPDATA%/ms-playwright` 释放空间。
- task.md 全部条目已勾选并补充说明。