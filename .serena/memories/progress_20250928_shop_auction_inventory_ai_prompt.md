时间戳：2025-09-28
变更摘要：
- 新增购买与背包接口：
  - schemas：新增 InventoryEntryResponse、ShopPurchaseRequest/Response、AuctionBuyRequest/Response、AscensionEligibilityResponse。
  - data.GameRepository：新增 get_inventory/_add_inventory/purchase_from_shop/buyout_auction_lot/ascension_eligible。
  - main.py：新增路由 POST /shops/{shop_id}/purchase、POST /auctions/{auction_id}/buy、GET /inventory、GET /ascension/eligibility。
- AI 提示与输出：
  - prompts.py：强化世界种子要求，首条背景/事件描述需>=200字；明确时序与严格字段。
  - ai.py：修改 generate_command_feedback 提示，要求输出完整事件叙事并以问题收尾，引导下一步。
验证建议：
1) 商铺购买：
   - 前置到 N002（落日坊市）后，POST /shops/S_Market_01/purchase {item_id: "Item_004", quantity: 1}；应 201，并返回 spent、新余额（在 profile.spirit_stones 中）和 inventory 更新；/chronicles 新增“交易·商铺”。
   - 灵石不足或库存不足分别返回 403/400。
2) 拍卖买断：
   - POST /auctions/A_Market_01/buy {lot_id: "L001"}；成功 201，返回 spent 和 inventory；/chronicles 新增“交易·拍卖”。
3) 背包：GET /inventory 返回当前背包条目数组。
4) 升阶资格：GET /ascension/eligibility 返回 {eligible, required_realm: "炼气一阶"}；凡人阶段应为 false。
5) 指令反馈：POST /commands 后返回的 result.feedback 为完整事件叙述并以提问收尾。
回滚：
- 移除新增 schemas 与路由；还原 ai.py 与 prompts.py 之前的内容。
注意：
- 前端需调用新接口实现购买与背包展示；如需我改前端路由/页面，提供入口位置即可。