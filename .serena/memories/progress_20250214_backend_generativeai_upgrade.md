时间戳：2025-09-28
变更：升级后端依赖 google-generativeai 版本
文件：server/requirements.txt
旧值：google-generativeai==0.7.0
新值：google-generativeai==0.8.0
原因：修复运行日志中的 v1beta/模型 404 不兼容问题，配合 ai.py 的模型名规范化与候选回退，避免 /commands 503。按用户要求仅升级依赖，不引入“内置文案”降级输出。
回滚：如需恢复，改回 0.7.0 即可。
验证建议：
1) 使用 venv：python -m venv .venv && .venv\\Scripts\\activate
2) 重新安装：pip install -r server/requirements.txt
3) 启动 uvicorn 并调用 POST /commands，观察是否返回 200 且日志显示使用的模型名。