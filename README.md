# 灵衍天纪开发笔记

## 项目概述
- **定位**：AI 驱动的多人文字修仙世界，Flutter 前端 + FastAPI 后端。
- **核心体验**：玩家以自然语言指令驱动剧情，实时世界事件与灵仆灵宠反馈通过 WebSocket 同步。
- **当前状态**：完成后端仓储 + REST/WebSocket 通道、前端 Riverpod 状态树与真实数据对接，提供指令中心、秘境、飞升、炼丹、功法等页面。

## 目录结构
```
├── app/                        # Flutter 前端
│   ├── lib/
│   │   ├── main.dart           # 程序入口
│   │   ├── src/app.dart        # 全局主题与路由
│   │   ├── src/core/           # 配置与网络客户端
│   │   └── src/features/       # 各功能页面与状态
├── server/
│   └── app/
│       ├── main.py             # FastAPI 应用工厂 + 路由
│       ├── data.py             # 示例数据仓储
│       ├── events.py           # WebSocket 广播管理
│       └── schemas.py          # Pydantic 模型
├── scripts/
│   └── integration_smoke_test.py  # REST + WebSocket 冒烟脚本
├── docs/
│   ├── test-plan.md            # 手工/自动化测试记录
│   └── iteration_plan.md       # 后续迭代路线
├── dao_yan_plan.md             # 长期架构蓝图
├── README.md                   # 本文档
└── task.md                     # 任务追踪清单
```

## 快速开始
### 1. 启动后端
```bash
python -m venv .venv
.venv\Scripts\activate
pip install -r server/requirements.txt
uvicorn server.app.main:app --reload --port 8000
```

### 2. 启动前端
```bash
cd app
flutter pub get
flutter run --dart-define=API_BASE_URL=http://localhost:8000 --dart-define=WS_CHRONICLES_URL=ws://localhost:8000/ws/chronicles
```
> 若仅在浏览器运行，可改用 `flutter run -d chrome`。

### 3. 集成冒烟测试
待后端运行后执行：
```bash
python scripts/integration_smoke_test.py --base-url http://localhost:8000
```
脚本会依次校验档案接口、秘境列表、指令提交、指令历史刷新以及实时日志推送。

### 4. Docker Compose 快速启动
```bash
docker compose up --build
```
> 默认启动 FastAPI、Redis、PostgreSQL（示例用途）。配置位于 `.env.example`，实际敏感信息请另行维护。

服务就绪后可访问 `http://localhost:8000/health` 验证，再按需运行前端或冒烟脚本。

### 5. 配置 Gemini（AI 仅生成，无内置数据）
- 在 Google AI Studio/Vertex AI 申请 Gemini API Key。
- 将密钥写入环境变量 `GEMINI_API_KEY` 或 `.env` 文件（参考 `.env.example`）。
- 安装后端依赖 `pip install -r server/requirements.txt`，其中包含 `google-generativeai`。
- 可选：通过 `GEMINI_MODEL_NAME` 指定模型（推荐 `models/gemini-flash-latest`；如遇版本不兼容可用 `gemini-2.5-flash-latest` 或 `gemini-1.0-pro-latest` 回退）。
- 兼容策略：代码将同时尝试带前缀（如 `models/gemini-flash-latest`）与不带前缀（如 `gemini-2.5-flash-latest`）两种形式，以适配不同库版本（v1beta/v1）。
- AI 仅生成模式：设置 `AI_SEED_ONLY=true` 后，系统只接受由 Gemini 生成的世界初始数据；若无法生成（如地区限制/模型不可用），
  - 启动阶段会失败并提示；
  - `/admin/reset` 会返回 503 而不会落回内置初始数据。
 


## 后端接口速览
| 方法 | 路径 | 描述 |
| --- | --- | --- |
| GET | /health | 健康检查 |
| GET | /profile | 玩家档案 |
| GET | /companions | 灵仆列表 |
| GET | /secret-realms | 秘境列表 |
| GET | /ascension/challenges | 飞升试炼 |
| GET | /alchemy/recipes | 丹药配方 |
| GET | /chronicles | 事件日志 |
| GET | /commands/history | 指令历史 |
| POST | /commands | 提交玩家指令（返回指令结果 + 生成日志） |
| POST | /memories | 写入玩家/世界记忆（返回记录） |
| GET | /memories/search | 记忆模糊检索 |
| POST | /events/emit | 按频道广播后台事件（内部/调试用途） |
| WS | /ws/chronicles | 世界日志实时推送通道 |
| WS | /ws/events/{channel} | 通用事件通道，支持多频道订阅 |

## 测试矩阵
| 范畴 | 命令 | 说明 |
| --- | --- | --- |
| 后端接口 | `python -m pytest` | 6 项接口/WS/记忆测试全部通过 |
| Flutter 静态检查 | `flutter analyze` | 无告警；统一 package 导入与主题配置 |
| Flutter 单测 | `flutter test` | 8 个用例，包含首页黄金路径（假数据 + 假 WS） |
| 集成冒烟 | `python scripts/integration_smoke_test.py` | 校验档案/记忆/指令/事件通道全链路 |

详尽执行记录与注意事项见 [docs/test-plan.md](docs/test-plan.md)。

## CI
仓库已提供 [`.github/workflows/ci.yml`](.github/workflows/ci.yml)，覆盖以下作业：

- `backend`：安装 Python 依赖并执行 `python -m pytest`。
- `frontend-lint`：获取依赖并运行 `flutter analyze`。
- `frontend-test`：执行 `flutter test` 与 `flutter test integration_test`。
- `integration`：启动临时 uvicorn 服务并运行 `python scripts/integration_smoke_test.py`。

如需扩展，可在对应 job 中加入缓存策略或将测试结果导出为 junit 工件。

## 文档索引
- [docs/test-plan.md](docs/test-plan.md)：测试命令、版本、结果与风险记录。
- [docs/iteration_plan.md](docs/iteration_plan.md)：AI 记忆服务、实时通信、部署方案等下一阶段计划。
- [dao_yan_plan.md](dao_yan_plan.md)：完整架构设计蓝图。

## 贡献流程
1. Fork 或直接创建 feature 分支（命名示例：`feature/home-socket`）。
2. 保持提交信息中文描述，包含业务背景与验证方式。
3. 提交前执行 `flutter analyze`、`flutter test` 及 `python -m pytest`。
4. 提 PR 时附上影响面、验证截图与回滚方案。

## 许可证
暂定 MIT License，可根据后续合作形态调整。
# 灵衍天纪开发笔记

## 项目概述
- **定位**：AI 驱动的多人文字修仙世界，Flutter 前端 + FastAPI 后端。
- **核心体验**：玩家以自然语言指令驱动剧情，实时世界事件与灵仆灵宠反馈通过 WebSocket 同步。
- **当前状态**：完成后端仓储 + REST/WebSocket 通道、前端 Riverpod 状态树与真实数据对接，提供指令中心、秘境、飞升、炼丹、功法等页面。

## 目录结构
```
├── app/                        # Flutter 前端
│   ├── lib/
│   │   ├── main.dart           # 程序入口
│   │   ├── src/app.dart        # 全局主题与路由
│   │   ├── src/core/           # 配置与网络客户端
│   │   └── src/features/       # 各功能页面与状态
├── server/
│   └── app/
│       ├── main.py             # FastAPI 应用工厂 + 路由
│       ├── data.py             # 示例数据仓储
│       ├── events.py           # WebSocket 广播管理
│       └── schemas.py          # Pydantic 模型
├── scripts/
│   └── integration_smoke_test.py  # REST + WebSocket 冒烟脚本
├── docs/
│   ├── test-plan.md            # 手工/自动化测试记录
│   └── iteration_plan.md       # 后续迭代路线
├── dao_yan_plan.md             # 长期架构蓝图
├── README.md                   # 本文档
└── task.md                     # 任务追踪清单
```

## 快速开始
### 1. 启动后端
```bash
python -m venv .venv
.venv\Scripts\activate
pip install -r server/requirements.txt
uvicorn server.app.main:app --reload --port 8000
```

### 2. 启动前端
```bash
cd app
flutter pub get
flutter run --dart-define=API_BASE_URL=http://localhost:8000 --dart-define=WS_CHRONICLES_URL=ws://localhost:8000/ws/chronicles
```
> 若仅在浏览器运行，可改用 `flutter run -d chrome`。

### 3. 集成冒烟测试
待后端运行后执行：
```bash
python scripts/integration_smoke_test.py --base-url http://localhost:8000
```
脚本会依次校验档案接口、秘境列表、指令提交、指令历史刷新以及实时日志推送。

### 4. Docker Compose 快速启动
```bash
docker compose up --build
```
> 默认启动 FastAPI、Redis、PostgreSQL（示例用途）。配置位于 `.env.example`，实际敏感信息请另行维护。

服务就绪后可访问 `http://localhost:8000/health` 验证，再按需运行前端或冒烟脚本。

### 5. 配置 Gemini（AI 仅生成，无内置数据）
- 在 Google AI Studio/Vertex AI 申请 Gemini API Key。
- 将密钥写入环境变量 `GEMINI_API_KEY` 或 `.env` 文件（参考 `.env.example`）。
- 安装后端依赖 `pip install -r server/requirements.txt`，其中包含 `google-generativeai`。
 


## 后端接口速览
| 方法 | 路径 | 描述 |
| --- | --- | --- |
| GET | /health | 健康检查 |
| GET | /profile | 玩家档案 |
| GET | /companions | 灵仆列表 |
| GET | /secret-realms | 秘境列表 |
| GET | /ascension/challenges | 飞升试炼 |
| GET | /alchemy/recipes | 丹药配方 |
| GET | /chronicles | 事件日志 |
| GET | /commands/history | 指令历史 |
| POST | /commands | 提交玩家指令（返回指令结果 + 生成日志） |
| POST | /memories | 写入玩家/世界记忆（返回记录） |
| GET | /memories/search | 记忆模糊检索 |
| POST | /events/emit | 按频道广播后台事件（内部/调试用途） |
| WS | /ws/chronicles | 世界日志实时推送通道 |
| WS | /ws/events/{channel} | 通用事件通道，支持多频道订阅 |

## 测试矩阵
| 范畴 | 命令 | 说明 |
| --- | --- | --- |
| 后端接口 | `python -m pytest` | 6 项接口/WS/记忆测试全部通过 |
| Flutter 静态检查 | `flutter analyze` | 无告警；统一 package 导入与主题配置 |
| Flutter 单测 | `flutter test` | 8 个用例，包含首页黄金路径（假数据 + 假 WS） |
| 集成冒烟 | `python scripts/integration_smoke_test.py` | 校验档案/记忆/指令/事件通道全链路 |

详尽执行记录与注意事项见 [docs/test-plan.md](docs/test-plan.md)。

## CI
仓库已提供 [`.github/workflows/ci.yml`](.github/workflows/ci.yml)，覆盖以下作业：

- `backend`：安装 Python 依赖并执行 `python -m pytest`。
- `frontend-lint`：获取依赖并运行 `flutter analyze`。
- `frontend-test`：执行 `flutter test` 与 `flutter test integration_test`。
- `integration`：启动临时 uvicorn 服务并运行 `python scripts/integration_smoke_test.py`。

如需扩展，可在对应 job 中加入缓存策略或将测试结果导出为 junit 工件。

## 文档索引
- [docs/test-plan.md](docs/test-plan.md)：测试命令、版本、结果与风险记录。
- [docs/iteration_plan.md](docs/iteration_plan.md)：AI 记忆服务、实时通信、部署方案等下一阶段计划。
- [dao_yan_plan.md](dao_yan_plan.md)：完整架构设计蓝图。

## 贡献流程
1. Fork 或直接创建 feature 分支（命名示例：`feature/home-socket`）。
2. 保持提交信息中文描述，包含业务背景与验证方式。
3. 提交前执行 `flutter analyze`、`flutter test` 及 `python -m pytest`。
4. 提 PR 时附上影响面、验证截图与回滚方案。

## 许可证
暂定 MIT License，可根据后续合作形态调整。
