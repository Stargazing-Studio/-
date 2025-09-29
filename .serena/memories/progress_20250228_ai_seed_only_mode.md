时间戳：2025-09-28
变更：支持 AI 仅生成模式（AI_SEED_ONLY=true）。
文件：
- server/app/initializer.py：新增 ai_seed_only()，ensure_world_loaded() 在 AI_ONLY 下不回退；新增 regenerate_world_via_ai() 供重置使用。
- server/app/main.py：/admin/reset 在 AI_ONLY 模式下尝试用 Gemini 重建，否则返回 503；非 AI_ONLY 则仍回退到内置初始数据。
- README.md：文档补充 AI_SEED_ONLY 行为说明。
验证：
- 未设 AI_SEED_ONLY：启动即使 Gemini 失败也会使用内置初始世界；/admin/reset 覆盖为内置状态。
- 设 AI_SEED_ONLY=true：启动若 Gemini 不可用将失败；/admin/reset 返回 503，不回退。
注意：
- 当前环境日志显示地区限制（FailedPrecondition: User location is not supported）；开启 AI_ONLY 会导致启动失败，需先解决地区/代理。