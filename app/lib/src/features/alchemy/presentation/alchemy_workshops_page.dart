import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ling_yan_tian_ji/src/features/common/data/mock_data.dart';

class AlchemyWorkshopsPage extends ConsumerWidget {
  const AlchemyWorkshopsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recipesState = ref.watch(pillRecipesProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('炼丹工坊')),
      body: recipesState.when(
        data: (recipes) => ListView.separated(
          padding: const EdgeInsets.all(20),
          itemCount: recipes.length,
          separatorBuilder: (_, __) => const SizedBox(height: 16),
          itemBuilder: (context, index) {
            final recipe = recipes[index];
            return Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${recipe.name} · ${recipe.grade}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text('难度：${recipe.difficulty}'),
                    const SizedBox(height: 12),
                    const Text(
                      '基础药效',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    ...recipe.baseEffects.map(
                      (effect) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          children: [
                            const Icon(Icons.auto_fix_high, size: 18),
                            const SizedBox(width: 8),
                            Expanded(child: Text(effect)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      '所需材料',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Column(
                      children: recipe.materials
                          .map(
                            (material) => ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: const Icon(Icons.grass, size: 20),
                              title: Text(material.name),
                              subtitle: Text('来源：${material.origin}'),
                              trailing: Text('×${material.quantity}'),
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: FilledButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.science_outlined),
                        label: const Text('启动炼丹流程'),
                      ),
                    ),
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
                Text('无法获取炼丹配方：$error'),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () async {
                    ref.invalidate(pillRecipesProvider);
                    await ref.read(pillRecipesProvider.future);
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