## 2025-02-14 底部导航栏修复
- 更新 AscensionDashboardPage 与 SecretRealmPage，统一通过 NavigationScaffold 渲染底部导航，避免切换页面后导航栏消失。
- 修复 home_page.dart 多余括号与遗留 `_indexForLocation` 片段，同时更新 MainNavigationBar 使用 `GoRouterState.of(context)` 获取当前路径，解决 `_paths` 未定义与 `GoRouter.location` 失效问题。
- FastAPI 服务：在 server/app/main.py 中引入 FastAPI lifespan 钩子，移除直接调用 `asyncio.run`，避免 uvicorn 已运行事件循环报错；调整 WorldStateStore 序列化使用 `model_dump(mode="json")`，解决 fallback 世界状态写盘时 datetime 无法编码的问题。
- HomePage 聚焦 AI 对话体验：移除首页的档案/事件通栏，新增对话状态抬头与气泡式日志列表，将玩家档案展示收敛到 ProfilePage。
- 初始叙事：WorldInitializer 会注入“星辰初启”开场日志，确保事件流有完整背景；保留命令输入区和快捷指令。
- Flutter 配置：更新 app_config.dart 默认 API 地址逻辑，Web 环境自动复用当前主机并指向 8000 端口，支持远端终端访问本地后端。
- 运行 `flutter analyze` 仍因既有 `animated_page_route.dart` 与 `test/widget_test.dart` 的历史错误导致失败；后端暂未追加自动化测试。