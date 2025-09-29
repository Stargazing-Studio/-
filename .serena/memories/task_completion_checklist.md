# 任务完成前检查
- 按模块更新 `task.md` 勾选状态并记录问题/解决方案。
- Flutter 端执行 `dart format .`、`flutter analyze`、`flutter test`，确保无告警和关键测试通过。
- FastAPI 端执行 `pytest`，确认核心接口测试通过；必要时使用 `uvicorn` 启动自测接口。
- 若新增接口或页面，更新 `README.md` 或新增相关文档（如运行手册、接口说明）。
- 对照仓库 AGENTS 指南，确保中文注释/文档齐备，变更可追溯。