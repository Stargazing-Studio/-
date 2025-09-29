# 后续迭代计划（短期）

## 1. AI 记忆服务深化
- **目标**：落地 DaoCore 记忆检索服务，与当前内存仓储解耦。
- **进展（2025-02-14）**：新增内存级记忆仓库与 `/memories`、`/memories/search` 接口，支持冒烟脚本校验。
- **行动项**：
  - [x] 发布 `/memories` 与 `/memories/search` 接口，并纳入冒烟脚本校验。
  - [ ] 定义事件/实体标签 Schema，与 Milvus/PG 映射。
  - [ ] 开发记忆写入流水线：世界事件 → 摘要 → 嵌入 → 审计。
  - [ ] 引入 OPA/策略引擎对白名单指令写入做安全校验。

## 2. 实时通信扩展
- **目标**：从单一日志通道扩展为多频道（世界广播、秘境实例、灵仆动态）。
- **进展（2025-02-14）**：事件 Broker 升级为多频道，新增 `/ws/events/{channel}` 与 `/events/emit` 调试广播接口。
- **行动项**：
  - [x] 将日志通道改造为多频道 `MultiChannelEventBroker`，并提供 `/ws/events/{channel}` 订阅与 `/events/emit` 广播。
  - [ ] 加入心跳与断线重连协商，前端同步提示状态。
  - [ ] 设计统一消息规范（type、payload、scope、version），提供 Schema 校验。
  - [ ] 引入 Redis Pub/Sub 作为中间件，评估横向扩展能力。

## 3. 部署管线
- **目标**：提供可复制的本地→测试→线上部署流程。
- **行动项**：
  - [x] 提供基础 `docker-compose.yml` 与 `server/Dockerfile`，本地一键启动 FastAPI + Redis + PostgreSQL。
  - [ ] 使用 GitHub Actions 构建后端镜像并推送至容器仓库。
  - [ ] 设计 K8s/Helm 初版部署模版，含 Liveness/Readiness、水平扩缩容策略。
  - [ ] 整合敏感配置管理（.env/Secrets Manager）与日志采集（ELK 或 Loki）。

## 4. 前端黄金路径测试
- **目标**：补齐首页指令→反馈→日志刷新 end-to-end 覆盖。
- **行动项**：
  - [x] 使用 `integration_test` 编写黄金路径脚本并纳入 `flutter test integration_test`。
  - [x] 在 CI 工作流中执行集成测试任务。
  - [ ] 引入截图对比或文字快照，保障 UI 文案稳定。

## 5. 观测与告警
- **目标**：为后续公测准备监控指标。
- **行动项**：
  - 在 FastAPI 中追加请求日志、指令耗时、WS 连接数指标。
  - 设计 Prometheus 指标 Exporter，记录指令成功率与错误类型。
  - 建立飞书/Slack 告警 Webhook，配置关键阈值（WS 断连率、指令失败率）。

## 里程碑
- **Milestone M1（两周）**：记忆服务原型 + 多频道推送 + docker-compose 打包；前端完成黄金路径测试。
- **Milestone M2（四周）**：K8s 部署样板 + 监控告警上线 + 集成测试纳入 CI。
