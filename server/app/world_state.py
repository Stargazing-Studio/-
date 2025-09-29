from __future__ import annotations

import json
from datetime import UTC, datetime
from pathlib import Path
from threading import Lock
from typing import Dict, List, Any

from pydantic import BaseModel, Field

from .schemas import (
    AscensionChallenge,
    ChronicleLog,
    CommandResult,
    Companion,
    PillRecipe,
    PlayerProfile,
    SecretRealm,
)


class Coordinates(BaseModel):
    x: float = Field(ge=0.0, le=1.0)
    y: float = Field(ge=0.0, le=1.0)


class MapNodeStyle(BaseModel):
    fill_color: str = "#26A69A"
    border_color: str = "#E0E5FF"
    icon: str | None = None


class MapNode(BaseModel):
    id: str
    name: str
    category: str
    description: str
    coords: Coordinates
    connections: List[str]
    discovered: bool = False
    style: MapNodeStyle = Field(default_factory=MapNodeStyle)


class MapStyle(BaseModel):
    background_color: str = "#0F172A"
    edge_color: str = "#334155"
    grid_color: str | None = "#1F2937"
    node_label_color: str = "#E0E5FF"
    extras: Dict[str, Any] = Field(default_factory=dict)


class MapState(BaseModel):
    nodes: List[MapNode]
    style: MapStyle = Field(default_factory=MapStyle)


class ShopItem(BaseModel):
    id: str
    name: str
    category: str
    rarity: str
    price: int
    stock: int
    description: str


class Shop(BaseModel):
    id: str
    location_id: str
    name: str
    description: str
    inventory: List[ShopItem]


class AuctionLot(BaseModel):
    id: str
    lot_name: str
    category: str
    current_bid: int
    buyout_price: int | None = None
    time_remaining_minutes: int
    seller: str
    description: str


class AuctionHouse(BaseModel):
    id: str
    location_id: str
    name: str
    description: str
    listings: List[AuctionLot]


class InventoryEntry(BaseModel):
    id: str
    name: str
    category: str
    quantity: int
    description: str


class PlayerState(BaseModel):
    profile: PlayerProfile
    current_location: str
    spirit_stones: int
    inventory: List[InventoryEntry]
    blood_percent: int = 100


class WorldState(BaseModel):
    player: PlayerState
    companions: List[Companion]
    secret_realms: List[SecretRealm]
    ascension_challenges: List[AscensionChallenge]
    pill_recipes: List[PillRecipe]
    chronicle_logs: List[ChronicleLog]
    command_history: List[CommandResult]
    map_state: MapState
    shops: Dict[str, Shop]
    auctions: Dict[str, AuctionHouse]
    last_updated: datetime = Field(default_factory=lambda: datetime.now(UTC))


class WorldStateStore:
    def __init__(self, storage_path: Path | None = None) -> None:
        default_path = Path(__file__).resolve().parent.parent / "world_state.json"
        self._path = storage_path or default_path
        self._lock = Lock()
        self._state: WorldState | None = None

        if self._path.exists():
            self._state = WorldState.model_validate_json(
                self._path.read_text(encoding="utf-8")
            )

    @property
    def path(self) -> Path:
        return self._path

    def has_state(self) -> bool:
        return self._state is not None

    @property
    def state(self) -> WorldState:
        if not self._state:
            raise RuntimeError("World state not initialised")
        return self._state

    def set_state(self, state: WorldState) -> None:
        with self._lock:
            self._state = state
            serialized = json.dumps(
                state.model_dump(mode="json"),
                ensure_ascii=False,
                indent=2,
            )
            self._path.write_text(serialized, encoding="utf-8")

    def update_state(self, state: WorldState) -> None:
        state.last_updated = datetime.now(UTC)
        self.set_state(state)

    def save(self) -> None:
        if not self._state:
            return
        with self._lock:
            serialized = json.dumps(
                self._state.model_dump(mode="json"),
                ensure_ascii=False,
                indent=2,
            )
            self._path.write_text(serialized, encoding="utf-8")
