"""灵衍天纪后端集成冒烟脚本。

依赖项：
    pip install -r server/requirements.txt
运行方式：
    python scripts/integration_smoke_test.py --base-url http://localhost:8000

脚本流程：
1. 调用 REST 接口校验基础数据（人物档案、秘境列表等）。
2. 写入一条记忆并通过模糊检索确认可用。
3. 发送一条指令并确认命令历史刷新。
4. 建立 WebSocket 监听，等待实时日志推送。
5. 通过事件通道广播测试提醒并校验消息可达。
"""

from __future__ import annotations

import argparse
import json
import sys
import time
from collections.abc import Iterable
from dataclasses import dataclass
from typing import Any
from uuid import uuid4

import httpx

try:
    from websocket import WebSocket
except ModuleNotFoundError:  # pragma: no cover - 运行 pytest 时可能未安装
    WebSocket = None  # type: ignore[assignment]


@dataclass
class CommandResult:
    command_id: str
    feedback: str


class IntegrationFlow:
    def __init__(self, base_url: str) -> None:
        self.base_url = base_url.rstrip("/")
        self.client = httpx.Client(base_url=self.base_url, timeout=10)

    def _create_websocket(self) -> "WebSocket":
        if WebSocket is None:  # pragma: no cover - 仅在依赖缺失时触发
            raise RuntimeError(
                "websocket-client 未安装，无法运行冒烟测试。请执行 'pip install websocket-client' 后重试。"
            )
        return WebSocket()

    def _get(self, path: str) -> httpx.Response:
        response = self.client.get(path)
        response.raise_for_status()
        return response

    def _post(self, path: str, payload: dict[str, Any]) -> httpx.Response:
        response = self.client.post(path, json=payload)
        response.raise_for_status()
        return response

    def verify_profile(self) -> None:
        profile = self._get("/profile").json()
        assert profile["name"], "玩家名称应非空"
        assert profile["techniques"], "功法列表应非空"
        print("✅ 个人档案校验通过：", profile["name"])

    def verify_secret_realms(self) -> None:
        realms = self._get("/secret-realms").json()
        assert isinstance(realms, list) and realms, "秘境列表为空"
        print("✅ 秘境列表返回 %d 条" % len(realms))

    def verify_memory_flow(self) -> None:
        subject = f"冒烟记忆-{uuid4().hex[:8]}"
        append_payload = {
            "subject": subject,
            "content": "测试记忆：辰羽在冒烟脚本中记录世界见闻。",
            "tags": ["冒烟", "测试"],
            "category": "smoke",
            "importance": 60,
        }
        record = self._post("/memories", append_payload).json()
        assert record["id"], "记忆写入失败"
        result = self.client.get(
            "/memories/search", params={"query": subject, "limit": 3}
        )
        result.raise_for_status()
        payload = result.json()
        assert payload["results"], "记忆检索未命中"
        print("✅ 记忆检索命中：", payload["results"][0]["subject"])

    def submit_command(self, content: str) -> CommandResult:
        response = self._post("/commands", {"content": content}).json()
        command_id = response["result"]["id"]
        feedback = response["result"]["feedback"]
        print("✅ 指令提交成功：", command_id)
        return CommandResult(command_id=command_id, feedback=feedback)

    def verify_command_history(self, command_id: str) -> None:
        history = self._get("/commands/history").json()
        assert history, "指令历史为空"
        latest = history[0]
        assert latest["id"] == command_id, "最新指令并非刚提交的记录"
        print("✅ 指令历史已更新：", latest["content"])

    def verify_chronicle_update(self, command_feedback: str) -> None:
        ws_url = self.base_url.replace("http", "ws") + "/ws/chronicles"
        ws = self._create_websocket()
        ws.connect(ws_url, timeout=10)
        try:
            snapshot = json.loads(ws.recv())
            assert snapshot["type"] == "snapshot", "首次消息应为日志 snapshot"
            print("✅ 初始日志 %d 条" % len(snapshot["logs"]))

            # 重放一条心跳，等待后台推送新的 chronicle
            ws.send("ping")
            deadline = time.time() + 8
            while time.time() < deadline:
                update = json.loads(ws.recv())
                if update.get("type") != "chronicle_update":
                    continue
                summary = update["log"]["summary"]
                assert command_feedback[:6] in summary, "日志摘要未包含指令反馈"
                print("✅ 实时日志收到推送：", summary)
                return
            raise AssertionError("在超时时间内未收到 chronicle_update")
        finally:
            ws.close()

    def verify_event_channel(self) -> None:
        ws_url = self.base_url.replace("http", "ws") + "/ws/events/smoke"
        ws = self._create_websocket()
        ws.connect(ws_url, timeout=10)
        try:
            payload = {"type": "alert", "message": "集成冒烟通知"}
            self._post("/events/emit", {"channel": "smoke", "payload": payload})
            message = json.loads(ws.recv())
            assert message["message"] == payload["message"], "事件通道未收到消息"
            print("✅ 事件通道收到广播：", message["message"])
        finally:
            ws.close()

    def close(self) -> None:
        self.client.close()



def main(argv: Iterable[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description="后端集成冒烟测试")
    parser.add_argument("--base-url", default="http://127.0.0.1:8000", help="FastAPI 服务地址")
    args = parser.parse_args(argv)

    flow = IntegrationFlow(args.base_url)
    try:
        flow.verify_profile()
        flow.verify_secret_realms()
        flow.verify_memory_flow()
        result = flow.submit_command("测试集成流程")
        flow.verify_command_history(result.command_id)
        flow.verify_chronicle_update(result.feedback)
        flow.verify_event_channel()
    except Exception as exc:  # noqa: BLE001
        print("❌ 集成流程失败：", exc)
        return 1
    finally:
        flow.close()
    print("🎉 集成流程通过")
    return 0


if __name__ == "__main__":
    sys.exit(main())
