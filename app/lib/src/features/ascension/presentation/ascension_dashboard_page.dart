import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ling_yan_tian_ji/src/features/common/data/mock_data.dart';
import 'package:ling_yan_tian_ji/src/features/common/models/game_entities.dart';
import 'package:ling_yan_tian_ji/src/shared/widgets/navigation_scaffold.dart';
import 'package:ling_yan_tian_ji/src/core/network/api_client.dart';

class AscensionDashboardPage extends ConsumerWidget {
  const AscensionDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileState = ref.watch(playerProfileProvider);
    final challengesState = ref.watch(ascensionChallengesProvider);
    final eligibility = ref.watch(_ascensionEligibilityProvider);
    return NavigationScaffold(
      appBar: AppBar(title: const Text('飞升试炼面板')),
      body: profileState.when(
        data: (profile) => challengesState.when(
          data: (challenges) => eligibility.when(
            data: (info) => info.eligible
                ? _AscensionView(profile: profile, challenges: challenges)
                : _AscensionGate(requiredRealm: info.requiredRealm, onRefresh: () async {
                    ref.invalidate(_ascensionEligibilityProvider);
                    await ref.read(_ascensionEligibilityProvider.future);
                    ref.invalidate(playerProfileProvider);
                    await ref.read(playerProfileProvider.future);
                  }),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('资质校验失败：$e')),
          ),
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (error, _) => _ErrorPlaceholder(
            message: '无法加载试炼列表：$error',
            onRetry: () async {
              ref.invalidate(ascensionChallengesProvider);
              await ref.read(ascensionChallengesProvider.future);
            },
          ),
        ),
        loading: () => const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: CircularProgressIndicator(),
          ),
        ),
        error: (error, _) => _ErrorPlaceholder(
          message: '无法加载修士档案：$error',
          onRetry: () async {
            ref.invalidate(playerProfileProvider);
            await ref.read(playerProfileProvider.future);
          },
        ),
      ),
    );
  }
}

final _ascensionEligibilityProvider = FutureProvider<AscensionEligibility>((ref) async {
  final api = ref.watch(apiClientProvider);
  return api.fetchAscensionEligibility();
});

class _AscensionGate extends StatelessWidget {
  const _AscensionGate({required this.requiredRealm, required this.onRefresh});
  final String requiredRealm;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lock_outline, size: 40, color: Colors.orange),
            const SizedBox(height: 12),
            Text('尚未达到开启条件（需要：$requiredRealm）'),
            const SizedBox(height: 8),
            const Text('请先提升境界或完成必要前置。'),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRefresh,
              icon: const Icon(Icons.refresh),
              label: const Text('刷新检测'),
            )
          ],
        ),
      ),
    );
  }
}

class _AscensionView extends StatelessWidget {
  const _AscensionView({required this.profile, required this.challenges});

  final PlayerProfile profile;
  final List<AscensionChallenge> challenges;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '当前阶段：${profile.ascensionProgress.stage}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: (profile.ascensionProgress.score % 3000) / 3000,
                  ),
                  const SizedBox(height: 12),
                  Text('下一目标：${profile.ascensionProgress.nextMilestone}'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          ...challenges.map(
            (challenge) => _AscensionCard(challenge: challenge),
          ),
        ],
      ),
    );
  }
}

class _AscensionCard extends StatelessWidget {
  const _AscensionCard({required this.challenge});

  final AscensionChallenge challenge;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.auto_awesome,
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          challenge.title,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 4),
                        Text('难度：${challenge.difficulty}'),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text('试炼要求', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              ...challenge.requirements.map(
                (req) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      const Icon(Icons.task_alt, size: 18),
                      const SizedBox(width: 8),
                      Expanded(child: Text(req)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Text('潜在奖励', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Wrap(
                spacing: 8,
                children: challenge.rewards
                    .map(
                      (reward) => Chip(
                        avatar: const Icon(Icons.stars, size: 16),
                        label: Text(reward),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.login),
                  label: const Text('加入试炼队列'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorPlaceholder extends StatelessWidget {
  const _ErrorPlaceholder({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

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
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('重试'),
            ),
          ],
        ),
      ),
    );
  }
}
