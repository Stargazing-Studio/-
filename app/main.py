"""转发 FastAPI 应用入口，保持包路径稳定。"""

from fastapi import FastAPI

from server.app.main import app as _shared_app, create_app as _shared_create_app


def create_app() -> FastAPI:
    """返回一个新的 FastAPI 应用实例，供测试或扩展使用。"""
    return _shared_create_app()


app: FastAPI = _shared_app
