import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ling_yan_tian_ji/src/features/common/data/mock_data.dart';
import 'package:ling_yan_tian_ji/src/features/common/models/game_entities.dart';

class TechniqueLibraryPage extends ConsumerWidget {
  const TechniqueLibraryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileState = ref.watch(playerProfileProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('功法图鉴')),
      body: profileState.when(
        data: (profile) => ListView(
          padding: const EdgeInsets.all(20),
          children: profile.techniques.map(_buildCard).toList(),
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
                Text('无法加载功法图鉴：$error'),
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

  Widget _buildCard(TechniqueSummary technique) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              technique.name,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 6),
            Text(
              '类型：${_labelForTechnique(technique.type)} · 精通度：${technique.mastery}%',
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: technique.synergies
                  .map(
                    (synergy) => Chip(
                      avatar: const Icon(Icons.auto_awesome, size: 16),
                      label: Text(synergy),
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      ),
    );
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
}
