from __future__ import annotations

from contextlib import asynccontextmanager
import logging
from typing import List

from fastapi import FastAPI, HTTPException, Query, WebSocket, WebSocketDisconnect
from fastapi.encoders import jsonable_encoder
from fastapi.middleware.cors import CORSMiddleware

from .ai import GeminiClient
from .data import GameRepository, MemoryRepository
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
from .world_state import WorldStateStore

logger = logging.getLogger("lingyan.server")


def create_app() -> FastAPI:
    store = WorldStateStore()
    gemini = GeminiClient.from_environment()
    initializer = WorldInitializer(store, gemini)
    repository = GameRepository(store)
    memory_repository = MemoryRepository()
    broker = MultiChannelEventBroker()

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

    app.add_middleware(
        CORSMiddleware,
        allow_origins=["*"],
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )

    @app.get("/health")
    async def health_check() -> dict[str, str]:
        return {"status": "ok", "message": "DaoCore 连接成功。"}

    @app.get("/profile", response_model=PlayerProfile)
    async def get_profile() -> PlayerProfile:
        return repository.get_profile()

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
    async def list_chronicles() -> List[ChronicleLog]:
        return repository.list_chronicles()

    @app.get("/commands/history", response_model=List[CommandResult])
    async def list_command_history() -> List[CommandResult]:
        return repository.list_command_history()

    @app.get("/location/current", response_model=MapNodeView)
    async def current_location() -> MapNodeView:
        node = repository.get_current_location_node()
        if not node:
            raise HTTPException(status_code=404, detail="未知地点")
        return MapNodeView(**node.model_dump())

    @app.get("/map", response_model=MapViewResponse)

    async def fetch_map() -> MapViewResponse:
        return MapViewResponse(**repository.get_map_view())

    @app.post("/travel", response_model=TravelResponse)
    async def travel(request: TravelRequest) -> TravelResponse:
        profile = repository.travel_to(request.location_id)
        current = repository.get_state().player.current_location
        return TravelResponse(profile=profile, current_location=current)

    @app.get("/shops/current", response_model=List[ShopResponse])
    async def shops_at_location() -> List[ShopResponse]:
        shops = repository.list_shops_for_current_location()
        return [ShopResponse(**shop.model_dump()) for shop in shops]

    @app.get("/shops/{shop_id}", response_model=ShopResponse)
    async def shop_detail(shop_id: str) -> ShopResponse:
        shop = repository.get_shop(shop_id)
        return ShopResponse(**shop.model_dump())

    @app.post("/shops/{shop_id}/purchase", response_model=ShopPurchaseResponse, status_code=201)
    async def shop_purchase(shop_id: str, payload: ShopPurchaseRequest) -> ShopPurchaseResponse:
        spent = repository.purchase_from_shop(shop_id, payload.item_id, payload.quantity)
        inv = [InventoryEntryResponse(**i.model_dump()) for i in repository.get_inventory()]
        return ShopPurchaseResponse(
            spent=spent,
            profile=repository.get_profile(),
            inventory=inv,
        )

    @app.get("/auctions/current", response_model=AuctionHouseResponse | None)
    async def auction_at_location() -> AuctionHouseResponse | None:
        auction = repository.list_auctions_for_current_location()
        if auction is None:
            return None
        return AuctionHouseResponse(**auction.model_dump())

    @app.post("/auctions/{auction_id}/buy", response_model=AuctionBuyResponse, status_code=201)
    async def auction_buy(auction_id: str, payload: AuctionBuyRequest) -> AuctionBuyResponse:
        spent = repository.buyout_auction_lot(auction_id, payload.lot_id)
        inv = [InventoryEntryResponse(**i.model_dump()) for i in repository.get_inventory()]
        return AuctionBuyResponse(
            spent=spent,
            profile=repository.get_profile(),
            inventory=inv,
        )

    @app.post("/commands", response_model=CommandResponse)
    async def submit_command(payload: CommandRequest) -> CommandResponse:
        gemini_client: GeminiClient = app.state.gemini_client
        if not gemini_client.available:
            raise HTTPException(
                status_code=503,
                detail="天机灵枢暂未接通，请稍后再试",
            )

        try:
            # 构造对话上下文（最近3轮 + 旧历史压缩）
            history = repository.list_command_history()
            recent = history[:3]
            older = history[3:]
            transcript_recent = "\n".join(
                [
                    f"玩家：{c.content}\n天机：{c.feedback}" for c in reversed(recent)
                ]
            )
            summary_block = None
            if older:
                # 使用 AI 压缩旧历史（不展示给玩家）
                transcript_older = "\n".join(
                    [f"玩家：{c.content}\n天机：{c.feedback}" for c in reversed(older)]
                )
                summary_block = await gemini_client.summarize_dialogue(transcript_older)
                # 记录到内存记忆库，便于检索（不返还给前端）
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
            context_text = (f"【旧历史压缩】{summary_block}\n\n" if summary_block else "") + \
                           (f"【最近三轮】\n{transcript_recent}" if transcript_recent else "")

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

        command, chronicle = repository.record_command(
            payload, feedback_override=feedback
        )
        await broker.broadcast(
            "chronicles",
            jsonable_encoder(ChronicleStreamUpdate(log=chronicle)),
        )
        logger.info("command %s handled", command.id)
        return CommandResponse(result=command, emitted_log=chronicle)

    @app.post("/memories", response_model=MemoryRecord, status_code=201)
    async def append_memory(payload: MemoryAppendRequest) -> MemoryRecord:
        record = memory_repository.append(payload)
        return record

    @app.get("/inventory", response_model=list[InventoryEntryResponse])
    async def get_inventory() -> list[InventoryEntryResponse]:
        inv = [InventoryEntryResponse(**i.model_dump()) for i in repository.get_inventory()]
        return inv

    @app.get("/ascension/eligibility", response_model=AscensionEligibilityResponse)
    async def ascension_eligibility() -> AscensionEligibilityResponse:
        return AscensionEligibilityResponse(
            eligible=repository.ascension_eligible(),
            required_realm="炼气一阶",
        )

    @app.get("/wallet", response_model=WalletResponse)
    async def get_wallet() -> WalletResponse:
        state = repository.get_state()
        return WalletResponse(spirit_stones=state.player.spirit_stones)

    @app.get("/memories/search", response_model=MemorySearchResponse)
    async def search_memories(
        query: str = Query("", max_length=120, description="模糊匹配的关键词"),
        limit: int = Query(10, ge=1, le=50, description="返回条数上限"),
    ) -> MemorySearchResponse:
        results = memory_repository.search(query, limit)
        return MemorySearchResponse(query=query, results=results)

    @app.post("/events/emit", status_code=202)
    async def emit_event(payload: EventBroadcastRequest) -> dict[str, str]:
        await broker.broadcast(payload.channel, payload.payload)
        return {"status": "ok"}

    # 管理接口：重置世界状态与游玩数据（开发/调试用途）
    @app.post("/admin/reset", status_code=202)
    async def admin_reset_world() -> dict[str, str]:
        """清空游玩数据，并强制通过 AI 重建（不使用内置内容）。

        失败时返回 503，不落回任何内置模板。
        """
        try:
            ok = await initializer.regenerate_world_via_ai()
        except Exception as e:
            raise HTTPException(status_code=503, detail=f"世界重建失败：{e}")
        if not ok:
            raise HTTPException(
                status_code=503,
                detail="无法通过 Gemini 重建世界，请检查 API Key/地区支持/模型配置。",
            )
        memory_repository.clear()
        # 广播空事件快照以刷新前端
        snapshot_message = jsonable_encoder(
            ChronicleStreamSnapshot(logs=repository.list_chronicles())
        )
        await broker.broadcast("chronicles", snapshot_message)
        return {"status": "ok", "message": "world reset"}

    # 便于浏览器直接触发（GET），功能等同于 POST /admin/reset
    @app.get("/admin/reset")
    async def admin_reset_world_get() -> dict[str, str]:
        try:
            return await admin_reset_world()
        except HTTPException:
            raise
        except Exception as e:
            raise HTTPException(status_code=503, detail=f"世界重建失败：{e}")

    @app.websocket("/ws/chronicles")
    async def chronicle_stream(websocket: WebSocket) -> None:
        snapshot_message = jsonable_encoder(
            ChronicleStreamSnapshot(logs=repository.list_chronicles())
        )
        await broker.connect("chronicles", websocket, [snapshot_message])
        try:
            while True:
                await websocket.receive_text()
        except WebSocketDisconnect:
            await broker.disconnect("chronicles", websocket)
        except Exception:  # pragma: no cover - 防御性处理
            await broker.disconnect("chronicles", websocket)
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
