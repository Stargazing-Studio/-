时间戳：2025-09-28
需求：1) 删除所有现有游玩数据；2) 删除事件变化时底部“最近事件”弹窗；3) 修复事件日志页无法返回主页。
变更：
- server/app/data.py：MemoryRepository 增加 clear()，用于清空记忆记录。
- server/app/main.py：新增管理接口 POST /admin/reset，覆盖 world_state 为内置初始状态并清空 MemoryRepository，随后广播 snapshot 刷新前端。
- app/lib/src/features/home/presentation/home_page.dart：
  - 删除监听 lastFeedback 并 showSnackBar 的逻辑（移除底部最近事件弹窗）。
  - 将导航到“事件日志”的跳转由 context.go('/chronicles') 改为 context.push('/chronicles')，以启用返回按钮。
验证建议：
1) 后端：重启 uvicorn；调用 POST /admin/reset，预期返回 {status: ok}；/chronicles GET 返回空列表。
2) 前端：
   - 首页不再出现底部 SnackBar 弹窗；
   - 点击“事件日志”进入列表页，AppBar 出现返回箭头，可返回主页；
   - 通过提交指令新增日志后，首页列表与头部状态更新，无底部弹窗。
回滚：
- 撤销 /admin/reset 路由与 MemoryRepository.clear()；
- 恢复 home_page 删除的 SnackBar 代码，并把 push 改回 go。