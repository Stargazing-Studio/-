import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ling_yan_tian_ji/src/features/common/data/mock_data.dart';

class EventTicker extends ConsumerWidget {
  const EventTicker({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final realmsState = ref.watch(secretRealmsProvider);
    final challengesState = ref.watch(ascensionChallengesProvider);

    final highlights = <String>[];
    realmsState.whenData((realms) {
      highlights.addAll(
        realms.map(
          (realm) => '秘境：${realm.name} · 推荐战力 ${realm.recommendedPower}',
        ),
      );
    });
    challengesState.whenData((challenges) {
      highlights.addAll(
        challenges.map(
          (challenge) => '飞升：${challenge.title} · 难度：${challenge.difficulty}',
        ),
      );
    });

    final isLoading = realmsState.isLoading || challengesState.isLoading;
    final hasError = realmsState.hasError || challengesState.hasError;

    if (highlights.isEmpty) {
      if (isLoading) {
        return const _TickerPlaceholder(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 8),
              Text('世界动态加载中…'),
            ],
          ),
        );
      }
      if (hasError) {
        return const _TickerPlaceholder(
          child: Text('无法获取最新世界动态'),
        );
      }
      return const SizedBox(height: 38);
    }

    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: highlights.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final text = highlights[index];
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0x4426A69A), Color(0x220F4C75)],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0x3326A69A)),
            ),
            child: Center(
              child: Text(
                text,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _TickerPlaceholder extends StatelessWidget {
  const _TickerPlaceholder({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 38,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x3326A69A)),
        color: const Color(0x1126A69A),
      ),
      child: child,
    );
  }
}
