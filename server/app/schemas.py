from __future__ import annotations

from datetime import datetime
from typing import Any, Dict, List, Literal

from pydantic import BaseModel, Field


class Technique(BaseModel):
    id: str
    name: str
    type: str
    mastery: int = Field(ge=0, le=100)
    synergies: List[str] = []


class AscensionProgress(BaseModel):
    stage: str
    score: int
    next_milestone: str


class PlayerProfile(BaseModel):
    id: str
    name: str
    realm: str
    guild: str
    faction_reputation: Dict[str, int]
    attributes: Dict[str, int]
    techniques: List[Technique]
    achievements: List[str]
    ascension_progress: AscensionProgress


class Companion(BaseModel):
    id: str
    name: str
    role: str
    personality: str
    bond_level: int = Field(ge=0, le=100)
    skills: List[str]
    mood: str
    fatigue: int = Field(ge=0, le=100)
    traits: List[str]


class SecretRealm(BaseModel):
    id: str
    name: str
    tier: int
    schedule: str
    environment: Dict[str, float]
    recommended_power: int
    dynamic_events: List[str]


class AscensionChallenge(BaseModel):
    id: str
    title: str
    difficulty: str
    requirements: List[str]
    rewards: List[str]


class PillRecipeMaterial(BaseModel):
    name: str
    quantity: int
    origin: str


class PillRecipe(BaseModel):
    id: str
    name: str
    grade: str
    base_effects: List[str]
    materials: List[PillRecipeMaterial]
    difficulty: int


class ChronicleLog(BaseModel):
    id: str
    title: str
    timestamp: datetime
    summary: str
    tags: List[str]


class CommandRequest(BaseModel):
    content: str = Field(..., min_length=1, max_length=280)


class CommandResult(BaseModel):
    id: str
    content: str
    feedback: str
    created_at: datetime


class CommandResponse(BaseModel):
    result: CommandResult
    emitted_log: ChronicleLog


class ChronicleStreamSnapshot(BaseModel):
    type: Literal["snapshot"] = "snapshot"
    logs: List[ChronicleLog]


class ChronicleStreamUpdate(BaseModel):
    type: Literal["chronicle_update"] = "chronicle_update"
    log: ChronicleLog


class MemoryAppendRequest(BaseModel):
    subject: str = Field(..., min_length=1, max_length=120)
    content: str = Field(..., min_length=1)
    category: str = Field(default="general", max_length=40)
    tags: List[str] = []
    importance: int = Field(default=50, ge=0, le=100)


class MemoryRecord(MemoryAppendRequest):
    id: str
    created_at: datetime


class MemorySearchResponse(BaseModel):
    query: str
    results: List[MemoryRecord]


class EventBroadcastRequest(BaseModel):
    channel: str = Field(..., min_length=1, max_length=64)
    payload: Dict[str, Any]


class MapNodeView(BaseModel):
    id: str
    name: str
    category: str
    description: str
    coords: Dict[str, float]
    connections: List[str]
    style: Dict[str, Any]


class MapViewResponse(BaseModel):
    style: Dict[str, Any]
    nodes: List[MapNodeView]
    edges: List[Dict[str, str]]


class TravelRequest(BaseModel):
    location_id: str = Field(..., min_length=1)


class TravelResponse(BaseModel):
    profile: PlayerProfile
    current_location: str


class ShopItemResponse(BaseModel):
    id: str
    name: str
    category: str
    rarity: str
    price: int
    stock: int
    description: str


class ShopResponse(BaseModel):
    id: str
    location_id: str
    name: str
    description: str
    inventory: List[ShopItemResponse]

class InventoryEntryResponse(BaseModel):
    id: str
    name: str
    category: str
    quantity: int
    description: str

class ShopPurchaseRequest(BaseModel):
    item_id: str = Field(..., min_length=1)
    quantity: int = Field(..., ge=1, le=99)

class ShopPurchaseResponse(BaseModel):
    spent: int
    profile: PlayerProfile
    inventory: List[InventoryEntryResponse]


class AuctionLotResponse(BaseModel):
    id: str
    lot_name: str
    category: str
    current_bid: int
    buyout_price: int | None = None
    time_remaining_minutes: int
    seller: str
    description: str


class AuctionHouseResponse(BaseModel):
    id: str
    location_id: str
    name: str
    description: str
    listings: List[AuctionLotResponse]

class AuctionBuyRequest(BaseModel):
    lot_id: str = Field(..., min_length=1)

class AuctionBuyResponse(BaseModel):
    spent: int
    profile: PlayerProfile
    inventory: List[InventoryEntryResponse]

class AscensionEligibilityResponse(BaseModel):
    eligible: bool
    required_realm: str = "炼气一阶"

class WalletResponse(BaseModel):
    spirit_stones: int
