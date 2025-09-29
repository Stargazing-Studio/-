import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ling_yan_tian_ji/src/features/common/data/wallet_provider.dart';

import 'package:ling_yan_tian_ji/src/features/auction/application/auction_providers.dart';
import 'package:ling_yan_tian_ji/src/core/network/api_client.dart';
import 'package:ling_yan_tian_ji/src/features/common/data/mock_data.dart';
import 'package:ling_yan_tian_ji/src/shared/widgets/navigation_scaffold.dart';

class AuctionHousePage extends ConsumerWidget {
  const AuctionHousePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auctionAsync = ref.watch(auctionHouseProvider);
    return NavigationScaffold(
      appBar: AppBar(title: const Text('流拍阁 · 拍卖行')),
      body: auctionAsync.when(
        data: (house) {
          if (house == null) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text('此处未设拍卖行，请前往指定坊市。'),
              ),
            );
          }
          if (house.listings.isEmpty) {
            return const Center(child: Text('暂无拍卖品，稍后再来。'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: house.listings.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final lot = house.listings[index];
              return Card(
                child: ListTile(
                  title: Text('${lot.lotName} · ${lot.category}'),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(lot.description),
                        const SizedBox(height: 6),
                        Text('出品人：${lot.seller}')
                      ],
                    ),
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('当前价：${lot.currentBid} 灵石'),
                      if (lot.buyoutPrice != null)
                        Text('一口价：${lot.buyoutPrice} 灵石'),
                      Text('剩余时间：${lot.timeRemainingMinutes} 分钟'),
                    ],
                  ),
                  onTap: lot.buyoutPrice == null
                      ? null
                      : () async {
                          try {
                            final api = ref.read(apiClientProvider);
                            await api.buyoutAuction(
                              auctionId: house.id,
                              lotId: lot.id,
                            );
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('已买断：${lot.lotName}')),
                            );
                            ref.invalidate(auctionHouseProvider);
                            await ref.read(auctionHouseProvider.future);
                            ref.invalidate(playerProfileProvider);
                            await ref.read(playerProfileProvider.future);
                            ref.read(chronicleLogsProvider.notifier).refresh();
                          } on DioException catch (e) {
                            final msg = e.response?.data is Map && (e.response!.data['detail'] != null)
                                ? e.response!.data['detail'].toString()
                                : (e.message ?? '购买失败');
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(msg)),
                            );
                          } catch (e) {
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('购买失败：$e')),
                            );
                          }
                        },
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Padding(
          padding: const EdgeInsets.all(24),
          child: Text('拍卖行加载失败：$error\n$stack'),
        ),
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
