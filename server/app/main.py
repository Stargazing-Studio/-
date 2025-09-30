from __future__ import annotations

from contextlib import asynccontextmanager
import logging
from typing import List
from datetime import UTC, datetime
from pathlib import Path
import os
import uuid
import re

from fastapi import FastAPI, HTTPException, Query, WebSocket, WebSocketDisconnect, Request, Response
from fastapi.encoders import jsonable_encoder
from fastapi.middleware.cors import CORSMiddleware

from .ai import GeminiClient
from .data import GameRepository, MemoryRepository, PlayerStore
from .events import MultiChannelEventBroker
from .initializer import WorldInitializer
from .schemas import (
    AscensionChallenge,
    AuctionHouseResponse,
    ChronicleLog,
    ChronicleStreamSnapshot,
    ChronicleStreamUpdate,
    CommandRequest,
    CommandResponse,
    CommandResult,
    Companion,
    EventBroadcastRequest,
    MapNodeView,
    MapViewResponse,
    MemoryAppendRequest,
    MemoryRecord,
    MemorySearchResponse,
    PillRecipe,
    PlayerProfile,
    SecretRealm,
    ShopResponse,
    ShopPurchaseRequest,
    ShopPurchaseResponse,
    AuctionBuyRequest,
    AuctionBuyResponse,
    InventoryEntryResponse,
    AscensionEligibilityResponse,
    WalletResponse,
    TravelRequest,
    TravelResponse,
)
from .world_state import WorldStateStore, PlayerState
from .prompts import INIT_PLAYER_PROMPT

logger = logging.getLogger("lingyan.server")


def _load_env_from_file(env_path: Path) -> None:
    """简易 .env 加载器：在未设置的情况下从文件写入环境变量。

    - 仅解析 KEY=VALUE 行，忽略空行与以 # 开头的注释。
    - 不覆盖现有的 os.environ 值。
    """
    try:
        if not env_path.exists():
            return
        for raw in env_path.read_text(encoding="utf-8").splitlines():
            line = raw.strip()
            if not line or line.startswith("#"):
                continue
            if "=" not in line:
                continue
            k, v = line.split("=", 1)
            k = k.strip()
            v = v.strip().strip('"').strip("'")
            if k and k not in os.environ:
                os.environ[k] = v
    except Exception:
        # 加载失败不影响启动，仅记录
        logging.getLogger("lingyan.server").debug(".env load skipped/failed", exc_info=True)


def create_app() -> FastAPI:
    # 优先加载 server/.env 以配置 GEMINI_API_KEY 等
    _load_env_from_file(Path(__file__).resolve().parent.parent / ".env")
    store = WorldStateStore()
    gemini = GeminiClient.from_environment()
    initializer = WorldInitializer(store, gemini)
    repository = GameRepository(store)
    memory_repository = MemoryRepository()
    broker = MultiChannelEventBroker()
    players = PlayerStore(Path(__file__).resolve().parent.parent / "players")

    @asynccontextmanager
    async def lifespan(app: FastAPI):
        # 在应用生命周期启动时确保世界数据已加载
        await initializer.ensure_world_loaded()
        yield

    app = FastAPI(title="LingYan TianJi API", version="0.4.0", lifespan=lifespan)

    app.state.event_broker = broker
    app.state.game_repository = repository
    app.state.memory_repository = memory_repository
    app.state.gemini_client = gemini
    app.state.world_initializer = initializer
    app.state.player_store = players

    # 重要：当 allow_credentials=True 时，CORS 不允许 "*"。否则浏览器会直接拦截并显示 status=null。
    # 这里改为基于正则放行本地开发来源（localhost/127.0.0.1 任意端口）。
    origin_regex = os.environ.get(
        "ALLOWED_ORIGIN_REGEX",
        r"^https?://(localhost|127\.0\.0\.1)(:\d+)?$",
    )
    app.add_middleware(
        CORSMiddleware,
        allow_origin_regex=origin_regex,
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )

    @app.get("/diagnose/ai")
    async def diagnose_ai() -> dict:
        gemini_client: GeminiClient = app.state.gemini_client
        has_key = bool(os.environ.get("GEMINI_API_KEY"))
        return {
            "env": {"GEMINI_API_KEY": has_key},
            "gemini": {"available": gemini_client.available, "model": gemini_client.model_name},
            "hint": "若 available=false，请检查 .env 中 GEMINI_API_KEY、网络/地区与模型名是否受支持。",
        }

    @app.get("/whoami")
    async def whoami(request: Request, response: Response) -> dict[str, str]:
        pid = request.cookies.get("player_id")
        if not pid:
            import uuid
            pid = uuid.uuid4().hex
            response.set_cookie("player_id", pid, httponly=True, samesite="lax")
        return {"player_id": pid}

    @app.get("/health")
    async def health_check() -> dict[str, str]:
        return {"status": "ok", "message": "DaoCore 连接成功。"}

    @app.get("/profile", response_model=PlayerProfile)
    async def get_profile(request: Request, response: Response) -> PlayerProfile:
        players: PlayerStore = app.state.player_store
        pid = request.cookies.get("player_id")
        if not pid:
            import uuid
            pid = uuid.uuid4().hex
            response.set_cookie("player_id", pid, httponly=True, samesite="lax")
        if not players.exists(pid):
            # 首次进入：完全由 AI 生成玩家数据（不同设备→使用 pid 作为签名引导差异化），并生成“初试事件”
            gemini_client: GeminiClient = app.state.gemini_client
            if not gemini_client.available:
                raise HTTPException(status_code=503, detail="AI 未就绪，无法生成角色数据；请配置 .env/GEMINI_API_KEY 或访问 /diagnose/ai 排查。")

            # 若世界在运行期被清空（如 /admin/purge?rebuild=false），尝试自动重建
            try:
                world = repository.get_state()
            except RuntimeError:
                ok = False
                try:
                    ok = await initializer.regenerate_world_via_ai()
                except Exception as e:
                    raise HTTPException(status_code=503, detail=f"世界未初始化，且自动重建失败：{e}")
                if not ok:
                    raise HTTPException(status_code=503, detail="世界未初始化，且自动重建失败：请使用 /admin/purge?rebuild=true 或检查 AI 配置")
                world = repository.get_state()
            node_ids = [n.id for n in world.map_state.nodes]
            # 提供精简节点清单给 AI 选择合法起点
            nodes_brief = "\n".join([f"- {n.id}" for n in world.map_state.nodes])
            # 注意：INIT_PLAYER_PROMPT 内含大量 JSON 花括号，避免使用 str.format 造成 KeyError
            prompt = (
                INIT_PLAYER_PROMPT
                .replace("{nodes_brief}", nodes_brief)
                .replace("{seed_hint}", pid[:12])
            )

            # 生成并解析 PlayerState JSON
            text = await gemini_client.generate_player_state_text(prompt)
            if not text:
                raise HTTPException(status_code=503, detail="AI 未返回玩家数据")

            def _extract_json(s: str) -> str:
                s = s.strip()
                if s.startswith("{") and s.endswith("}"):
                    return s
                a, b = s.find("{"), s.rfind("}")
                if a == -1 or b == -1:
                    raise ValueError("AI 返回不含 JSON")
                return s[a : b + 1]

            import json as _json
            try:
                parsed = _json.loads(_extract_json(text))
            except Exception as e:
                raise HTTPException(status_code=503, detail=f"玩家数据解析失败：{e}")

            def _slug(s: str, prefix: str) -> str:
                s = (s or "").strip()
                base = re.sub(r"[^a-zA-Z0-9]+", "_", s).strip("_").lower() or prefix
                return f"{prefix}_{base}"[:48]

            def _ensure_int(x, default: int = 0) -> int:
                try:
                    if isinstance(x, bool):
                        return default
                    return int(x)
                except Exception:
                    return default

            def _normalize_player_state(data: dict, node_ids: list[str], pid: str) -> dict:
                out: dict = {}
                prof = data.get("profile") or {}
                # 基本档案
                name = prof.get("name") or "无名"
                out_profile = {
                    "id": prof.get("id") or f"p_{pid[:8]}",
                    "name": name,
                    "realm": str(prof.get("realm") or "凡人九品"),
                    "guild": prof.get("guild") or "",
                    "faction_reputation": prof.get("faction_reputation") or {},
                    "attributes": prof.get("attributes") or {},
                }
                # techniques: 允许 dict{name: mastery}
                tech = prof.get("techniques")
                tech_list = []
                if isinstance(tech, list):
                    for t in tech:
                        if not isinstance(t, dict):
                            continue
                        tname = t.get("name") or t.get("id") or "无名术"
                        tech_list.append({
                            "id": t.get("id") or _slug(tname, "tech"),
                            "name": tname,
                            "type": t.get("type") or "support",
                            "mastery": _ensure_int(t.get("mastery"), 1),
                            "synergies": t.get("synergies") or [],
                        })
                elif isinstance(tech, dict):
                    for tname, lvl in tech.items():
                        tech_list.append({
                            "id": _slug(str(tname), "tech"),
                            "name": str(tname),
                            "type": "support",
                            "mastery": _ensure_int(lvl, 1),
                            "synergies": [],
                        })
                out_profile["techniques"] = tech_list
                out_profile["achievements"] = prof.get("achievements") or []
                ap = prof.get("ascension_progress") or {}
                out_profile["ascension_progress"] = {
                    "stage": ap.get("stage") or str(prof.get("realm") or "凡人九品"),
                    "score": _ensure_int(ap.get("score"), 0),
                    "next_milestone": ap.get("next_milestone") or "炼气一阶",
                }
                out["profile"] = out_profile

                # 位置
                loc = data.get("current_location")
                if isinstance(loc, dict):
                    loc = loc.get("id")
                if not isinstance(loc, str) or not loc:
                    loc = node_ids[0] if node_ids else ""
                out["current_location"] = loc

                # 资源、血量
                out["spirit_stones"] = _ensure_int(data.get("spirit_stones"), 20)
                out["blood_percent"] = _ensure_int(data.get("blood_percent"), 100)

                # 背包
                inv = data.get("inventory") or []
                inv_list = []
                if isinstance(inv, list):
                    for it in inv:
                        if not isinstance(it, dict):
                            continue
                        iname = it.get("name") or "无名物"
                        cat = it.get("category") or it.get("type") or "杂物"
                        inv_list.append({
                            "id": it.get("id") or _slug(iname, "item"),
                            "name": iname,
                            "category": str(cat),
                            "quantity": _ensure_int(it.get("quantity"), 1),
                            "description": str(it.get("description") or ""),
                        })
                out["inventory"] = inv_list
                return out

            try:
                normalized = _normalize_player_state(parsed, node_ids, pid)
                pstate = PlayerState.model_validate(normalized)
            except Exception as e:
                raise HTTPException(status_code=503, detail=f"玩家数据解析失败：{e}")

            # 兜底：若 current_location 非法，则回退为首个已知节点
            if not pstate.current_location or pstate.current_location not in node_ids:
                pstate.current_location = node_ids[0] if node_ids else world.player.current_location

            # 保存到独立玩家存档
            players.save(pid, pstate)

            # 生成“初试事件”，写入世界编年史并广播（标签含“初试事件”）
            try:
                loc = next((n for n in world.map_state.nodes if n.id == pstate.current_location), None)
                location_name = loc.name if loc else pstate.current_location
                summary = await gemini_client.generate_initial_event_summary(
                    player_name=pstate.profile.name,
                    realm=pstate.profile.realm,
                    guild=pstate.profile.guild,
                    location_name=location_name,
                    seed_hint=pid,
                )
            except Exception:
                summary = None
            from datetime import UTC, datetime as _dt
            if not summary:
                summary = (
                    f"命轮初启。{pstate.profile.name} 出身凡俗（{pstate.profile.realm}，{pstate.profile.guild}），"
                    f"初临 {location_name}。此时机缘若隐，风物有兆，心念所向，尚需自择其途。汝当如何抉择？"
                )
            ev = ChronicleLog(
                id=f"init-{_dt.now(UTC).strftime('%Y%m%d%H%M%S')}-{pid[:6]}",
                title=f"命轮初启 · {pstate.profile.name}",
                timestamp=_dt.now(UTC),
                summary=summary,
                tags=["初试事件", location_name],
            )
            # 写入玩家独立日志并仅向该玩家频道广播
            players.append_log(pid, ev)
            # 同步写入对话记录，作为系统开场消息（玩家气泡可忽略显示）
            init_cmd = CommandResult(
                id=f"cmdinit-{_dt.now(UTC).strftime('%Y%m%d%H%M%S')}-{pid[:6]}",
                content="",
                feedback=summary,
                created_at=_dt.now(UTC),
            )
            players.append_command(pid, init_cmd)
            await broker.broadcast(f"chronicles:{pid}", jsonable_encoder(ChronicleStreamUpdate(log=ev)))
        return players.load(pid).profile

    @app.get("/companions", response_model=List[Companion])
    async def list_companions() -> List[Companion]:
        return repository.list_companions()

    @app.get("/secret-realms", response_model=List[SecretRealm])
    async def list_secret_realms() -> List[SecretRealm]:
        return repository.list_secret_realms()

    @app.get("/ascension/challenges", response_model=List[AscensionChallenge])
    async def list_ascension_challenges() -> List[AscensionChallenge]:
        return repository.list_ascension_challenges()

    @app.get("/alchemy/recipes", response_model=List[PillRecipe])
    async def list_pill_recipes() -> List[PillRecipe]:
        return repository.list_pill_recipes()

    @app.get("/chronicles", response_model=List[ChronicleLog])
    async def list_chronicles(request: Request) -> List[ChronicleLog]:
        players: PlayerStore = app.state.player_store
        pid = request.cookies.get("player_id")
        if pid and players.exists(pid):
            return players.list_logs(pid)
        return []

    @app.get("/commands/history", response_model=List[CommandResult])
    async def list_command_history(request: Request) -> List[CommandResult]:
        players: PlayerStore = app.state.player_store
        pid = request.cookies.get("player_id")
        if pid and players.exists(pid):
            return players.list_commands(pid)
        return []

    @app.get("/location/current", response_model=MapNodeView)
    async def current_location(request: Request, response: Response) -> MapNodeView:
        players: PlayerStore = app.state.player_store
        pid = request.cookies.get("player_id")
        if not pid:
            import uuid
            pid = uuid.uuid4().hex
            response.set_cookie("player_id", pid, httponly=True, samesite="lax")
        if not players.exists(pid):
            raise HTTPException(status_code=400, detail="未初始化玩家，请先访问 /profile")
        pstate = players.load(pid)
        node = next((n for n in repository.get_state().map_state.nodes if n.id == pstate.current_location), None)
        if not node:
            raise HTTPException(status_code=404, detail="未知地点")
        return MapNodeView(**node.model_dump())

    @app.get("/map", response_model=MapViewResponse)

    async def fetch_map() -> MapViewResponse:
        return MapViewResponse(**repository.get_map_view())

    @app.post("/travel", response_model=TravelResponse)
    async def travel(req: Request, resp: Response, request: TravelRequest) -> TravelResponse:
        players: PlayerStore = app.state.player_store
        pid = req.cookies.get("player_id")
        if not pid:
            import uuid
            pid = uuid.uuid4().hex
            resp.set_cookie("player_id", pid, httponly=True, samesite="lax")
        if not players.exists(pid):
            raise HTTPException(status_code=400, detail="未初始化玩家，请先访问 /profile")
        pstate = players.load(pid)
        world = repository.get_state()
        target = next((n for n in world.map_state.nodes if n.id == request.location_id), None)
        if not target:
            raise HTTPException(status_code=404, detail="未知地点")
        current_node = next((n for n in world.map_state.nodes if n.id == pstate.current_location), None)
        if current_node and request.location_id not in current_node.connections:
            raise HTTPException(status_code=400, detail="无法直接前往该地点")
        pstate.current_location = request.location_id
        players.save(pid, pstate)
        return TravelResponse(profile=pstate.profile, current_location=pstate.current_location)

    @app.get("/shops/current", response_model=List[ShopResponse])
    async def shops_at_location(request: Request, response: Response) -> List[ShopResponse]:
        players: PlayerStore = app.state.player_store
        pid = request.cookies.get("player_id")
        if not pid:
            import uuid
            pid = uuid.uuid4().hex
            response.set_cookie("player_id", pid, httponly=True, samesite="lax")
        if not players.exists(pid):
            raise HTTPException(status_code=400, detail="未初始化玩家，请先访问 /profile")
        pstate = players.load(pid)
        shops = [s for s in repository.get_state().shops.values() if s.location_id == pstate.current_location]
        return [ShopResponse(**shop.model_dump()) for shop in shops]

    @app.get("/shops/{shop_id}", response_model=ShopResponse)
    async def shop_detail(shop_id: str) -> ShopResponse:
        shop = repository.get_shop(shop_id)
        return ShopResponse(**shop.model_dump())

    @app.post("/shops/{shop_id}/purchase", response_model=ShopPurchaseResponse, status_code=201)
    async def shop_purchase(request: Request, response: Response, shop_id: str, payload: ShopPurchaseRequest) -> ShopPurchaseResponse:
        players: PlayerStore = app.state.player_store
        pid = request.cookies.get("player_id")
        if not pid:
            import uuid
            pid = uuid.uuid4().hex
            response.set_cookie("player_id", pid, httponly=True, samesite="lax")
        if not players.exists(pid):
            raise HTTPException(status_code=400, detail="未初始化玩家，请先访问 /profile")
        pstate = players.load(pid)
        world = repository.get_state()
        shop = world.shops.get(shop_id)
        if not shop:
            raise HTTPException(status_code=404, detail="未找到商铺")
        if shop.location_id != pstate.current_location:
            raise HTTPException(status_code=403, detail="需要前往商铺所在地")
        item = next((x for x in shop.inventory if x.id == payload.item_id), None)
        if not item:
            raise HTTPException(status_code=404, detail="商品不存在")
        if item.stock < payload.quantity:
            raise HTTPException(status_code=400, detail="库存不足")
        total = item.price * payload.quantity
        if pstate.spirit_stones < total:
            raise HTTPException(status_code=403, detail="灵石不足，无法购买")
        pstate.spirit_stones -= total
        item.stock -= payload.quantity
        merged = False
        for ent in pstate.inventory:
            if ent.id == item.id:
                ent.quantity += payload.quantity
                merged = True
                break
        if not merged:
            from .world_state import InventoryEntry
            pstate.inventory.append(InventoryEntry(id=item.id, name=item.name, category=item.category, quantity=payload.quantity, description=item.description))
        players.save(pid, pstate)
        now = datetime.now(UTC)
        ev = ChronicleLog(id=f"shop-{now.strftime('%Y%m%d%H%M%S')}-{item.id}", title=f"购入 · {item.name}", timestamp=now, summary=f"玩家({pid[:6]})在商铺购入 {payload.quantity} × {item.name}，花费 {total} 灵石。", tags=["交易", "商铺"]) 
        players.append_log(pid, ev)
        await broker.broadcast(f"chronicles:{pid}", jsonable_encoder(ChronicleStreamUpdate(log=ev)))
        inv = [InventoryEntryResponse(**i.model_dump()) for i in pstate.inventory]
        return ShopPurchaseResponse(spent=total, profile=pstate.profile, inventory=inv)

    @app.get("/auctions/current", response_model=AuctionHouseResponse | None)
    async def auction_at_location(request: Request, response: Response) -> AuctionHouseResponse | None:
        players: PlayerStore = app.state.player_store
        pid = request.cookies.get("player_id")
        if not pid:
            import uuid
            pid = uuid.uuid4().hex
            response.set_cookie("player_id", pid, httponly=True, samesite="lax")
        if not players.exists(pid):
            players.create_from_world(pid, store.state)
        pstate = players.load(pid)
        auction = next((a for a in repository.get_state().auctions.values() if a.location_id == pstate.current_location), None)
        if auction is None:
            return None
        return AuctionHouseResponse(**auction.model_dump())

    @app.post("/auctions/{auction_id}/buy", response_model=AuctionBuyResponse, status_code=201)
    async def auction_buy(request: Request, response: Response, auction_id: str, payload: AuctionBuyRequest) -> AuctionBuyResponse:
        players: PlayerStore = app.state.player_store
        pid = request.cookies.get("player_id")
        if not pid:
            import uuid
            pid = uuid.uuid4().hex
            response.set_cookie("player_id", pid, httponly=True, samesite="lax")
        if not players.exists(pid):
            raise HTTPException(status_code=400, detail="未初始化玩家，请先访问 /profile")
        pstate = players.load(pid)
        world = repository.get_state()
        auction = next((a for a in world.auctions.values() if a.id == auction_id), None)
        if not auction:
            raise HTTPException(status_code=404, detail="未找到拍卖行")
        if auction.location_id != pstate.current_location:
            raise HTTPException(status_code=403, detail="需要前往拍卖行所在地")
        lot = next((l for l in auction.listings if l.id == payload.lot_id), None)
        if not lot:
            raise HTTPException(status_code=404, detail="未找到拍品")
        if lot.buyout_price is None:
            raise HTTPException(status_code=400, detail="该拍品不支持一口价")
        price = lot.buyout_price
        if pstate.spirit_stones < price:
            raise HTTPException(status_code=403, detail="灵石不足，无法买断")
        pstate.spirit_stones -= price
        auction.listings = [l for l in auction.listings if l.id != payload.lot_id]
        from .world_state import InventoryEntry
        pstate.inventory.append(InventoryEntry(id=lot.id, name=lot.lot_name, category=lot.category, quantity=1, description=lot.description))
        players.save(pid, pstate)
        now = datetime.now(UTC)
        ev = ChronicleLog(id=f"auction-{now.strftime('%Y%m%d%H%M%S')}-{lot.id}", title=f"拍卖成交 · {lot.lot_name}", timestamp=now, summary=f"玩家({pid[:6]})在拍卖行以 {price} 灵石一口价购得 {lot.lot_name}。", tags=["交易", "拍卖"]) 
        players.append_log(pid, ev)
        await broker.broadcast(f"chronicles:{pid}", jsonable_encoder(ChronicleStreamUpdate(log=ev)))
        inv = [InventoryEntryResponse(**i.model_dump()) for i in pstate.inventory]
        return AuctionBuyResponse(spent=price, profile=pstate.profile, inventory=inv)

    @app.post("/commands", response_model=CommandResponse)
    async def submit_command(request: Request, response: Response, payload: CommandRequest) -> CommandResponse:
        gemini_client: GeminiClient = app.state.gemini_client
        if not gemini_client.available:
            raise HTTPException(
                status_code=503,
                detail="天机灵枢暂未接通，请稍后再试",
            )

        try:
            # 构造对话上下文（最近3轮 + 旧历史压缩）
            # 构造对话上下文（最近3轮 + 旧历史压缩 + 同域玩家）
            players: PlayerStore = app.state.player_store
            pid = request.cookies.get("player_id") or ""
            if not pid:
                import uuid
                pid = uuid.uuid4().hex
                response.set_cookie("player_id", pid, httponly=True, samesite="lax")
            if not players.exists(pid):
                # 未初始化时不再返回 400，直接给出友好占位反馈，避免前端提示“未就绪”阻断流程
                now = datetime.now(UTC)
                command = CommandResult(
                    id=f"cmd-{now.strftime('%Y%m%d%H%M%S')}-{pid[:6]}",
                    content=payload.content,
                    feedback="指令通道未就绪：请先点击“开始修行”完成初始化。",
                    created_at=now,
                )
                chronicle = ChronicleLog(
                    id=f"log-{now.strftime('%Y%m%d%H%M%S')}-{pid[:6]}",
                    title="指令通道未就绪",
                    timestamp=now,
                    summary="请先完成初始化（开始修行），以接通天机。",
                    tags=["指令", "未就绪"],
                )
                return CommandResponse(result=command, emitted_log=chronicle)
            # 使用玩家个人指令历史
            history = players.list_commands(pid)
            recent = history[:3]
            older = history[3:]
            transcript_recent = "\n".join([
                f"玩家：{c.content}\n天机：{c.feedback}" for c in reversed(recent)
            ])
            summary_block = None
            if older:
                transcript_older = "\n".join([
                    f"玩家：{c.content}\n天机：{c.feedback}" for c in reversed(older)
                ])
                summary_block = await gemini_client.summarize_dialogue(transcript_older)
                if summary_block:
                    try:
                        app.state.memory_repository.append(
                            MemoryAppendRequest(
                                subject="会话压缩",
                                content=summary_block,
                                category="context",
                                tags=["ai", "summary"],
                                importance=10,
                            )
                        )
                    except Exception:
                        pass
            # 同域玩家（用于相遇叙事，不得泄露隐私，仅提供称谓/姓名）
            pstate = players.load(pid)
            co_players = players.list_players_at(pstate.current_location, exclude_pid=pid)
            others_label = ", ".join([ps.profile.name for _, ps in co_players][:5]) if co_players else ""
            presence_block = f"【同域修行者】{others_label}" if others_label else ""

            context_text = "".join([
                f"【旧历史压缩】{summary_block}\n\n" if summary_block else "",
                f"【最近三轮】\n{transcript_recent}\n" if transcript_recent else "",
                f"{presence_block}\n" if presence_block else "",
            ]) + (f"【最近三轮】\n{transcript_recent}" if transcript_recent else "")

            feedback = await gemini_client.generate_command_feedback(
                payload.content, context=context_text or None
            )
        except Exception as exc:  # pragma: no cover - 防御性捕获
            logger.exception("Gemini feedback failed")
            raise HTTPException(
                status_code=503,
                detail=f"天机推演失败：{exc}",
            )

        if not feedback or not feedback.strip():
            raise HTTPException(
                status_code=503,
                detail="天机灵枢未返回有效内容，请稍后再试",
            )

        # 写入玩家独立指令历史与事件日志
        now = datetime.now(UTC)
        command = CommandResult(
            id=f"cmd-{now.strftime('%Y%m%d%H%M%S')}-{pid[:6]}",
            content=payload.content,
            feedback=feedback,
            created_at=now,
        )
        chronicle = ChronicleLog(
            id=f"log-{now.strftime('%Y%m%d%H%M%S')}-{pid[:6]}",
            title=f"指令回响 · {pstate.current_location}",
            timestamp=now,
            summary=feedback,
            tags=["指令", pstate.current_location],
        )
        players.append_command(pid, command)
        players.append_log(pid, chronicle)
        await broker.broadcast(
            f"chronicles:{pid}",
            jsonable_encoder(ChronicleStreamUpdate(log=chronicle)),
        )
        logger.info("command for %s handled", pid[:6])
        return CommandResponse(result=command, emitted_log=chronicle)

    @app.post("/memories", response_model=MemoryRecord, status_code=201)
    async def append_memory(payload: MemoryAppendRequest) -> MemoryRecord:
        record = memory_repository.append(payload)
        return record

    @app.get("/inventory", response_model=list[InventoryEntryResponse])
    async def get_inventory(request: Request, response: Response) -> list[InventoryEntryResponse]:
        players: PlayerStore = app.state.player_store
        pid = request.cookies.get("player_id")
        if not pid:
            import uuid
            pid = uuid.uuid4().hex
            response.set_cookie("player_id", pid, httponly=True, samesite="lax")
        if not players.exists(pid):
            raise HTTPException(status_code=400, detail="未初始化玩家，请先访问 /profile")
        pstate = players.load(pid)
        return [InventoryEntryResponse(**i.model_dump()) for i in pstate.inventory]

    @app.get("/ascension/eligibility", response_model=AscensionEligibilityResponse)
    async def ascension_eligibility(request: Request, response: Response) -> AscensionEligibilityResponse:
        players: PlayerStore = app.state.player_store
        pid = request.cookies.get("player_id")
        if not pid:
            import uuid
            pid = uuid.uuid4().hex
            response.set_cookie("player_id", pid, httponly=True, samesite="lax")
        # 未初始化玩家时返回“空值”而非 400，便于前端正常渲染
        if not players.exists(pid):
            return AscensionEligibilityResponse(eligible=False, required_realm="炼气一阶")
        pstate = players.load(pid)
        return AscensionEligibilityResponse(eligible=("炼气" in pstate.profile.ascension_progress.stage), required_realm="炼气一阶")

    @app.get("/wallet", response_model=WalletResponse)
    async def get_wallet(request: Request, response: Response) -> WalletResponse:
        players: PlayerStore = app.state.player_store
        pid = request.cookies.get("player_id")
        if not pid:
            import uuid
            pid = uuid.uuid4().hex
            response.set_cookie("player_id", pid, httponly=True, samesite="lax")
        if not players.exists(pid):
            raise HTTPException(status_code=400, detail="未初始化玩家，请先访问 /profile")
        pstate = players.load(pid)
        return WalletResponse(spirit_stones=pstate.spirit_stones)

    @app.get("/memories/search", response_model=MemorySearchResponse)
    async def search_memories(
        query: str = Query("", max_length=120, description="模糊匹配的关键词"),
        limit: int = Query(10, ge=1, le=50, description="返回条数上限"),
    ) -> MemorySearchResponse:
        results = memory_repository.search(query, limit)
        return MemorySearchResponse(query=query, results=results)

    @app.get("/players/nearby")
    async def players_nearby(request: Request, response: Response) -> list[dict[str, str]]:
        players: PlayerStore = app.state.player_store
        pid = request.cookies.get("player_id")
        if not pid:
            import uuid
            pid = uuid.uuid4().hex
            response.set_cookie("player_id", pid, httponly=True, samesite="lax")
        if not players.exists(pid):
            raise HTTPException(status_code=400, detail="未初始化玩家，请先访问 /profile")
        pstate = players.load(pid)
        others = players.list_players_at(pstate.current_location, exclude_pid=pid)
        return [{"id": p[:6], "name": ps.profile.name} for p, ps in others]

    @app.post("/events/emit", status_code=202)
    async def emit_event(payload: EventBroadcastRequest) -> dict[str, str]:
        await broker.broadcast(payload.channel, payload.payload)
        return {"status": "ok"}

    # 管理接口：重置世界状态与游玩数据（开发/调试用途）
    @app.post("/admin/reset", status_code=202)
    async def admin_reset(scope: str = Query("world", pattern="^(world|players|all)$")) -> dict[str, str | list[str]]:
        """重置功能增强版。

        scope:
          - world: 仅重建世界（AI 生成），并尝试迁移现有玩家至新世界首个节点；
          - players: 仅清空所有玩家存档；
          - all: 同时重建世界并清空所有玩家存档。
        """
        changed: list[str] = []
        # 1) 清理玩家数据
        if scope in ("players", "all"):
            players.clear_all()
            changed.append("players_cleared")

        # 2) 重建世界
        if scope in ("world", "all"):
            try:
                ok = await initializer.regenerate_world_via_ai()
            except Exception as e:
                raise HTTPException(status_code=503, detail=f"世界重建失败：{e}")
            if not ok:
                raise HTTPException(
                    status_code=503,
                    detail="无法通过 Gemini 重建世界，请检查 API Key/地区支持/模型配置。",
                )
            changed.append("world_regenerated")
            memory_repository.clear()

            # 2.1 迁移存量玩家到新世界（仅当未清空玩家时）
            if scope == "world":
                node_ids = [n.id for n in repository.get_state().map_state.nodes]
                for pid in players.list_ids():
                    try:
                        pstate = players.load(pid)
                        if pstate.current_location not in node_ids and node_ids:
                            pstate.current_location = node_ids[0]
                            players.save(pid, pstate)
                            # 通知该玩家：世界已重铸
                            now = datetime.now(UTC)
                            ev = ChronicleLog(
                                id=f"world-{now.strftime('%Y%m%d%H%M%S')}-{pid[:6]}",
                                title="世界重铸",
                                timestamp=now,
                                summary="天机改换，山河重绘。你被安置于新世界的起点，请继续探索。",
                                tags=["系统", "世界重置"],
                            )
                            players.append_log(pid, ev)
                            await broker.broadcast(f"chronicles:{pid}", jsonable_encoder(ChronicleStreamUpdate(log=ev)))
                    except Exception:
                        continue

        return {"status": "ok", "changed": changed}

    # 便于浏览器直接触发（GET），功能等同于 POST /admin/reset
    @app.get("/admin/reset")
    async def admin_reset_get(scope: str = Query("world", pattern="^(world|players|all)$")) -> dict[str, str | list[str]]:
        try:
            return await admin_reset(scope)
        except HTTPException:
            raise
        except Exception as e:
            raise HTTPException(status_code=503, detail=f"世界重建失败：{e}")

    @app.post("/admin/purge", status_code=202)
    async def admin_purge(rebuild: bool = Query(False)) -> dict[str, str | list[str]]:
        """直接清除所有数据（不依赖 cookie）：删除所有玩家与世界存档；可选重建世界。

        - rebuild=false：仅清除；后续首次访问可通过 /profile 或服务重启时再生成世界。
        - rebuild=true：清除后立刻通过 AI 重建世界。
        """
        changed: list[str] = []
        # 清空玩家
        players.clear_all()
        changed.append("players_cleared")
        # 清空世界
        store.clear()
        changed.append("world_cleared")
        memory_repository.clear()
        try:
            # 广播空快照到通用频道（已连接的客户端可能无法收到私有频道）
            empty = jsonable_encoder(ChronicleStreamSnapshot(logs=[]))
            await broker.broadcast("chronicles", empty)
        except Exception:
            pass
        if rebuild:
            try:
                ok = await initializer.regenerate_world_via_ai()
            except Exception as e:
                raise HTTPException(status_code=503, detail=f"世界重建失败：{e}")
            if not ok:
                raise HTTPException(status_code=503, detail="无法通过 Gemini 重建世界")
            changed.append("world_regenerated")
        return {"status": "ok", "changed": changed}

    # 便于浏览器直接触发（GET 兼容）
    @app.get("/admin/purge")
    async def admin_purge_get(rebuild: bool = Query(False)) -> dict[str, str | list[str]]:
        return await admin_purge(rebuild)

    @app.post("/admin/reset/player", status_code=202)
    async def admin_reset_player(request: Request, response: Response) -> dict[str, str]:
        """仅清空当前玩家存档，便于在不影响他人的情况下重新开始。"""
        pid = request.cookies.get("player_id")
        if not pid:
            raise HTTPException(status_code=400, detail="未发现玩家身份（cookie 缺失）")
        players.delete_player(pid)
        # 推送空快照，刷新前端时间线
        try:
            snapshot = jsonable_encoder(ChronicleStreamSnapshot(logs=[]))
            await broker.broadcast(f"chronicles:{pid}", snapshot)
        except Exception:
            pass
        # 同时清除客户端 cookie，避免使用已被删除的身份继续访问
        try:
            response.delete_cookie("player_id")
        except Exception:
            pass
        return {"status": "ok", "message": "player cleared; cookie removed", "player_id": pid}

    # 便于浏览器直接触发（GET 兼容）
    @app.get("/admin/reset/player")
    async def admin_reset_player_get(request: Request, response: Response) -> dict[str, str]:
        return await admin_reset_player(request, response)

    @app.websocket("/ws/chronicles")
    async def chronicle_stream(websocket: WebSocket) -> None:
        # 根据 cookie 选择玩家私有频道；若无 cookie 则退化为全局空快照
        pid = websocket.cookies.get("player_id") if hasattr(websocket, "cookies") else None
        channel = f"chronicles:{pid}" if pid else "chronicles"
        # 构造该玩家的时间线快照
        try:
            if pid:
                logs = players.list_logs(pid)
            else:
                logs = []
        except Exception:
            logs = []
        snapshot_message = jsonable_encoder(ChronicleStreamSnapshot(logs=logs))
        await broker.connect(channel, websocket, [snapshot_message])
        try:
            while True:
                await websocket.receive_text()
        except WebSocketDisconnect:
            await broker.disconnect(channel, websocket)
        except Exception:  # pragma: no cover - 防御性处理
            await broker.disconnect(channel, websocket)
            logger.exception("websocket connection aborted")

    @app.websocket("/ws/events/{channel}")
    async def generic_event_stream(channel: str, websocket: WebSocket) -> None:
        await broker.connect(channel, websocket)
        try:
            while True:
                await websocket.receive_text()
        except WebSocketDisconnect:
            await broker.disconnect(channel, websocket)
        except Exception:  # pragma: no cover
            await broker.disconnect(channel, websocket)
            logger.exception("websocket %s aborted", channel)

    return app


app = create_app()
