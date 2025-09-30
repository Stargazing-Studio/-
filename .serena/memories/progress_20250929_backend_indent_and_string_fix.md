时间：2025-09-29 00:00Z
任务：修复 FastAPI 启动报错（IndentationError / 字符串字面量错误）
触发条件：用户运行 `uvicorn server.app.main:app` 报错 `IndentationError: unexpected unindent`（server/app/main.py:187），随后在静态检查中发现未闭合字符串。
变更文件：
- server/app/main.py
变更摘要：
1) 调整 5 个路由处理函数缩进，使其正确嵌套于 `create_app()`：
   - `/shops/{shop_id}/purchase` → `shop_purchase`
   - `/auctions/{auction_id}/buy` → `auction_buy`
   - `/inventory` → `get_inventory`
   - `/ascension/eligibility` → `ascension_eligibility`
   - `/wallet` → `get_wallet`
2) 修复会话上下文构建中的字符串字面量：
   - 将包含裸换行的字符串改为 `\n` 转义形式（`transcript_recent`、`transcript_older`、`context_text` 片段）。
验证：
- 本地执行 `python -m py_compile server/app/main.py` 通过（语法检查 OK）。
- 受限于当前运行环境未安装 `fastapi`，未在本环境实跑 `uvicorn`；建议在用户原环境复测启动。
回滚思路：
- 如需回滚，可从 Git 历史恢复此前版本的 `server/app/main.py`，或将上述修改段落恢复为原始缩进/字符串形式；注意回滚后仍会出现原始错误。
证据：
- 语法检查命令输出：0 错误。