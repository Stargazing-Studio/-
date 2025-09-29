from __future__ import annotations

import asyncio
from collections import defaultdict
from typing import Any, Iterable, Set

from fastapi import WebSocket


class MultiChannelEventBroker:
    """管理多频道 WebSocket 连接并广播消息。"""

    def __init__(self) -> None:
        self._channels: dict[str, Set[WebSocket]] = defaultdict(set)
        self._lock = asyncio.Lock()

    async def connect(
        self,
        channel: str,
        websocket: WebSocket,
        first_messages: Iterable[Any] | None = None,
    ) -> None:
        await websocket.accept()
        if first_messages:
            for message in first_messages:
                await websocket.send_json(message)
        async with self._lock:
            self._channels[channel].add(websocket)

    async def disconnect(self, channel: str, websocket: WebSocket) -> None:
        async with self._lock:
            sockets = self._channels.get(channel)
            if not sockets:
                return
            sockets.discard(websocket)
            if not sockets:
                self._channels.pop(channel, None)

    async def broadcast(self, channel: str, payload: Any) -> None:
        async with self._lock:
            targets = list(self._channels.get(channel, set()))
        for websocket in targets:
            try:
                await websocket.send_json(payload)
            except Exception:
                await self.disconnect(channel, websocket)
