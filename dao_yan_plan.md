# 《灵衍天纪》全栈开发蓝图

## 1. 项目概览
### 1.1 愿景与体验目标
- 构建一个由大型语言模型驱动的开放式文字修仙世界，让玩家的决策与世界演化实时绑定。
- 保证跨平台一致性：Flutter 前端在 iOS/Android 上维持 60fps，弱网环境下仍能平稳输出文字流。
- AI 叙事不仅负责剧情，还承担世界法则的自监督，确保逻辑自洽与长期沉浸感。

### 1.2 用户群体与设备基线
- 目标玩家：18-35 岁的修仙题材爱好者、轻度社交向 MMORPG 玩家、内容创作者。
- 设备：中端 Android（6GB RAM）与 iOS（A12 芯片）作为性能基准，支持横竖屏自适应。

### 1.3 功能范围扩展
- 个人信息页面：提供角色名片、属性成长轨迹、功法与灵仆灵宠展示、社交标签、最近成就。
- 灵仆灵宠系统：玩家可契约灵仆（辅助型）与灵宠（战斗/探索型），均由 AI 赋予性格、记忆与成长曲线。
- 秘境系统：支持单人/多人秘境、时序刷新、AI 驱动的秘境事件与动态奖励；与世界事件、宗门争夺联动。
- 飞升体系：跨大区的飞升试炼、位面晋升与传承继承，提供长期飞升目标与跨服荣誉展示。
- 丹药与功法体系：完善的炼丹炼器工作流、功法树与绝学传承，允许 AI 根据记忆与世界状态生成变种配方与功法进阶路径。
- 运营扩展：活动日历、排行榜、战报留存，为长期运营准备数据化接口。

## 2. 总体技术架构设计
### 2.1 组件关系与数据流
- **Flutter 客户端**：Riverpod 状态树 + WebSocket 指令通道 + REST 拉取非实时资源（个人信息、灵仆/秘境面板）；本地 Hive/Isar 缓存最近 24h 叙事与记忆片段。
- **API 网关 (FastAPI + Uvicorn)**：统一鉴权、请求优先级队列、速率限制，并暴露 OpenAPI 供内部调用。
- **会话编排服务**：处理玩家输入解析、构建情境数据块、协同 DaoCore AI 服务。
- **世界状态服务**：掌管场景、事件、势力、秘境刷新、飞升阶梯与灵仆灵宠成长状态；提供事务性写接口。
- **秘境与飞升服务簇**：包括秘境调度器、试炼评分器、奖励分发器，负责副本实例管理、跨服飞升匹配与多维分级。
- **社交与个人信息服务**：维护个人信息页数据、关系图谱、隐私控制、灵仆灵宠与功法展示数据聚合。
- **战斗与模拟服务**：半即时回合计算、技能/功法数值执行、灵宠协同出手逻辑，兼容秘境环境加成与飞升试炼特殊规则。
- **炼丹炼器服务**：管理配方、炼化流程、失败/突破概率，并与 AI 交互生成新丹方。
- **AI 编排 (DaoCore)**：提示模板管理、RAG 检索、模型调用、输出结构验证及成本监控。
- **向量数据库 (Milvus 集群)**：存储玩家/NPC/灵仆灵宠/秘境事件的长时记忆向量。
- **PostgreSQL 主库 + 读写分离**：结构化数据与 JSONB 拓展字段；配合 TimescaleDB 插件记录时间轴。
- **Redis**：短时记忆、速率限制、会话锁；Redis Streams 记录近期交互与秘境战斗快照。
- **Kafka 事件总线**：广播世界事件、秘境状态、飞升排名、灵仆灵宠动态，并提供事件溯源。
- **监控与安全**：Prometheus/Grafana 监测，OpenTelemetry 分布式追踪，OPA (Open Policy Agent) 实现 AI 指令安全策略。

### 2.2 典型交互链路
玩家输入“我上次帮了李药师一个忙，现在想去问问他有没有炼制筑基丹的丹方”时：
1. Flutter 将自然语言封装为 `PlayerCommand`，经 WebSocket 发送至网关，附带玩家 ID、会话 Token、位置上下文。
2. 会话编排服务写入 Redis Stream（短时记忆），生成情境标签（玩家 ID、NPC ID、地点、主题=炼丹）。
3. DaoCore 根据标签向 Milvus 发起混合检索：语义向量 + 标签过滤，返回 Top8 记忆片段（包含之前帮忙事件、NPC 性格、丹方相关知识）。
4. DaoCore 组合短时记忆、情境数据块、系统规则提示，调用高阶 LLM；LLM 生成叙事与指令 JSON。
5. 指令执行器验证 JSON Schema、权限与冷却，触发世界状态服务更新玩家好感、奖励丹方、记录新的记忆条目并写入 Kafka。
6. Kafka 推送事件至社交/世界频道；会话编排将叙事文本与状态变更包经 WebSocket 回传玩家，并向相关区域玩家广播；若触发秘境加成或丹药线索，也会同步给相关服务。
7. 客户端更新文字流、角色属性卡片；同时刷新个人信息页缓存（新增丹方、灵仆羁绊加成），并提示可解锁的秘境或功法分支。

## 3. 核心模块技术方案
### 3.1 AI 记忆与叙事编排
#### 3.1.1 长时记忆（RAG）
- 记忆生成：事件监听器从游戏服务捕获关键事件，使用模板转写成摘要（主体、场景、动机、结果、影响），并打上标签（players、npcs、companions、locations、themes、secret_realms、pills、techniques）。
- 嵌入：采用 text-embedding-3-large 或开源 bge-m3 模型生成 1024 维向量；将摘要、原始详情、标签、版本号存入 Milvus 分片。
- 分片策略：按世界大区与实体类型进行 Hybrid Shard；灵仆灵宠、秘境、丹药、功法记忆分别独立分片以保障检索效率。

#### 3.1.2 短时记忆
- Redis Stream 记录最近 10 轮对话、战斗轮次、秘境事件、灵仆灵宠互动；每条记录含时间戳、叙事文本、结构化变更。
- 对不同频道（主线、战斗、秘境、社交）分别维护 Stream，拼装提示时按优先级筛选。

#### 3.1.3 记忆检索流程
- 预过滤：基于玩家 ID、场景 ID、参与实体（NPC/灵仆/秘境/功法）过滤 Milvus 候选集合，避免无关记忆污染。
- 语义排序：综合余弦相似度、时间衰减（λ=0.85/周）与重要性评分（GM 评分 + 玩家反馈）。
- 结果拼装：选取 Top5 长时记忆 + Top3 灵仆灵宠或秘境专属记忆；若不足则退化为规则化知识库查询。

#### 3.1.4 情境数据块模板
```json
{
  "session_id": "sess-48a7",
  "timestamp": "2024-03-21T12:03:22Z",
  "player": {
    "id": "player-1024",
    "name": "辰羽",
    "realm": "筑基中期",
    "stats": {"hp": 860, "mp": 540, "qi": "122/150"},
    "reputation": {"丹霞坊": 35, "青云宗": 18},
    "social_tags": ["炼丹师", "结义-晨风"],
    "companions": ["companion-spirit-ashfox"],
    "active_quests": ["quest-alchemy-003"],
    "eligible_secret_realms": ["realm-danxia-lab"],
    "ascension_progress": {"stage": "筑基天梯", "points": 42}
  },
  "npc": {
    "id": "npc-li-yaoshi",
    "name": "李药师",
    "affiliation": "丹霞坊",
    "current_mood": "感激",
    "debt_to_player": "承诺提供筑基丹相关帮助"
  },
  "companions": [
    {
      "id": "companion-spirit-ashfox",
      "type": "灵宠",
      "bond_level": 42,
      "recent_role": "探索支援",
      "unique_trait": "记忆远古丹方"
    }
  ],
  "location": {
    "id": "loc-danxia-hall",
    "name": "丹霞坊炼丹殿",
    "regional_events": ["event-demon-raids-nearby"],
    "environmental_state": {"qi_density": "高", "visitors": 24}
  },
  "skills": [
    {"id": "skill-flame-control", "name": "紫焰控火术", "proficiency": 72}
  ],
  "items": [
    {"id": "item-qi-condensing-herb", "name": "凝气草", "quantity": 3}
  ],
  "world_state": {
    "season": "仲夏",
    "global_events": ["秘境·青云裂谷三日后开启"],
    "factions": {"丹霞坊": "盟友", "血冥教": "敌对"}
  },
  "recent_short_term_memory": [
    "上一轮对话中玩家协助李药师收集灵草。",
    "李药师承诺回赠筑基丹方。",
    "灵宠灰炎狐记得一处失落丹方线索。"
  ]
}
```

#### 3.1.5 AI 输出结构化 JSON
```json
{
  "narrative": "李药师面露喜色，从袖中取出一枚玉简递给你，低声道：“这是我珍藏的筑基层丹方，愿你早日结丹。”灵宠灰炎狐兴奋地绕着你盘旋，提醒你这丹方或许还能改良，并提议前往丹霞秘境深处采集稀有药材。",
  "instructions": [
    {
      "action": "update_player_stat",
      "target_player_id": "player-1024",
      "payload": {"stat": "favor_li_apothecary", "mode": "add", "value": 10}
    },
    {
      "action": "add_item_to_inventory",
      "target_player_id": "player-1024",
      "payload": {"item_id": "item-core-jade-slip", "quantity": 1, "metadata": {"grade": "rare", "name": "筑基层丹方"}}
    },
    {
      "action": "create_world_event",
      "payload": {
        "event_id": "event-alchemy-boost",
        "title": "丹霞坊炼丹热潮",
        "description": "李药师公开筑基丹方的部分要点，引发炼丹师热议。",
        "scope": "region_danxia",
        "start_time": "2024-03-21T12:03:25Z",
        "duration_minutes": 180,
        "impact_tags": ["alchemy", "economy"]
      }
    },
    {
      "action": "update_npc_relationship",
      "target_npc_id": "npc-li-yaoshi",
      "payload": {"player_id": "player-1024", "relationship": "ally", "trust_delta": 15}
    },
    {
      "action": "update_companion_state",
      "target_companion_id": "companion-spirit-ashfox",
      "payload": {"bond_exp": 50, "mood": "excited", "memory_fragment": "协助玩家获得丹方"}
    },
    {
      "action": "unlock_secret_realm",
      "payload": {"realm_id": "realm-danxia-lab", "player_id": "player-1024", "expiry": "2024-03-28T00:00:00Z"}
    }
  ]
}
```

#### 3.1.6 记忆写入与治理
- 新增记忆：将叙事要点、指令执行结果写入事件溯源日志，同时生成适用于灵仆灵宠、秘境、丹药、功法的专属记忆。
- 记忆治理：定期离线清洗重复/冲突记忆，使用人工审核工具处理高价值 NPC、秘境事件、丹药与功法记忆。
- 控制成本：对高频场景启用记忆缓存与精简提示策略；秘境/飞升场景支持批量提示拼接。

### 3.2 后端服务模块
- **技术栈推荐**：Python + FastAPI + SQLAlchemy + Pydantic v2；原因：生态成熟、异步支持良好、便于整合 AI 工作流与 DevOps。
- **服务拆分**：
  - 会话编排服务：负责意图理解、指令路由、AI 调用。
  - 世界状态服务：掌管地图、事件、资源刷新，使用 CQRS 读写分离。
  - 灵仆灵宠服务：追踪成长、技能、羁绊任务、AI 行为偏好。
  - 秘境与飞升服务：负责秘境生成、匹配、奖励结算、飞升试炼与飞升功勋。
  - 炼丹炼器服务：管理配方、炼制过程、失败与突破概率。
  - 社交与个人信息服务：好友、师徒、道侣、宗门、排行榜、个人信息页数据聚合。
  - 资产服务：物品、功法、炼丹炼器产出。
- **AI 指令执行器**：
  - Pydantic Schema 校验 → OPA 权限策略 → 事务执行（PostgreSQL + Redis）→ 事件写入 Kafka → 观察者更新缓存。
  - 支持幂等、回滚与审计；为灵仆灵宠、秘境奖励、飞升积分指令设定独立速率限制与资源上限。
- **规则与 AI 平衡**：
  - 数值底层（战斗、资源刷新、秘境奖励、飞升积分、丹药炼制成功率）由硬编码规则控制；AI 在允许范围内生成叙事与差异化奖励。
  - 对稀有产物与飞升资格引入“AI 审核层”，通过策略引擎二次确认后落库。

### 3.3 多人实时通信
- 选型：python-socketio + Redis Adapter。优势：与 FastAPI 易整合、支持水平扩展与房间模型、高级 ACK 机制保证消息投递。
- 通道划分：
  - 世界广播、区域频道、宗门频道、队伍/副本房间、秘境实例房间、飞升试炼频道、私聊。
  - 灵仆灵宠动态通知独立频道，可单独订阅。
- 同步策略：
  - 增量补丁（diff patch） + 客户端状态版本号；秘境实例采用“场景快照 +事件流”双通道。
  - 大事件（世界 Boss、飞升冲榜、跨服秘境）通过 Kafka → Socket.IO 推送，客户端使用一致性校验码快速确认。

### 3.4 Flutter 前端模块
- **状态管理**：Riverpod + StateNotifier + Freezed 数据模型，辅以 dio/http 包与 web_socket_channel。
- **UI 布局**：
  - 主游戏界面：顶栏世界事件 ticker，中部文字叙事瀑布流，底部输入栏 + 快捷指令（功法、灵仆技、秘境指令、常用动作）。
  - 个人信息页面：
    - Tab 切换：属性总览、功法与战力、灵仆灵宠、秘境战绩、社交关系、成就收藏。
    - 展示维度：成长曲线图（realm progression）、功法搭配、灵仆羁绊树、秘境通关记录、飞升段位、玩家自定义介绍。
    - 数据来源：REST 拉取基础资料 + WebSocket 推送动态（新成就、灵仆升级、秘境战报）。
  - 灵仆灵宠面板：
    - 卡片式列表（灵仆、灵宠分组），展示性格、技能、心情、羁绊、上次出战表现。
    - 互动区域（喂食、对话、派遣任务、秘境参战），实时调用后端指令。
  - 秘境/飞升界面：
    - 列表 + 地图混合视图，展示可参与秘境、推荐难度、队伍招募。
    - 飞升试炼面板展示飞升排行、奖励里程碑、传承继承配置。
- **交互伪代码**：
```dart
final channel = IOWebSocketChannel.connect(Uri.parse(wsEndpoint));
final commandBus = StreamController<PlayerCommand>();

void initSockets() {
  channel.stream.listen((payload) {
    final event = WorldEvent.fromJson(jsonDecode(payload));
    ref.read(worldStateProvider.notifier).apply(event);
    if (event.affectsProfile) {
      ref.invalidate(playerProfileProvider);
    }
    if (event.type == WorldEventType.companionUpdate) {
      ref.read(companionProvider.notifier).sync(event);
    }
    if (event.type == WorldEventType.secretRealmUpdate) {
      ref.read(secretRealmProvider.notifier).sync(event);
    }
    if (event.type == WorldEventType.ascensionRanking) {
      ref.read(ascensionProvider.notifier).update(event);
    }
  });

  commandBus.stream.listen((cmd) {
    channel.sink.add(jsonEncode(cmd.toJson()));
  });
}

void sendPlayerAction(PlayerCommand cmd) => commandBus.add(cmd);
```

### 3.5 灵仆灵宠系统设计
- **类型与角色**：
  - 灵仆：辅助/生产/探索，偏向采集、炼丹、炼器、信息侦查，秘境中可提供资源倾向与道具制作。
  - 灵宠：战斗/护主/奇遇触发，拥有主动与被动技能，战斗时按羁绊触发联动，部分灵宠可在飞升试炼中解锁专属奥义。
- **AI 行为**：
  - 每个灵仆/灵宠拥有独立人格向量、情绪状态、记忆片段；RAG 检索时额外注入灵仆视角记忆。
  - 支持玩家与灵仆自然语言互动（训练、安抚、命令），秘境内会根据地形与敌情提出建议。
- **成长系统**：
  - 羁绊值、忠诚度、心情、疲劳度；利用定时任务与事件驱动更新。
  - 灵仆任务系统（派遣到秘境/市集），结果由 AI 叙事 + 数值模拟混合决定，并可能解锁新丹方或功法线索。
- **战斗协同**：
  - 灵宠技能与玩家功法组合触发联动，后端战斗服务按规则计算效果，AI 负责描述。
  - 秘境/飞升场景提供环境触发器（灵宠共鸣、灵仆阵法），AI 会在提示中指示可用策略。

### 3.6 秘境、飞升、丹药与功法系统设计
#### 3.6.1 秘境系统
- **秘境类型**：恒常秘境、限时秘境、跨服大秘境、宗门秘境；根据难度划分 tiers，与玩家境界和装备挂钩。
- **生成与刷新**：世界状态服务根据玩家行为热度与 AI 建议生成秘境队列；秘境调度器结合 Kafka 事件与 Redis 速率限制分配实例。
- **AI 叙事**：DaoCore 在秘境探索中根据实时战况、环境、记忆为每个阶段生成叙事文本与事件（机关、奇遇、突发敌人）。
- **奖励机制**：奖励由规则引擎给出数值边界，再由 AI 根据玩家表现细化叙事；支持灵仆特性加成、丹药产出概率、功法残篇掉落。
- **协作模式**：多人秘境采用分段锁步机制，战斗与探险交替；AI 协调队伍互动与冲突调解。

#### 3.6.2 飞升体系
- **进阶结构**：设定多阶段飞升阶梯，结合境界考核、跨服挑战与传承试炼，强调长期成长与实力认证。
- **试炼流程**：飞升服务根据玩家境界、功法组合与秘境成就匹配试炼；AI 生成独特试炼叙事并提供分支选择。
- **传承与继承**：飞升成功后，AI 生成传承故事，允许玩家将部分功法、灵仆记忆、丹药配方传递给新角色或宗门。
- **跨服交互**：飞升段位匹配跨区玩家进行切磋；实时通信模块提供观战与弹幕功能。
- **失败补偿**：结合玩家历史数据提供“悟道”线索，指导功法搭配和丹药研制。

#### 3.6.3 丹药体系
- **配方管理**：基础配方存于 PostgreSQL，AI 可基于记忆与事件生成变体；变体通过 OPA 策略校验后入库。
- **炼制流程**：炼丹界面采用阶段式交互（洗药、凝丹、温养），AI 根据玩家操作返回叙事与成功率调整。
- **材料来源**：材料来自秘境采集、灵仆任务、飞升副本；Redis 维护短期稀缺度，限制市场通货膨胀。
- **品质评估**：战斗服务根据丹药品质影响属性上限、气海恢复、功法突破概率；引入副作用与药毒逻辑。
- **社交分享**：支持丹药展示与交易，个人信息页展示代表性丹药制品。

#### 3.6.4 功法体系
- **功法结构**：划分为心法、身法、攻伐、辅助四大类；通过功法树与羁绊矩阵建模，支持自定义组合。
- **学习途径**：主线奖励、秘境掉落、师徒/宗门传授、AI 生成奇遇；灵仆与灵宠可提供功法共鸣。
- **AI 作用**：DaoCore 根据玩家战斗表现与记忆推荐功法搭配，生成悟道提示；支持功法残篇拼接与功法合成。
- **平衡机制**：硬编码基础数值，AI 输出的功法变体需通过技能模拟器与策略引擎校验。

### 3.7 数据库与数据模型
- **数据库组合**：PostgreSQL（结构化）+ TimescaleDB（时序）+ Redis（缓存/短时记忆）+ Milvus（向量）+ S3 兼容对象存储（灵仆模型、素材、秘境地图）。
- **核心数据表（示例字段）**：
  - `players(id, account_id, name, gender, realm_stage, stats_json, reputation_json, created_at)`
  - `player_profiles(player_id, biography, titles, showcase_items, social_links, privacy_flags, updated_at)`
  - `npcs(id, name, faction_id, temperament, standing_json, last_interaction_at)`
  - `companions(id, owner_player_id, type, name, personality_tags, bond_level, mood_state, fatigue, skills_json, last_update)`
  - `secret_realms(id, name, tier, schedule_type, entry_rules, environment_json, rewards_json, reset_at)`
  - `realm_runs(id, realm_id, instance_id, participant_ids, outcome, loot_json, started_at, finished_at)`
  - `ascension_trials(id, player_id, tier, score, milestones_json, status, updated_at)`
  - `pill_recipes(id, name, grade, base_effects_json, required_items, difficulty, unlock_source)`
  - `pill_batches(id, recipe_id, crafter_id, success_rate, result_quality, side_effects_json, created_at)`
  - `technique_trees(id, name, category, branches_json, unlock_requirements, synergy_tags)`
  - `player_techniques(id, player_id, technique_id, mastery_level, custom_variation_json, last_used_at)`
  - `items(id, name, rarity, type, base_properties_json, craft_recipe_id)`
  - `skills(id, name, category, base_power, scaling_rules_json, unlock_requirements)`
  - `world_events(id, title, scope, state, start_time, end_time, payload_json, created_by)`
  - `quests(id, owner_id, quest_type, status, objectives_json, rewards_json, expires_at)`
  - `player_relations(id, player_id, target_id, relation_type, intimacy, trust, last_update)`
  - `profile_highlights(id, player_id, highlight_type, description, media_ref, created_at)`

### 3.8 运维与安全
- DevOps：GitHub Actions + Argo CD，实现多环境部署；模型调用采用自建代理或官方 SDK。
- 监控：Prometheus 监控 LLM 调用耗时/成本、秘境实例数、飞升成功率、灵仆任务成功率；Grafana 告警绑定飞书/Slack。
- 安全：JWT + 确权，灵仆命令、秘境奖励、飞升段位变更需服务端二次确认；DLP 检测玩家输入防止违规内容。

## 4. 开发路线图
### 阶段一：技术验证与单人 MVP（第 1-8 周）
- 目标：单人冒险闭环、基础 RAG、灵仆原型（静态羁绊展示）、丹药炼制原型（单步流程）。
- 指标：平均响应时间 ≤ 4s；剧情分支 ≥ 10；灵仆羁绊界面可展示基础信息；丹药成功率算法上线。

### 阶段二：多人核心功能与个人信息页（第 9-18 周）
- 目标：接入 Socket.IO，完成共享世界；上线个人信息页（属性、功法、灵仆卡片、秘境战绩预留）；实现玩家间私聊与组队；丹药配方收集系统。
- 指标：并发在线 800；个人信息页加载 ≤ 1.5s；在线留言/互动成功率 ≥ 99%；丹药配方检索延迟 ≤ 200ms。

### 阶段三：AI 记忆深化、秘境与灵仆灵宠系统（第 19-30 周）
- 目标：完善 AI 指令执行器、安全策略；开放秘境匹配、灵仆任务、灵宠战斗协同、记忆个性化对话；世界事件与秘境动态打通；功法树基础版。
- 指标：记忆命中率 ≥ 85%；秘境实例稳定度 ≥ 99%；灵仆任务成功率统计上线；功法搭配推荐准确率 ≥ 75%。

### 阶段四：飞升体系与运营工具（第 31-40 周）
- 目标：上线飞升试炼体系、跨服匹配、传承系统；完善丹药交互（全流程炼制、批量炼制、流通记录）；搭建运营后台、活动与排行系统；监控与告警、A/B 测试框架。
- 指标：P95 响应 ≤ 2.2s；飞升试炼参与率 ≥ 60%；丹药流通成功率 ≥ 98%；留存（次日）≥ 38%。

### 阶段五：公测迭代与内容扩充（第 41-52 周）
- 目标：根据公测反馈优化 AI 成本、拓展跨服秘境与飞升主题内容；推出功法合成、丹药名册、灵仆灵宠主题剧情；完善长期轮换工具链。
- 指标：LLM 成本较公测初期下降 25%；世界事件稳定度 ≥ 99%；新增内容每月保持 2 次大更；飞升挑战复回率 ≥ 70%。

## 5. 关键挑战与解决方案
- **记忆一致性与污染**：引入记忆版本控制、冲突检测、人工审核工具；灵仆灵宠、秘境、丹药、功法记忆并行存储，避免串扰。
- **LLM 成本与延迟**：分层模型路由（高价值剧情→高端模型、常规对话→中型模型）；提示缓存、批量请求、流式解码；秘境与飞升场景采用阶段性合并提示。
- **AI 指令安全可扩展性**：白名单动作 + OPA 策略；在灰度环境回放指令；提供 DSL 配置使新动作可热插拔；关键指令需多人审核。
- **多人实时压力**：分区房间 + 消息聚合；世界事件走 Kafka 批处理；客户端退避策略与增量同步确保弱网体验；秘境使用实例级限流与优先级队列。
- **秘境与飞升资源调度**：建立弹性实例池与冷启动预热机制；依据在线人数和活动节奏动态扩缩容；结合 TimescaleDB 预测模型提前调度资源。

## 6. 团队配置与协作建议
- 核心团队：架构师 1、后端 5（含秘境/飞升专人 2）、Flutter 3、AI 工程 2、游戏策划 4（含秘境/功法策划）、UX/UI 2、系统策划 1、QA 4、运维 2、数据分析 1。
- 每阶段结束安排跨学科评审（AI、策划、客户端、运营），确保叙事逻辑、数值平衡、秘境/飞升体验一致。

## 7. 里程碑交付物
- 架构文档、API 契约、指令白名单、秘境/飞升设计手册、丹药与功法数值表、数据库 Schema、Flutter 组件库基线、灵仆灵宠与秘境美术与交互稿、监控仪表盘原型。
- 公测前提供玩家数据导出、秘境战报回放、飞升试炼分析、丹药炼制日志、AI 指令回放、灵仆灵宠成长报告等后台工具。
