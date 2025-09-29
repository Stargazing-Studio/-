# 测试记录与注意事项

| 日期 | 版本 | 命令 | 结果 | 备注 |
| --- | --- | --- | --- | --- |
| 2025-02-14 | 后端 v0.3.0 / 前端 master | `python -m pytest` | ✅ 6 passed | 新增记忆/事件接口测试，覆盖健康检查、档案、指令、WS 推送 |
| 2025-02-14 | Flutter stable | `flutter analyze` | ✅ 无告警 | 统一 package 导入、CardTheme API 兼容 Flutter 3.22 |
| 2025-02-14 | Flutter stable | `flutter test` | ✅ 8 passed | 包含黄金路径用例；首次运行需清理 `C:\Users\Administrator\AppData\Local\ms-playwright` 释放磁盘 |
| 2025-02-14 | 集成脚本 | `python scripts/integration_smoke_test.py` | ✅ 通过 | 校验档案/记忆/指令历史/日志推送/多频道广播 |

## 执行摘要
- **环境**：Windows Server、Python 3.12.10、Flutter 3.22.0、Chrome 无头模式。
- **后端服务**：`uvicorn server.app.main:app --reload --port 8000`
- **前端参数**：`--dart-define=API_BASE_URL=http://localhost:8000`、`--dart-define=WS_CHRONICLES_URL=ws://localhost:8000/ws/chronicles`
- **新增校验**：记忆写入/检索、`/events/emit` 多频道广播、`/ws/events/{channel}` 监听

## 风险与改进
1. **磁盘空间**：Flutter 测试需至少 1GB 可用空间。建议定期清理 `%LOCALAPPDATA%/ms-playwright` 与临时目录，并在 CI 中加挂 5GB 工作卷。
2. **WebSocket 依赖**：集成脚本使用 `websocket-client`，需确保 `pip install -r server/requirements.txt` 后可用。
3. **数据一致性**：当前示例数据存于内存，如需回放测试应在脚本前调用 `/commands` 之前清理历史记录或重启服务。
4. **前端黄金路径**：已完成本地集成测试，后续可引入截图对比或连通真实后端环境以验证 UI 一致性。

## 后续动作
- 在 CI 中追加测试结果工件（junit/coverage），便于平台汇总。
- 引入 coverage 统计（`pytest --cov` / `flutter test --coverage`）并将阈值写入 CI。
- 评估使用容器化后端运行 Flutter 集成测试，实现真实服务联调。
