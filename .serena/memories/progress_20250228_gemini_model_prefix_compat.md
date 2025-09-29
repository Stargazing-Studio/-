时间戳：2025-09-28
变更：Gemini 模型名前缀兼容与默认值调整
文件：server/app/ai.py, README.md
详情：
- 默认模型改为 `models/gemini-flash-latest`，与用户环境一致。
- 候选生成逻辑增强：针对用户输入会同时尝试带 `models/` 与不带前缀两种形式，并补充 `-latest`/`-001`、`gemini-2.5-flash-latest`、`gemini-1.0-pro(-latest)` 等常见别名，提升 v1beta/v1 兼容性。
- README 增补说明：推荐设置 `GEMINI_MODEL_NAME=models/gemini-flash-latest`；代码自动尝试两种前缀形式。
验证建议：
- venv 安装依赖（google-generativeai>=0.8.0），设置 GEMINI_MODEL_NAME=models/gemini-flash-latest，重启 uvicorn；调用 POST /commands 观察 200 与“Gemini 已就绪”日志。
回滚：
- 若需恢复旧默认，改回 `gemini-2.5-flash` 并移除候选中的前缀型条目。