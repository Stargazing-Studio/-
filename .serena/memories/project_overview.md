# 项目概览
- 名称：灵衍天纪（LingYan TianJi），目标构建 AI 驱动的多人文字修仙世界。
- 技术栈：前端 Flutter 3.3+/Riverpod/GoRouter，后端 FastAPI + Pydantic + Uvicorn，配套 pytest/httpx 进行 API 测试。
- 目录：`app/` Flutter 客户端（入口 `lib/main.dart`，核心在 `src/` 的路由、主题、功能模块）；`server/` FastAPI 服务（`app/` 下 API、数据、模式定义，`tests/` 下 pytest 用例）；根目录含 `task.md` 任务清单、`dao_yan_plan.md` 蓝图文档。
- 功能：前端提供主页、个人信息、灵仆灵宠、秘境、飞升、炼丹、日志等页面；后端已提供健康检查、档案、灵仆、秘境、飞升挑战、炼丹配方、事件日志等静态数据接口。