"""对外暴露 FastAPI 应用入口，兼容测试路径。"""

from server.app.main import app, create_app

__all__ = ["app", "create_app"]
