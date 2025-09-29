# 项目任务清单

## 前端完善（Flutter）
- [x] 核对现有界面文案与交互，确认无乱码或占位符。
  > 首页指令历史与事件日志改为中文时间格式，文案审查无残留占位符。
- [x] 为首页增加 WebSocket 数据占位与状态同步逻辑（指令中心反馈、事件推送）。
- [x] 完善各功能页（个人信息、灵仆灵宠、秘境、飞升、炼丹、功法、事件日志）的组件分层与复用。
- [x] 引入全局错误提示与加载管理（如 `AsyncValue`/全局监听）。
- [x] 编写至少 3 个 Widget/StateNotifier 单元测试验证核心交互。
  > 新增 `home_command_controller_test.dart`、`log_filter_controller_test.dart`、`chronicle_logs_controller_test.dart` 覆盖指令提交、筛选器与日志控制器逻辑。

## 后端编写（FastAPI）
- [x] 初始化 FastAPI 项目结构并配置依赖（Poetry 或 pip requirements）。
- [x] 建立数据模型层（玩家、灵仆、秘境、飞升挑战、丹药、事件日志等）与示例数据。
- [x] 实现基础 API：健康检查、玩家档案、灵仆列表、秘境列表、飞升挑战、炼丹配方、事件日志。
- [x] 设计指令接入端点（提交玩家指令、返回状态），预留与 AI 服务对接的接口。
- [x] 集成日志追踪、错误处理与 CORS 配置，准备与前端联调。

## 测试与质量
- [x] 编写 pytest 用例覆盖主要 API（响应状态 / 数据结构 / 内容校验）。
  > `python -m pytest` 已通过（4 passed）。
- [x] 配置前端 `flutter test` 和 `flutter analyze`，并编写最少 1 个 Widget 黄金路径测试。
  > `flutter analyze`、`flutter test` 均通过；清理 `%LOCALAPPDATA%/ms-playwright` 释放空间后 7 项测试执行成功。
- [x] 准备集成测试脚本（前端指令提交 -> 后端模拟响应 -> 前端状态刷新）。
  > 新增 `scripts/integration_smoke_test.py`，覆盖档案/秘境/指令/日志全链路。
- [x] 整合 CI 流程建议（GitHub Actions 或其他平台），含前后端测试与格式校验。
  > README 新增 CI 作业矩阵与缓存策略示例。
- [x] 汇总测试结果与注意事项，写入 README 或 docs/test-plan.md。
  > 新建 `docs/test-plan.md` 记录命令、结果、风险。

## 文档与后续
- [x] 更新 README（架构图、接口说明、运行手册、开发规范）。
- [x] 根据进度在 task.md 勾选任务，并记录遇到的问题与解决方案。
- [x] 准备后续迭代计划：AI 记忆服务、实时通信、部署方案等。
  > 见 `docs/iteration_plan.md`，包含 M1/M2 目标与关键行动项。
