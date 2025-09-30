from __future__ import annotations

from datetime import UTC, datetime
from typing import List, Tuple
from uuid import uuid4

from fastapi import HTTPException, status

from .schemas import (
    AscensionChallenge,
    ChronicleLog,
    CommandRequest,
    CommandResult,
    Companion,
    MemoryAppendRequest,
    MemoryRecord,
    PillRecipe,
    PlayerProfile,
    SecretRealm,
)
from .world_state import AuctionHouse, Shop, WorldState, WorldStateStore, PlayerState
from pathlib import Path
import json as _json
import random as _random
import shutil as _shutil
import os as _os


class PlayerStore:
    """按浏览器/客户端区分的玩家状态存储（世界共享，玩家数据独立）。

    - 存储路径：server/players/{player_id}.json
    - 初始数据：基于当前世界的 player 模板复制，并随机选择一个地图节点作为起点。
    - 仅管理 PlayerState，不改动全局 WorldState。
    """

    def __init__(self, root: Path) -> None:
        self._root = root
        self._root.mkdir(parents=True, exist_ok=True)

    # 新版目录结构：players/{pid}/state.json, logs.json, commands.json
    def _dir_for(self, player_id: str) -> Path:
        d = self._root / player_id
        d.mkdir(parents=True, exist_ok=True)
        return d

    def _state_path(self, player_id: str) -> Path:
        return self._dir_for(player_id) / "state.json"

    def _logs_path(self, player_id: str) -> Path:
        return self._dir_for(player_id) / "logs.json"

    def _commands_path(self, player_id: str) -> Path:
        return self._dir_for(player_id) / "commands.json"

    # 兼容旧版：players/{pid}.json
    def _legacy_state_path(self, player_id: str) -> Path:
        return self._root / f"{player_id}.json"

    def exists(self, player_id: str) -> bool:
        return self._state_path(player_id).exists() or self._legacy_state_path(player_id).exists()

    def load(self, player_id: str) -> PlayerState:
        path = self._state_path(player_id)
        if not path.exists():
            legacy = self._legacy_state_path(player_id)
            if not legacy.exists():
                raise FileNotFoundError(f"player {player_id} not found")
            # 迁移旧版为新目录结构
            data = _json.loads(legacy.read_text(encoding="utf-8"))
            state = PlayerState.model_validate(data)
            self.save(player_id, state)
            return state
        data = _json.loads(path.read_text(encoding="utf-8"))
        return PlayerState.model_validate(data)

    def save(self, player_id: str, state: PlayerState) -> None:
        path = self._state_path(player_id)
        serialized = _json.dumps(state.model_dump(mode="json"), ensure_ascii=False, indent=2)
        path.write_text(serialized, encoding="utf-8")

    def create_from_world(self, player_id: str, world: WorldState) -> PlayerState:
        template = world.player
        # 随机起点：从地图节点中随机选择一个已存在的 id（避免贴合要求的 discovered 逻辑，保持独立）
        nodes = world.map_state.nodes
        start_id = nodes[_random.randrange(0, len(nodes))].id if nodes else template.current_location
        new_state = PlayerState(
            profile=template.profile,
            current_location=start_id,
            spirit_stones=template.spirit_stones,
            inventory=list(template.inventory),
            blood_percent=template.blood_percent,
        )
        self.save(player_id, new_state)
        return new_state

    # ===== 玩家个人编年史（独立于世界） =====
    def list_logs(self, player_id: str) -> list[ChronicleLog]:
        p = self._logs_path(player_id)
        if not p.exists():
            return []
        try:
            raw = _json.loads(p.read_text(encoding="utf-8"))
            return [ChronicleLog.model_validate(item) for item in raw]
        except Exception:
            return []

    def append_log(self, player_id: str, event: ChronicleLog) -> None:
        items = self.list_logs(player_id)
        items.insert(0, event)
        # 截断避免无限增长
        items = items[: GameRepository._max_chronicle_entries]
        p = self._logs_path(player_id)
        data = [e.model_dump(mode="json") for e in items]
        p.write_text(_json.dumps(data, ensure_ascii=False, indent=2), encoding="utf-8")

    # ===== 玩家个人指令历史 =====
    def list_commands(self, player_id: str) -> list[CommandResult]:
        p = self._commands_path(player_id)
        if not p.exists():
            return []
        try:
            raw = _json.loads(p.read_text(encoding="utf-8"))
            return [CommandResult.model_validate(item) for item in raw]
        except Exception:
            return []

    def append_command(self, player_id: str, cmd: CommandResult) -> None:
        items = self.list_commands(player_id)
        items.insert(0, cmd)
        items = items[: GameRepository._max_commands]
        p = self._commands_path(player_id)
        data = [c.model_dump(mode="json") for c in items]
        p.write_text(_json.dumps(data, ensure_ascii=False, indent=2), encoding="utf-8")

    def list_players_at(self, location_id: str, exclude_pid: str | None = None) -> list[tuple[str, PlayerState]]:
        players: list[tuple[str, PlayerState]] = []
        # 新版目录结构优先
        for path in self._root.glob("*/state.json"):
            pid = path.parent.name
            if exclude_pid and pid == exclude_pid:
                continue
            try:
                data = _json.loads(path.read_text(encoding="utf-8"))
                state = PlayerState.model_validate(data)
                if state.current_location == location_id:
                    players.append((pid, state))
            except Exception:
                continue
        # 兼容旧版扁平文件
        if not players:
            for opath in self._root.glob("*.json"):
                pid = opath.stem
                if exclude_pid and pid == exclude_pid:
                    continue
                try:
                    state = self.load(pid)
                    if state.current_location == location_id:
                        players.append((pid, state))
                except Exception:
                    continue
        return players

    # ===== 管理工具 =====
    def list_ids(self) -> list[str]:
        ids: list[str] = []
        # 新版目录结构
        for d in self._root.iterdir():
            if d.is_dir() and (d / "state.json").exists():
                ids.append(d.name)
        # 兼容旧版扁平文件
        for p in self._root.glob("*.json"):
            pid = p.stem
            if pid not in ids:
                ids.append(pid)
        return ids

    def delete_player(self, player_id: str) -> None:
        # 不要通过 _dir_for 创建目录再删，直接定位目录路径
        d = self._root / player_id
        try:
            if d.exists():
                _shutil.rmtree(d)
            # 兼容旧版扁平文件
            legacy = self._legacy_state_path(player_id)
            if legacy.exists():
                legacy.unlink()
        except Exception:
            pass

    def clear_all(self) -> None:
        try:
            if self._root.exists():
                for entry in self._root.iterdir():
                    try:
                        if entry.is_dir():
                            _shutil.rmtree(entry)
                        elif entry.is_file():
                            entry.unlink()
                    except Exception:
                        continue
        except Exception:
            pass


class GameRepository:
    """世界状态仓库，负责管理玩家、地图、商店与事件记录。"""

    _max_chronicle_entries = 256
    _max_commands = 200

    def __init__(self, store: WorldStateStore) -> None:
        self._store = store

    # 基础读接口 ------------------------------------------------------------
    def get_state(self) -> WorldState:
        return self._store.state

    def get_profile(self) -> PlayerProfile:
        return self.get_state().player.profile

    def list_companions(self) -> List[Companion]:
        return list(self.get_state().companions)

    def list_secret_realms(self) -> List[SecretRealm]:
        # 仅显示主角“已知”（地图已发现的）秘境：依据地图节点 category==secret_realm 且 discovered=True
        state = self.get_state()
        known_names = {
            node.name for node in state.map_state.nodes if node.category == "secret_realm" and node.discovered
        }
        realms = list(state.secret_realms)
        if not known_names:
            return []
        # 名称匹配过滤（若无严格映射，则退化为全部）
        filtered = [r for r in realms if r.name in known_names]
        return filtered if filtered else realms

    def list_ascension_challenges(self) -> List[AscensionChallenge]:
        return list(self.get_state().ascension_challenges)

    def list_pill_recipes(self) -> List[PillRecipe]:
        return list(self.get_state().pill_recipes)

    def list_chronicles(self) -> List[ChronicleLog]:
        return list(self.get_state().chronicle_logs)

    def list_command_history(self) -> List[CommandResult]:
        return list(self.get_state().command_history)

    # 命令与事件 ------------------------------------------------------------
    def record_command(
        self,
        request: CommandRequest,
        feedback_override: str | None = None,
    ) -> Tuple[CommandResult, ChronicleLog]:
        if feedback_override is None or not feedback_override.strip():
            raise ValueError("feedback is required when recording a command")

        state = self.get_state()
        now = datetime.now(UTC)
        feedback_text = feedback_override.strip()

        command = CommandResult(
            id=str(uuid4()),
            content=request.content,
            feedback=feedback_text,
            created_at=now,
        )

        location_node = self.get_current_location_node()
        location_name = location_node.name if location_node else state.player.current_location

        chronicle = ChronicleLog(
            id=f"log-{now.strftime('%Y%m%d%H%M%S')}-{command.id[-5:]}",
            title=f"指令回响 · {location_name}",
            timestamp=now,
            summary=feedback_text,
            tags=["指令", location_name],
        )

        state.command_history.insert(0, command)
        del state.command_history[self._max_commands :]

        state.chronicle_logs.insert(0, chronicle)
        del state.chronicle_logs[self._max_chronicle_entries :]

        self._store.update_state(state)
        return command, chronicle

    def append_event(self, event: ChronicleLog) -> None:
        state = self.get_state()
        state.chronicle_logs.insert(0, event)
        del state.chronicle_logs[self._max_chronicle_entries :]
        self._store.update_state(state)

    # 位置与地图 ------------------------------------------------------------
    def get_map_view(self) -> dict:
        state = self.get_state()
        visible_nodes = [node for node in state.map_state.nodes if node.discovered]
        visible_ids = {node.id for node in visible_nodes}
        # 生成更丰富的渲染样式
        style = state.map_state.style.model_dump()
        # 默认样式 + 可由状态内 extras 覆盖
        defaults = {
            "edge_styles": {
                "road": {"color": "#6B7280", "width": 3.0, "opacity": 0.6, "dash": []},
                "trail": {"color": "#9CA3AF", "width": 2.0, "opacity": 0.5, "dash": [6.0, 4.0]},
                "realm_path": {"color": "#5C6BC0", "width": 2.5, "opacity": 0.55, "dash": [2.0, 3.0]},
            },
            "background_gradient": ["#0F172A", "#111827"],
            "grid_visible": True,
            "node_label": {"color": style.get("node_label_color", "#E0E5FF"), "size": 12.0},
        }
        extras = state.map_state.style.extras if hasattr(state.map_state.style, "extras") else {}
        style.update(
            {
                **defaults,
                **(extras or {}),
            }
        )

        # 不自动生成 tiles。AI-only 模式下，tiles/tiling 必须由 AI 在 style.extras 中提供。

        # 为边增加类型，便于前端按样式绘制
        node_map = {n.id: n for n in visible_nodes}
        def _edge_type(a_cat: str, b_cat: str) -> str:
            pair = {a_cat, b_cat}
            if "secret_realm" in pair:
                return "realm_path"
            if "trail" in pair:
                return "trail"
            return "road"

        edges = []
        for node in visible_nodes:
            for target in node.connections:
                if target in visible_ids:
                    etype = _edge_type(node.category, node_map[target].category)
                    edges.append({"from": node.id, "to": target, "type": etype})

        return {"style": style, "nodes": [n.model_dump() for n in visible_nodes], "edges": edges}

    def get_current_location_node(self):
        state = self.get_state()
        return next(
            (node for node in state.map_state.nodes if node.id == state.player.current_location),
            None,
        )

    def travel_to(self, location_id: str) -> PlayerProfile:
        state = self.get_state()
        node = next((n for n in state.map_state.nodes if n.id == location_id), None)
        if not node:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="未知地点")
        current = state.player.current_location
        current_node = next((n for n in state.map_state.nodes if n.id == current), None)
        if current_node and location_id not in current_node.connections:
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="无法直接前往该地点")
        node.discovered = True
        state.player.current_location = location_id
        self._store.update_state(state)
        return state.player.profile

    # 商店与拍卖 ------------------------------------------------------------
    def list_shops_for_current_location(self) -> List[Shop]:
        state = self.get_state()
        current = state.player.current_location
        return [shop for shop in state.shops.values() if shop.location_id == current]

    def get_shop(self, shop_id: str) -> Shop:
        state = self.get_state()
        shop = state.shops.get(shop_id)
        if not shop:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="未找到商铺")
        if shop.location_id != state.player.current_location:
            raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="需要前往商铺所在地")
        return shop

    def list_auctions_for_current_location(self) -> AuctionHouse | None:
        state = self.get_state()
        current = state.player.current_location
        for auction in state.auctions.values():
            if auction.location_id == current:
                return auction
        return None

    # 购买与背包 ------------------------------------------------------------
    def get_inventory(self):
        return list(self.get_state().player.inventory)

    def _add_inventory(self, item_id: str, name: str, category: str, quantity: int, description: str) -> None:
        state = self.get_state()
        # 若同 id 物品存在则叠加数量
        for entry in state.player.inventory:
            if entry.id == item_id:
                entry.quantity += quantity
                self._store.update_state(state)
                return
        # 否则新增条目
        from .world_state import InventoryEntry  # 局部导入避免循环
        state.player.inventory.append(
            InventoryEntry(
                id=item_id,
                name=name,
                category=category,
                quantity=quantity,
                description=description,
            )
        )
        self._store.update_state(state)

    def purchase_from_shop(self, shop_id: str, item_id: str, quantity: int) -> int:
        if quantity <= 0:
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="数量必须大于 0")
        state = self.get_state()
        shop = self.get_shop(shop_id)
        item = next((x for x in shop.inventory if x.id == item_id), None)
        if not item:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="商品不存在")
        if item.stock < quantity:
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="库存不足")
        total_price = item.price * quantity
        if state.player.spirit_stones < total_price:
            raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="灵石不足，无法购买")
        # 扣费、减库存、入背包
        state.player.spirit_stones -= total_price
        item.stock -= quantity
        self._add_inventory(item.id, item.name, item.category, quantity, item.description)
        # 记录事件
        now = datetime.now(UTC)
        chronicle = ChronicleLog(
            id=f"shop-{now.strftime('%Y%m%d%H%M%S')}-{item.id}",
            title=f"购入 · {item.name}",
            timestamp=now,
            summary=f"在商铺购入 {quantity} × {item.name}，花费 {total_price} 灵石。",
            tags=["交易", "商铺"],
        )
        state.chronicle_logs.insert(0, chronicle)
        del state.chronicle_logs[self._max_chronicle_entries :]
        self._store.update_state(state)
        return total_price

    def buyout_auction_lot(self, auction_id: str, lot_id: str) -> int:
        state = self.get_state()
        auction = next((a for a in state.auctions.values() if a.id == auction_id), None)
        if not auction:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="未找到拍卖行")
        if auction.location_id != state.player.current_location:
            raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="需要前往拍卖行所在地")
        lot = next((l for l in auction.listings if l.id == lot_id), None)
        if not lot:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="未找到拍品")
        if lot.buyout_price is None:
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="该拍品不支持一口价")
        price = lot.buyout_price
        if state.player.spirit_stones < price:
            raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="灵石不足，无法买断")
        # 扣费、移除拍品、入背包
        state.player.spirit_stones -= price
        auction.listings = [l for l in auction.listings if l.id != lot_id]
        self._add_inventory(lot.id, lot.lot_name, lot.category, 1, lot.description)
        # 记录事件
        now = datetime.now(UTC)
        chronicle = ChronicleLog(
            id=f"auction-{now.strftime('%Y%m%d%H%M%S')}-{lot.id}",
            title=f"拍卖成交 · {lot.lot_name}",
            timestamp=now,
            summary=f"在拍卖行以 {price} 灵石一口价购得 {lot.lot_name}。",
            tags=["交易", "拍卖"],
        )
        state.chronicle_logs.insert(0, chronicle)
        del state.chronicle_logs[self._max_chronicle_entries :]
        self._store.update_state(state)
        return price

    # 升阶资格 ------------------------------------------------------------
    def ascension_eligible(self) -> bool:
        """简化规则：ascension_progress.stage 包含“炼气”视为可开启；凡人阶段禁止。"""
        stage = self.get_state().player.profile.ascension_progress.stage
        return "炼气" in stage


class MemoryRepository:
    """简单的内存记忆仓库，支持附加与基于关键词的检索。"""

    _max_records = 512

    def __init__(self) -> None:
        self._records: List[MemoryRecord] = []

    def clear(self) -> None:
        """清空所有记忆记录（用于开发/调试环境的数据重置）。"""
        self._records.clear()

    def append(self, payload: MemoryAppendRequest) -> MemoryRecord:
        normalized_tags = [tag.strip() for tag in payload.tags if tag.strip()]
        normalized_tags = list(dict.fromkeys(normalized_tags))
        record = MemoryRecord(
            id=str(uuid4()),
            subject=payload.subject,
            content=payload.content,
            category=payload.category,
            tags=normalized_tags,
            importance=payload.importance,
            created_at=datetime.now(UTC),
        )
        self._records.insert(0, record)
        del self._records[self._max_records :]
        return record

    def search(self, query: str, limit: int = 10) -> List[MemoryRecord]:
        limit = max(1, min(limit, self._max_records))
        if not query.strip():
            return self._records[:limit]

        normalized = query.strip().lower()
        scored: List[tuple[int, MemoryRecord]] = []
        for record in self._records:
            score = 0
            haystacks = [record.subject, record.content]
            if record.tags:
                haystacks.extend(record.tags)
            for text in haystacks:
                if normalized in text.lower():
                    score += 1
            if score:
                scored.append((score, record))
        scored.sort(key=lambda item: (item[0], item[1].created_at), reverse=True)
        return [record for _, record in scored[:limit]]

