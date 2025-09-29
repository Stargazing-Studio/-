import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ling_yan_tian_ji/src/features/market/application/market_providers.dart';
import 'package:ling_yan_tian_ji/src/features/common/data/mock_data.dart';
import 'package:ling_yan_tian_ji/src/core/network/api_client.dart';
import 'package:go_router/go_router.dart';
import 'package:ling_yan_tian_ji/src/features/common/data/wallet_provider.dart';
import 'package:ling_yan_tian_ji/src/shared/widgets/navigation_scaffold.dart';

class MarketPage extends ConsumerWidget {
  const MarketPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shopsAsync = ref.watch(marketShopsProvider);
    return NavigationScaffold(
      appBar: AppBar(title: const Text('坊市 · 可供交易的商铺')),
      body: shopsAsync.when(
        data: (shops) {
          if (shops.isEmpty) {
            return const _EmptyMarket();
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: shops.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final shop = shops[index];
              return Card(
                child: ExpansionTile(
                  title: Text(shop.name),
                  subtitle: Text(shop.description),
                  children: shop.inventory.isEmpty
                      ? [const Padding(
                          padding: EdgeInsets.all(12),
                          child: Text('暂无货品，稍后再来看看。'),
                        )]
                      : shop.inventory.map((item) {
                          return _ShopItemTile(shopId: shop.id, item: item);
                        }).toList(),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => _MarketError(error: error, stack: stack),
      ),
      bottom: Consumer(builder: (context, ref, _) {
        final wallet = ref.watch(walletProvider);
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(
            children: [
              const Icon(Icons.account_balance_wallet_outlined, size: 18),
              const SizedBox(width: 8),
              wallet.when(
                data: (w) => Text('灵石：${w.spiritStones}') ,
                loading: () => const Text('灵石：…'),
                error: (_, __) => const Text('灵石：--'),
              ),
              const Spacer(),
              const Icon(Icons.inventory_2_outlined, size: 18),
              const SizedBox(width: 8),
              TextButton.icon(
                onPressed: () => context.go('/profile'),
                icon: const Icon(Icons.arrow_forward, size: 16),
                label: const Text('背包'),
              )
            ],
          ),
        );
      }),
    );
  }
}

class _ShopItemTile extends ConsumerStatefulWidget {
  const _ShopItemTile({required this.shopId, required this.item});

  final String shopId;
  final ShopItemData item;

  @override
  ConsumerState<_ShopItemTile> createState() => _ShopItemTileState();
}

class _ShopItemTileState extends ConsumerState<_ShopItemTile> {
  bool _loading = false;
  int _qty = 1;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    return ListTile(
      title: Text('${item.name} · ${item.rarity}'),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(item.description),
          const SizedBox(height: 6),
          Row(
            children: [
              const Text('数量：'),
              SizedBox(
                width: 80,
                child: DropdownButton<int>(
                  value: _qty,
                  isExpanded: true,
                  items: List.generate(
                    (item.stock.clamp(1, 9)),
                    (i) => DropdownMenuItem(value: i + 1, child: Text('${i + 1}')),
                  ),
                  onChanged: _loading ? null : (v) => setState(() => _qty = v ?? 1),
                ),
              ),
            ],
          ),
        ],
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text('售价：${item.price} 灵石'),
          Text('库存：${item.stock}')
        ],
      ),
      onTap: _loading ? null : () async {
        if (item.stock <= 0) return;
        setState(() => _loading = true);
        try {
          final api = ref.read(apiClientProvider);
          await api.purchaseFromShop(
            shopId: widget.shopId,
            itemId: item.id,
            quantity: _qty,
          );
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('已购入 $_qty × ${item.name}')),
          );
          // 刷新商铺列表、人物信息与编年史
          ref.invalidate(marketShopsProvider);
          await ref.read(marketShopsProvider.future);
          ref.invalidate(playerProfileProvider);
          await ref.read(playerProfileProvider.future);
          ref.read(chronicleLogsProvider.notifier).refresh();
        } on DioException catch (e) {
          final msg = e.response?.data is Map && (e.response!.data['detail'] != null)
              ? e.response!.data['detail'].toString()
              : (e.message ?? '购买失败');
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
        } catch (e) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('购买失败：$e')));
        } finally {
          if (mounted) setState(() => _loading = false);
        }
      },
    );
  }
}

class _EmptyMarket extends StatelessWidget {
  const _EmptyMarket();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text('当前地点没有开放的商铺，请前往坊市或其他城镇。'),
      ),
    );
  }
}

class _MarketError extends StatelessWidget {
  const _MarketError({required this.error, required this.stack});

  final Object error;
  final StackTrace? stack;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.redAccent),
            const SizedBox(height: 12),
            Text('坊市数据加载失败：$error'),
            if (stack != null)
              Text(
                stack.toString(),
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: Colors.white38),
              ),
          ],
        ),
      ),
    );
  }
}
