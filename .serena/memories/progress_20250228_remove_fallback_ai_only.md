时间戳：2025-09-28
决策：按用户要求不使用任何内置内容，后端启动与重置均强制依赖 AI 生成；失败即报错/503。
改动：
- server/app/initializer.py：移除 fallback 路径；ensure_world_loaded 仅走 Gemini；失败抛错；保留 regenerate_world_via_ai()。
- server/app/main.py：/admin/reset 始终通过 AI 重建，失败返回 503；删除对 build_fallback_world_state 的引用。
- README.md：将“配置 Gemini”标题改为“AI 仅生成，无内置数据”，删除“缺省情况下仍使用内置示例回复”的描述。
影响面：
- 无法访问 Gemini（如地区限制）时，服务启动失败；/admin/reset 返回 503。
回滚：
- 若需恢复 fallback，重新引入 initial_state.build_fallback_world_state，并在 initializer/main 中添加回退逻辑。