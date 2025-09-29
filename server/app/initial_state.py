from __future__ import annotations

from datetime import UTC, datetime
from typing import List

from .world_state import (
    AuctionHouse,
    AuctionLot,
    InventoryEntry,
    MapNode,
    MapNodeStyle,
    MapState,
    PlayerState,
    Shop,
    ShopItem,
    WorldState,
)
from .schemas import (
    AscensionChallenge,
    AscensionProgress,
    ChronicleLog,
    CommandResult,
    Companion,
    PillRecipe,
    PillRecipeMaterial,
    PlayerProfile,
    SecretRealm,
    Technique,
)


def build_fallback_world_state() -> WorldState:
    now = datetime.now(UTC)

    player_profile = PlayerProfile(
        id="player-0001",
        name="沈衡",
        realm="凡人三品",
        guild="青林民兵",
        faction_reputation={"青林村": 35, "岐楼坊市": 5, "暮山书院": 2},
        attributes={"体魄": 62, "身法": 54, "心性": 48},
        techniques=[
            Technique(
                id="tech-basic-sword",
                name="青叶剑式",
                type="combat",
                mastery=42,
                synergies=["草叶掠风步"],
            ),
        ],
        achievements=["守护青林村免遭山匪侵袭"],
        ascension_progress=AscensionProgress(
            stage="凡人三品",
            score=12,
            next_milestone="积攒资源以求拜入岐楼修馆",
        ),
    )

    companions: List[Companion] = [
        Companion(
            id="companion-lin-qiu",
            name="林秋",
            role="scout",
            personality="沉稳忠厚",
            bond_level=55,
            skills=["山林侦察", "陷阱布设"],
            mood="警惕",
            fatigue=18,
            traits=["熟悉岐楼附近地形", "有书院求学的梦想"],
        )
    ]

    secret_realms = [
        SecretRealm(
            id="realm-cloud-fissure",
            name="云岫断隙",
            tier=1,
            schedule="每逢初五对凡人开放两个时辰",
            environment={"灵气浓度": 1.2, "雾气浓度": 0.8},
            recommended_power=15,
            dynamic_events=[
                "雾壁收缩需迅速寻路",
                "偶有灵蛇巡查通道",
            ],
        )
    ]

    ascension_challenges = [
        AscensionChallenge(
            id="challenge-first-step",
            title="觅途问心",
            difficulty="凡人关",
            requirements=[
                "在不伤及无辜的前提下击退山匪小队",
                "收集足够的灵材准备拜师礼",
            ],
            rewards=[
                "岐楼修馆观礼资格",
                "灵材：银泉草",
            ],
        )
    ]

    pill_recipes = [
        PillRecipe(
            id="pill-temper-bones",
            name="淬骨散",
            grade="凡阶上品",
            base_effects=["强化筋骨韧性", "缓慢提升体魄"],
            materials=[
                PillRecipeMaterial(name="雾灵花", quantity=2, origin="云岫断隙"),
                PillRecipeMaterial(name="山泉砂", quantity=3, origin="岐楼坊市石料铺"),
            ],
            difficulty=22,
        )
    ]

    chronicle_logs: List[ChronicleLog] = []

    command_history: List[CommandResult] = []

    map_nodes = [
        MapNode(
            id="qinglin-village",
            name="青林村",
            category="village",
            description="沈衡出生的山间村落，民风淳朴但近年受山匪骚扰。",
            coords={"x": 0.48, "y": 0.72},
            connections=["qilou-market", "moss-trail"],
            discovered=True,
            style=MapNodeStyle(fill_color="#26A69A", border_color="#E0E5FF", icon="village"),
        ),
        MapNode(
            id="qilou-market",
            name="岐楼坊市",
            category="market",
            description="山脚下热闹的集市，是凡人与修士交易之地。",
            coords={"x": 0.62, "y": 0.58},
            connections=["qinglin-village", "cloud-pass", "river-dock"],
            discovered=True,
            style=MapNodeStyle(fill_color="#4C51BF", border_color="#E0E5FF", icon="market"),
        ),
        MapNode(
            id="cloud-pass",
            name="云岫断隙入口",
            category="secret_realm",
            description="据说每月雾海退潮时，凡人亦可短暂进入收集灵材。",
            coords={"x": 0.7, "y": 0.42},
            connections=["qilou-market"],
            discovered=False,
            style=MapNodeStyle(fill_color="#0EA5E9", border_color="#E0E5FF", icon="realm"),
        ),
        MapNode(
            id="moss-trail",
            name="苔径",
            category="trail",
            description="通往暮山书院的林间小径，尚未踏足。",
            coords={"x": 0.36, "y": 0.58},
            connections=["qinglin-village", "mushan-academy"],
            discovered=False,
            style=MapNodeStyle(fill_color="#15803D", border_color="#E0E5FF", icon="path"),
        ),
        MapNode(
            id="mushan-academy",
            name="暮山书院",
            category="academy",
            description="传闻书院中藏有炼气仙法，但无引荐者难以踏入。",
            coords={"x": 0.2, "y": 0.4},
            connections=["moss-trail"],
            discovered=False,
            style=MapNodeStyle(fill_color="#F97316", border_color="#E0E5FF", icon="academy"),
        ),
    ]

    map_state = MapState(nodes=map_nodes)

    shops = {
        "qilou-market-bazaar": Shop(
            id="qilou-market-bazaar",
            location_id="qilou-market",
            name="岐楼坊市药材铺",
            description="售卖凡人可用的草药与符箓，偶尔也收购猎人带回的材料。",
            inventory=[
                ShopItem(
                    id="herb-mist-leaf",
                    name="雾岫叶",
                    category="灵材",
                    rarity="凡阶",
                    price=8,
                    stock=12,
                    description="可入淬骨散，有助于稳固筋骨。",
                ),
                ShopItem(
                    id="talisman-ward",
                    name="镇魇符",
                    category="符箓",
                    rarity="凡阶",
                    price=15,
                    stock=6,
                    description="短时间内抵御魇术侵扰，效果约一炷香。",
                ),
                ShopItem(
                    id="tea-gourd",
                    name="青山葫芦",
                    category="法器",
                    rarity="凡阶上品",
                    price=120,
                    stock=1,
                    description="炼制精良的木葫芦，可储存三次灵水。",
                ),
            ],
        )
    }

    auctions = {
        "qilou-auction": AuctionHouse(
            id="qilou-auction",
            location_id="qilou-market",
            name="岐楼流拍阁",
            description="坊市定期举行的流拍集市，偶尔能见到修士遗留的物件。",
            listings=[
                AuctionLot(
                    id="lot-ironwood",
                    lot_name="黑铁木长弓",
                    category="武器",
                    current_bid=240,
                    buyout_price=420,
                    time_remaining_minutes=180,
                    seller="雾岭猎团",
                    description="由黑铁木打造的长弓，适合凡人猎手使用。",
                ),
                AuctionLot(
                    id="lot-cicada",
                    lot_name="灵蜕残片",
                    category="材料",
                    current_bid=320,
                    buyout_price=None,
                    time_remaining_minutes=95,
                    seller="暮山书院托卖",
                    description="蠹蛹蜕下的灵蜕，传闻可炼制定神丹。",
                ),
            ],
        )
    }

    player_state = PlayerState(
        profile=player_profile,
        current_location="qinglin-village",
        spirit_stones=68,
        inventory=[
            InventoryEntry(
                id="tool-hunting-knife",
                name="猎户短刀",
                category="武器",
                quantity=1,
                description="沈衡常用的随身短刀，锋利但无法御敌法器。",
            ),
            InventoryEntry(
                id="provision-dried-meat",
                name="风干肉",
                category="补给",
                quantity=3,
                description="在野外行走三日所需的粮食。",
            ),
        ],
    )

    return WorldState(
        player=player_state,
        companions=companions,
        secret_realms=secret_realms,
        ascension_challenges=ascension_challenges,
        pill_recipes=pill_recipes,
        chronicle_logs=chronicle_logs,
        command_history=command_history,
        map_state=map_state,
        shops=shops,
        auctions=auctions,
    )
