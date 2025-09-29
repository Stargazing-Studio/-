import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ling_yan_tian_ji/src/features/common/data/mock_data.dart';
import 'package:ling_yan_tian_ji/src/features/common/models/game_entities.dart';

class CompanionHubPage extends ConsumerWidget {
  const CompanionHubPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final companionsState = ref.watch(companionsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('灵仆灵宠一览')),
      body: companionsState.when(
        data: (companions) => ListView.separated(
          padding: const EdgeInsets.all(20),
          itemCount: companions.length,
          separatorBuilder: (_, __) => const SizedBox(height: 14),
          itemBuilder: (context, index) {
            final companion = companions[index];
            return _CompanionCard(companion: companion);
          },
        ),
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
                Text('无法加载灵仆灵宠：$error'),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () async {
                    ref.invalidate(companionsProvider);
                    await ref.read(companionsProvider.future);
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

class _CompanionCard extends StatelessWidget {
  const _CompanionCard({required this.companion});

  final Companion companion;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _CompanionAvatar(role: companion.role),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        companion.name,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '定位：${_roleLabel(companion.role)} · 个性：${companion.personality}',
                      ),
                      Text('心情：${companion.mood} · 疲劳：${companion.fatigue}%'),
                    ],
                  ),
                ),
                _BondIndicator(level: companion.bondLevel),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 6,
              children: companion.skills
                  .map(
                    (skill) => Chip(
                      avatar: const Icon(Icons.auto_awesome_outlined, size: 16),
                      label: Text(skill),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: companion.traits
                  .map(
                    (trait) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0x335C6BC0)),
                      ),
                      child: Text(trait),
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  String _roleLabel(CompanionRole role) {
    switch (role) {
      case CompanionRole.attendant:
        return '侍奉灵仆';
      case CompanionRole.guardian:
        return '护主灵宠';
      case CompanionRole.scout:
        return '探索先驱';
      case CompanionRole.alchemist:
        return '炼丹管家';
    }
  }
}

class _CompanionAvatar extends StatelessWidget {
  const _CompanionAvatar({required this.role});

  final CompanionRole role;

  @override
  Widget build(BuildContext context) {
    final icon = () {
      switch (role) {
        case CompanionRole.attendant:
          return Icons.escalator_warning_rounded;
        case CompanionRole.guardian:
          return Icons.shield_outlined;
        case CompanionRole.scout:
          return Icons.travel_explore_outlined;
        case CompanionRole.alchemist:
          return Icons.science_outlined;
      }
    }();
    return CircleAvatar(
      radius: 26,
      backgroundColor: const Color(0x445C6BC0),
      child: Icon(icon, color: Colors.white),
    );
  }
}

class _BondIndicator extends StatelessWidget {
  const _BondIndicator({required this.level});

  final int level;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text('羁绊'),
        const SizedBox(height: 6),
        SizedBox(width: 60, child: LinearProgressIndicator(value: level / 100)),
        const SizedBox(height: 4),
        Text('$level%'),
      ],
    );
  }
}
