时间戳：2025-09-28
前端对接（最小改动）：
- API：在 api_client.dart 新增 purchaseFromShop/buyoutAuction/fetchInventory/fetchAscensionEligibility 及类型。
- 坊市页：market_page.dart 将货品项替换为 _ShopItemTile，支持选择数量与点击购买；购买成功刷新商铺与编年史。
- 拍卖页：auction_house_page.dart 点击支持一口价买断，成功刷新拍卖行与编年史。
- 飞升页：ascension_dashboard_page.dart 新增 _ascensionEligibilityProvider 与 _AscensionGate 未达境界时展示锁定提示。
- 导航容器：navigation_scaffold.dart 支持在底部导航上方插入可选自定义 bottom（后续可用于背包快捷入口）。
验证：
- 运行前端后进入坊市/拍卖页面进行购买；余额不足/库存不足时 Toast 提示。
- 进入飞升页，未达“炼气一阶”时显示锁定提示，可点击刷新检测。
后续：
- 背包展示入口与页面尚未添加（API 已就绪：GET /inventory）。可在 MainNavigationBar 或 Profile 页面增加入口。