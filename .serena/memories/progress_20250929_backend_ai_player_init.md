时间：2025-09-29 00:25Z
任务：将玩家初始化改为完全 AI 生成（不同设备生成不同玩家数据），并在生成存档后自动生成“初试事件”。
变更文件：
- server/app/ai.py：新增 generate_player_state_text 与 generate_initial_event_summary 两个方法；用于服务端直接调用生成玩家 JSON 与初试事件叙事。
- server/app/main.py：在 /profile 首次访问时，不再复制 world 模板；改为：
  1) 使用 INIT_PLAYER_PROMPT + 节点清单调用 Gemini 生成 PlayerState JSON；
  2) 解析/校验并保存玩家独立存档（players/{pid}.json）；pid 作为签名影响生成结果，确保不同设备差异化；
  3) 生成并写入“初试事件”（标签含“初试事件”），通过事件总线广播到 /ws/chronicles。
验证：
- `python -m py_compile server/app/main.py` & `server/app/ai.py` 通过；
- 运行服务后，首次调用 /profile 或前端“开始修行”按钮应：创建玩家存档 + 追加一条“初试事件”到时间线；不同设备（cookie 不同）生成的玩家应有差异。
回滚思路：
- main.py 中将 AI 初始化逻辑替换回 players.create_from_world；
- ai.py 中移除新增方法即可。