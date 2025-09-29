# 常用命令
- 初始化前端依赖：`cd app && flutter pub get`
- 运行前端调试：`cd app && flutter run`
- 前端格式化：`cd app && dart format .`
- 前端静态检查：`cd app && flutter analyze`
- 前端单元测试：`cd app && flutter test`
- 后端安装依赖：`python -m venv .venv && .venv\Scripts\activate && pip install -r server/requirements.txt`
- 后端本地运行：`uvicorn app.main:app --reload --app-dir server/app`
- 后端测试：`cd server && pytest`
- 接口体验（示例）：启动后访问 `http://127.0.0.1:8000/health`、`/profile` 等。