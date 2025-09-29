时间戳：2025-09-28
变更背景：后端调用 Gemini 报错 404（v1beta 不支持或模型名不兼容），导致 /commands 503。日志含 `models/gemini-2.5-flash`、`generateContent not supported`。
触发原因分析：
- 运行环境可能使用旧版 google-generativeai（v1beta 通道），对 1.5 模型支持不完整。
- 传入模型名带 `models/` 前缀或未加 `-latest/-001`，与库内部期望不一致。
涉及文件：
- server/app/ai.py：规范化模型名（去 `models/` 前缀），默认改为 `gemini-2.5-flash`，新增候选回退（含 `-latest`、`-001`、`gemini-1.0-pro(-latest)`、`gemini-pro`），初始化按序尝试并记录日志；提示用户升级依赖与使用 venv。
- README.md：补充 `GEMINI_MODEL_NAME` 使用建议与兼容性说明。
证据：
- 运行日志：Gemini generate_content failed: 404 models/gemini-2.5-flash ... for API version v1beta
回滚方案：
- 若需恢复：仅恢复 `server/app/ai.py` 到变更前版本，并删除 README 相关新增两行说明。
验证建议：
- 使用 venv 并 `pip install -r server/requirements.txt`（要求 google-generativeai>=0.7.0），`uvicorn server.app.main:app --reload`，调用 POST /commands 检查 200 与文本返回；观察日志“Gemini 已就绪，使用模型：...”。
备注：
- 若仍失败，检查系统 Python 是否为全局解释器（路径含 `D:\APP\Python`），建议改用本地 venv。