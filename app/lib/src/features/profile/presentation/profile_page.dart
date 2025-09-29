import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ling_yan_tian_ji/src/features/common/data/mock_data.dart';
import 'package:ling_yan_tian_ji/src/features/common/models/game_entities.dart';
import 'package:ling_yan_tian_ji/src/features/profile/application/inventory_providers.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileState = ref.watch(playerProfileProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('个人信息')),
      body: profileState.when(
        data: (profile) => _ProfileView(profile: profile),
        loading: () => const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: CircularProgressIndicator(),
          ),
        ),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, color: Colors.redAccent),
                const SizedBox(height: 12),
                Text('无法加载修士档案：$error'),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () async {
                    ref.invalidate(playerProfileProvider);
                    await ref.read(playerProfileProvider.future);
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('重试'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileView extends StatelessWidget {
  const _ProfileView({required this.profile});

  final PlayerProfile profile;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 36,
                backgroundColor: Color(0xFF5C6BC0),
                child: Icon(
                  Icons.auto_fix_high,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              const SizedBox(width: 18),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    profile.name,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 6),
                  Text('境界：${profile.realm}'),
                  Text('所属势力：${profile.guild}'),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          _SectionCard(
            title: '功法修炼',
            child: Column(
              children: profile.techniques
                  .map(
                    (technique) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(_iconForTechnique(technique.type)),
                      title: Text(technique.name),
                      subtitle: Text(
                        '类型：${_labelForTechnique(technique.type)} · 精通：${technique.mastery}%',
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: technique.synergies
                            .map(
                              (synergy) => Text(
                                synergy,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          const SizedBox(height: 16),
          // 背包（从后端实时获取）
          Consumer(builder: (context, ref, _) {
            final inv = ref.watch(inventoryProvider);
            return _SectionCard(
              title: '背包',
              child: inv.when(
                data: (items) {
                  if (items.isEmpty) {
                    return const Text('背包空空如也。');
                  }
                  return Column(
                    children: items
                        .map(
                          (e) => ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text('${e.name} × ${e.quantity}'),
                            subtitle: Text('${e.category} · ${e.description}'),
                          ),
                        )
                        .toList(),
                  );
                },
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: LinearProgressIndicator(),
                ),
                error: (err, _) => Text('背包加载失败：$err'),
              ),
            );
          }),
          const SizedBox(height: 16),
          _SectionCard(
            title: '成就轨迹',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: profile.achievements
                  .map(
                    (achievement) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle_outline),
                          const SizedBox(width: 12),
                          Expanded(child: Text(achievement)),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          const SizedBox(height: 16),
          _SectionCard(
            title: '飞升进度',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('当前阶段：${profile.ascensionProgress.stage}'),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: (profile.ascensionProgress.score % 3000) / 3000,
                ),
                const SizedBox(height: 12),
                Text('下一步：${profile.ascensionProgress.nextMilestone}'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

IconData _iconForTechnique(TechniqueType type) {
  switch (type) {
    case TechniqueType.core:
      return Icons.star_rate_rounded;
    case TechniqueType.combat:
      return Icons.flash_on_outlined;
    case TechniqueType.support:
      return Icons.shield_moon_outlined;
    case TechniqueType.movement:
      return Icons.air_rounded;
  }
}

String _labelForTechnique(TechniqueType type) {
  switch (type) {
    case TechniqueType.core:
      return '核心心法';
    case TechniqueType.combat:
      return '战斗绝学';
    case TechniqueType.support:
      return '辅助奇术';
    case TechniqueType.movement:
      return '身法遁术';
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}
