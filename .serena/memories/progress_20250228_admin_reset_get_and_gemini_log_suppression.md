时间戳：2025-09-28
变更：
1) 新增 GET /admin/reset 以便浏览器直接调用（与 POST /admin/reset 等效）。
2) 优化 Gemini 错误日志：对于 “FailedPrecondition: 400 User location is not supported” 降级为 warning 且不打印堆栈；世界种子失败时走本地初始世界。
文件：
- server/app/main.py：增加 admin_reset_world_get()
- server/app/ai.py：在 generate_command_feedback / generate_world_seed 中针对地区受限错误做无堆栈警告。
验证：
- 浏览器访问 GET /admin/reset 返回 {status: ok}；
- 启动日志不再输出长堆栈，仅有一条可读的 warning。
回滚：
- 删除 GET /admin/reset；恢复 ai.py 中的日志行为。