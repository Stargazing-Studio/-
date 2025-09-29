from __future__ import annotations

import json
import logging
from datetime import UTC, datetime
import os

from .ai import GeminiClient
from .prompts import INIT_WORLD_PROMPT
from .world_state import WorldState, WorldStateStore

logger = logging.getLogger("lingyan.world.initializer")


class WorldInitializer:
    def __init__(self, store: WorldStateStore, gemini: GeminiClient) -> None:
        self._store = store
        self._gemini = gemini

    # 是否强制仅由 AI 生成世界（不允许回退初始数据）
    def ai_seed_only(self) -> bool:
        return os.environ.get("AI_SEED_ONLY", "true").strip().lower() in {
            "1",
            "true",
            "yes",
            "on",
        }

    async def ensure_world_loaded(self) -> None:
        if self._store.has_state():
            return

        # 强制仅使用 AI 生成，失败则抛错，不使用任何内置内容
        if not self._gemini.available:
            raise RuntimeError("Gemini 未就绪，无法生成初始世界（不使用内置内容）")

        seed_text = await self._gemini.generate_world_seed(INIT_WORLD_PROMPT)
        if not seed_text:
            raise RuntimeError("Gemini 未返回世界种子（不使用内置内容）")
        parsed = self._parse_world_seed(seed_text)
        if not parsed:
            raise RuntimeError("世界种子解析失败（不使用内置内容）")
        # 严格校验地图与拼接规范
        self._validate_world_integrity(parsed)
        logger.info("World state initialised via Gemini (AI-only mode)")
        self._store.set_state(parsed)

    async def regenerate_world_via_ai(self) -> bool:
        """尝试通过 Gemini 重建世界状态，成功返回 True。"""
        if not self._gemini.available:
            return False
        seed_text = await self._gemini.generate_world_seed(INIT_WORLD_PROMPT)
        if not seed_text:
            return False
        parsed = self._parse_world_seed(seed_text)
        if not parsed:
            return False
        self._validate_world_integrity(parsed)
        self._store.set_state(parsed)
        logger.info("World state regenerated via Gemini")
        return True

    def _parse_world_seed(self, text: str) -> WorldState | None:
        try:
            json_str = self._extract_json(text)
            data = json.loads(json_str)
            state = WorldState.model_validate(data)
            state.last_updated = datetime.now(UTC)
            return state
        except Exception:  # pragma: no cover - AI 返回异常数据
            logger.exception("Invalid world seed JSON")
            return None

    @staticmethod
    def _extract_json(text: str) -> str:
        text = text.strip()
        if text.startswith("{") and text.endswith("}"):
            return text
        start = text.find("{")
        end = text.rfind("}")
        if start == -1 or end == -1:
            raise ValueError("No JSON object found in Gemini response")
        return text[start : end + 1]

    # ===== 严格校验（AI-only，无内置内容与自动补全） =====
    def _validate_world_integrity(self, state: WorldState) -> None:
        # 1) 节点与连接合法性
        nodes = state.map_state.nodes
        node_ids = {n.id for n in nodes}
        if len(node_ids) != len(nodes):
            raise RuntimeError("地图节点 id 不可重复")
        for n in nodes:
            if not (0.0 <= n.coords.x <= 1.0 and 0.0 <= n.coords.y <= 1.0):
                raise RuntimeError(f"节点 {n.id} 坐标必须在 [0,1]×[0,1]")
            # connections 使用 id 且对称
            for c in n.connections:
                if c not in node_ids:
                    raise RuntimeError(f"节点 {n.id} 的连接 {c} 不存在")
        # 对称性检查
        conn_map = {n.id: set(n.connections) for n in nodes}
        for a, outs in conn_map.items():
            for b in outs:
                if a not in conn_map.get(b, set()):
                    raise RuntimeError(f"连接不对称：{a}->{b} 但缺少 {b}->{a}")

        # 2) tile 拼接校验（必须提供，不自动补全）
        style = state.map_state.style
        extras = getattr(style, "extras", None)
        if not extras or not isinstance(extras, dict):
            raise RuntimeError("map_state.style.extras 缺失，必须提供 tiles 规范")
        grid = extras.get("tile_grid")
        tiles = extras.get("tiles")
        if not isinstance(grid, dict) or not isinstance(tiles, list) or not tiles:
            raise RuntimeError("缺少 tile_grid/tiles，AI 需完整生成可拼接地图配置")
        cols = int(grid.get("cols", 0))
        rows = int(grid.get("rows", 0))
        if cols < 2 or rows < 2 or cols > 6 or rows > 6:
            raise RuntimeError("tile_grid.cols/rows 必须在 2..6 范围内")

        # 3) tiles 覆盖与不重叠校验
        # 3.1 矩形严格重叠检测（边界接触不算重叠）
        def _bbox(t):
            b = t.get("bbox") or {}
            return (
                t.get("id", "<unknown>"),
                float(b.get("x0", -1)),
                float(b.get("y0", -1)),
                float(b.get("x1", -1)),
                float(b.get("y1", -1)),
            )

        rects = [_bbox(t) for t in tiles]
        for idx_a in range(len(rects)):
            id_a, ax0, ay0, ax1, ay1 = rects[idx_a]
            if not (0.0 <= ax0 < ax1 <= 1.0 and 0.0 <= ay0 < ay1 <= 1.0):
                raise RuntimeError(f"tile {id_a} 的 bbox 越界或无效")
            for idx_b in range(idx_a + 1, len(rects)):
                id_b, bx0, by0, bx1, by1 = rects[idx_b]
                # 开区间重叠：边界重合不算
                overlap_x = ax0 < bx1 and ax1 > bx0
                overlap_y = ay0 < by1 and ay1 > by0
                # 若仅在边或点接触（ax1==bx0 或 ay1==by0）不算重叠。
                touch_x = ax1 == bx0 or bx1 == ax0
                touch_y = ay1 == by0 or by1 == ay0
                if overlap_x and overlap_y and not (touch_x or touch_y):
                    raise RuntimeError(f"tiles 存在重叠区域：{id_a} 与 {id_b}")

        # 3.2 采样覆盖校验（避免空白区域）。为避免边界双计，采用半开区间判断。
        N = 24
        eps = 1e-9
        def _contains_half_open(t, x, y):
            b = t.get("bbox") or {}
            x0 = float(b.get("x0", -1))
            y0 = float(b.get("y0", -1))
            x1 = float(b.get("x1", -1))
            y1 = float(b.get("y1", -1))
            # 半开区间：左上包含，右下排除（避免边界双计）。
            return (x0 - eps) <= x < (x1 - eps) and (y0 - eps) <= y < (y1 - eps)

        for i in range(N + 1):
            for j in range(N + 1):
                # 将 1.0 轻微内缩，避免采样落在右/下边界造成无归属
                x = i / N
                y = j / N
                if abs(x - 1.0) < eps:
                    x = 1.0 - 2 * eps
                if abs(y - 1.0) < eps:
                    y = 1.0 - 2 * eps
                hit = 0
                for t in tiles:
                    if _contains_half_open(t, x, y):
                        hit += 1
                        if hit > 1:
                            # 由于半开区间策略，命中>1 仍然意味着实质重叠
                            ids = [tt.get("id", "<unknown>") for tt in tiles if _contains_half_open(tt, x, y)]
                            raise RuntimeError(f"tiles 存在重叠区域（采样点 {x:.3f},{y:.3f}）：{ids}")
                if hit == 0:
                    raise RuntimeError(f"tiles 未完全覆盖全图（采样点 {x:.3f},{y:.3f} 无归属）")

        # 4) 每个节点必须落在某个 tile 中
        for n in nodes:
            inside = any(_contains_half_open(t, n.coords.x, n.coords.y) for t in tiles)
            if not inside:
                raise RuntimeError(f"节点 {n.id} 未落在任何 tile bbox 内")
