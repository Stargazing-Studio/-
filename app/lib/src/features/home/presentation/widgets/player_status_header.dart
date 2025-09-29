import 'package:flutter/material.dart';

import 'package:ling_yan_tian_ji/src/features/common/models/game_entities.dart';

class PlayerStatusHeader extends StatelessWidget {
  const PlayerStatusHeader({required this.profile, super.key});

  final PlayerProfile profile;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(
                  radius: 28,
                  backgroundColor: Color(0xFF26A69A),
                  child: Icon(
                    Icons.auto_awesome,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        profile.name,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text('境界：${profile.realm} · 所属：${profile.guild}'),
                      const SizedBox(height: 4),
                      Text(
                        '飞升进度：${profile.ascensionProgress.stage} (${profile.ascensionProgress.score} 积分)',
                      ),
                      Text('下一目标：${profile.ascensionProgress.nextMilestone}'),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _AttributeGrid(attributes: profile.attributes)),
                const SizedBox(width: 12),
                Expanded(
                  child: _ReputationList(reputation: profile.factionReputation),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AttributeGrid extends StatelessWidget {
  const _AttributeGrid({required this.attributes});

  final Map<String, num> attributes;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('核心属性', style: TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Wrap(
          runSpacing: 8,
          spacing: 12,
          children: attributes.entries
              .map(
                (entry) => Container(
                  width: 110,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0x3326A69A)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.key,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      Text(entry.value.toString()),
                    ],
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}

class _ReputationList extends StatelessWidget {
  const _ReputationList({required this.reputation});

  final Map<String, int> reputation;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('势力声望', style: TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Column(
          children: reputation.entries
              .map(
                (entry) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  title: Text(entry.key),
                  trailing: Text(entry.value.toString()),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}
