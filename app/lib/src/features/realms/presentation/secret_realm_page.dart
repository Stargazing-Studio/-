import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ling_yan_tian_ji/src/features/common/data/mock_data.dart';
import 'package:ling_yan_tian_ji/src/features/common/models/game_entities.dart';
import 'package:ling_yan_tian_ji/src/shared/widgets/navigation_scaffold.dart';

class SecretRealmPage extends ConsumerWidget {
  const SecretRealmPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final realmsState = ref.watch(secretRealmsProvider);
    return NavigationScaffold(
      appBar: AppBar(title: const Text('秘境动态')),
      body: realmsState.when(
        data: (realms) => ListView.separated(
          padding: const EdgeInsets.all(20),
          itemCount: realms.length,
          separatorBuilder: (_, __) => const SizedBox(height: 16),
          itemBuilder: (context, index) {
            final realm = realms[index];
            return Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.forest_outlined),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${realm.name} · T${realm.tier}',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        const SizedBox(width: 8),
                        _RealmStatusBadge(realm: realm),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text('开放规则：${realm.schedule}', maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            );
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
                Text('无法获取秘境动态：$error'),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () async {
                    ref.invalidate(secretRealmsProvider);
                    await ref.read(secretRealmsProvider.future);
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

class _RealmStatusBadge extends StatelessWidget {
  const _RealmStatusBadge({required this.realm});
  final SecretRealm realm;

  bool get _enterable {
    // 简化策略：若 schedule 包含“开启/开放”等关键词则视为可进入；否则不可进入
    final s = realm.schedule;
    return s.contains('开') || s.contains('启') || s.contains('开放');
  }

  @override
  Widget build(BuildContext context) {
    final ok = _enterable;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: ok ? const Color(0x3326A69A) : const Color(0x33E57373),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(ok ? '可进入' : '不可进入'),
    );
  }
}
