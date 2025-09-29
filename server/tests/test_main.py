from __future__ import annotations

from fastapi.testclient import TestClient

from app.main import create_app


def make_client() -> TestClient:
    return TestClient(create_app())


def test_health_check() -> None:
    client = make_client()
    response = client.get("/health")
    assert response.status_code == 200
    assert response.json()["status"] == "ok"


def test_profile_endpoint() -> None:
    client = make_client()
    response = client.get("/profile")
    assert response.status_code == 200
    payload = response.json()
    assert payload["name"] == "辰羽"
    assert len(payload["techniques"]) >= 1


def test_command_submission_updates_history() -> None:
    client = make_client()
    response = client.post("/commands", json={"content": "测试指令"})
    assert response.status_code == 200
    data = response.json()
    assert data["result"]["content"] == "测试指令"
    history = client.get("/commands/history").json()
    assert history[0]["content"] == "测试指令"


def test_websocket_receives_chronicle_updates() -> None:
    client = make_client()
    with client.websocket_connect("/ws/chronicles") as websocket:
        snapshot = websocket.receive_json()
        assert snapshot["type"] == "snapshot"
        assert snapshot["logs"], "初始日志应非空"

        client.post("/commands", json={"content": "联调 WebSocket"})
        update = websocket.receive_json()
        assert update["type"] == "chronicle_update"
        assert "log" in update
        assert "联调" in update["log"]["summary"]


def test_memory_append_and_search() -> None:
    client = make_client()
    append_response = client.post(
        "/memories",
        json={
            "subject": "辰羽与李药师的协作",
            "content": "辰羽帮助李药师炼制筑基丹，记录于秘闻卷。",
            "tags": ["辰羽", "李药师"],
            "category": "story",
            "importance": 70,
        },
    )
    assert append_response.status_code == 201
    record = append_response.json()
    assert record["id"]
    search_response = client.get(
        "/memories/search", params={"query": "李药师", "limit": 5}
    )
    assert search_response.status_code == 200
    payload = search_response.json()
    assert payload["results"]
    assert payload["results"][0]["subject"].startswith("辰羽与李药师")


def test_event_emit_broadcasts_to_channel() -> None:
    client = make_client()
    with client.websocket_connect("/ws/events/alerts") as websocket:
        emit_response = client.post(
            "/events/emit",
            json={
                "channel": "alerts",
                "payload": {"type": "alert", "message": "测试广播"},
            },
        )
        assert emit_response.status_code == 202
        message = websocket.receive_json()
        assert message["message"] == "测试广播"
