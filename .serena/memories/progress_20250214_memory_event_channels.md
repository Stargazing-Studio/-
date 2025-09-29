# 2025-02-14 记忆与事件频道迭代
- 后端版本升至 0.3.0，新增 MemoryRepository 与 `/memories`, `/memories/search` REST 接口，提供内存级记忆写入与模糊检索。
- WebSocket Broker 升级为多频道 `MultiChannelEventBroker`，新增 `/ws/events/{channel}` 通用流和 `/events/emit` 广播端点；`/ws/chronicles` 保持向后兼容。
- 集成冒烟脚本扩展校验范围（记忆写入、事件广播），对 websocket-client 依赖缺失做运行时提示。
- 服务端测试增至 6 项，覆盖记忆 API 与事件广播；`python -m pytest`、`flutter analyze`、`flutter test` 皆通过。