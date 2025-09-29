时间戳：2025-09-28
变更：
1) AI 会话上下文管理（3轮+压缩）：
- server/app/ai.py：generate_command_feedback(content, context) 支持上下文；新增 summarize_dialogue() 供旧历史压缩。
- server/app/main.py：/commands 组装上下文（最近3轮+AI压缩旧历史），压缩摘要写入 MemoryRepository（subject=会话压缩, category=context）。
2) 秘境页面最小化展示：
- server/app/data.py：list_secret_realms 仅返回地图上已发现（secret_realm & discovered=true）的秘境；名称匹配失败时退化到默认列表。
- app/lib/src/features/realms/presentation/secret_realm_page.dart：只显示名称+是否可进入状态（基于 schedule 关键词），移除进入/申请按钮与细节点击。
验证：
- 多轮对话：第4轮起应在后端日志中看到“会话压缩”写入记忆；生成的反馈应考虑最近3轮与压缩摘要。
- 秘境列表：若地图未发现秘境则页面为空；发现后仅展示“可进入/不可进入”，无点击。
回滚：恢复 ai.py 与 main.py 的旧逻辑；还原 data.py 的过滤；还原秘境页面详细信息与按钮。