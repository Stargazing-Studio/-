时间戳：2025-09-28
变更：
- 后端：新增 GET /wallet，返回 {spirit_stones}（schemas.WalletResponse, main.py 路由）。
- 前端：
  1) 新增 WalletData + fetchWallet()，Provider walletProvider（features/common/data/wallet_provider.dart）。
  2) 坊市/拍卖页底部展示当前灵石，并提供“背包 查看”快捷入口；购买/买断后刷新钱包/档案/商铺或拍卖与编年史。
  3) 导航栏接入飞升资格 gating：MainNavigationBar 改为 ConsumerWidget，拦截未达条件的“飞升”点击并灰显图标（ascensionEligibilityProvider）。
验证：
- GET /wallet 返回数值。
- 前端底部显示“灵石：X”，购买/买断成功后数值变化并有事件写入。
- “飞升”入口在未达条件时点击提示并不跳转，达标后可进入。
回滚：删除 /wallet 与相关前端 Provider/调用，并将 MainNavigationBar 还原为 StatelessWidget。