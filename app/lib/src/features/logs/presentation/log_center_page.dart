import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:ling_yan_tian_ji/src/features/common/data/mock_data.dart';

final DateFormat _logTimestampFormat = DateFormat('yyyy-MM-dd HH:mm');

class LogCenterPage extends ConsumerWidget {
  const LogCenterPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logsState = ref.watch(chronicleLogsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('事件编年史')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: logsState.when(
          data: (logs) => ListView.separated(
            itemCount: logs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 14),
            itemBuilder: (context, index) {
              final log = logs[index];
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        log.title,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(log.summary),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: log.tags
                            .map((tag) => Chip(label: Text(tag)))
                            .toList(),
                      ),
                      const SizedBox(height: 6),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          _logTimestampFormat.format(log.timestamp.toLocal()),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          loading: () => const Center(
            child: CircularProgressIndicator(),
          ),
          error: (error, _) => Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, color: Colors.redAccent),
                const SizedBox(height: 12),
                Text('无法获取事件记录：$error'),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () async {
                  await ref.read(chronicleLogsProvider.notifier).refresh();
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
