# 2025-02-14 数据与测试更新
- 修复 `server/app/data.py` 乱码，改写示例数据为可读中文并保持仓储结构不变。
- 新增 `app/__init__.py` 与 `app/main.py` 转发至 `server.app.main`，确保 pytest 可以 `from app.main` 导入。
- 批量替换 Flutter 端相对路径导入为 `package:ling_yan_tian_ji/...`，修正路由导航与主题配置以适配 go_router 13 与 Flutter 3.22 API（含 `RouteInformation.uri`、`CardThemeData`、`withValues` 等）。
- 后端 `python -m pytest` 在 2025-02-14 运行通过（4 passed）。
- `flutter analyze` 现已无警告（2025-02-14），但 `flutter test` 仍因 Windows 临时目录磁盘空间不足（errno=112）超时，需腾出 `C:\Users\Administrator\AppData\Local\Temp` 再试。
