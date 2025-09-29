import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ling_yan_tian_ji/src/features/common/data/mock_data.dart';
import 'package:ling_yan_tian_ji/src/features/common/models/game_entities.dart';

final logFilterProvider =
    StateNotifierProvider<LogFilterController, Set<String>>(
      (ref) => LogFilterController(),
    );

final availableLogTagsProvider = Provider<List<String>>((ref) {
  final logsState = ref.watch(chronicleLogsProvider);
  return logsState.maybeWhen(
    data: (logs) {
      final tagSet = <String>{};
      for (final log in logs) {
        tagSet.addAll(log.tags);
      }
      final tags = tagSet.toList()..sort();
      return tags;
    },
    orElse: () => const [],
  );
});

final filteredLogsProvider = Provider<AsyncValue<List<ChronicleLog>>>((ref) {
  final filters = ref.watch(logFilterProvider);
  final logsState = ref.watch(chronicleLogsProvider);
  return logsState.when(
    data: (logs) {
      if (filters.isEmpty) {
        return AsyncValue.data(logs);
      }
      final filtered =
          logs.where((log) => log.tags.any(filters.contains)).toList();
      return AsyncValue.data(filtered);
    },
    loading: () => const AsyncValue<List<ChronicleLog>>.loading(),
    error: (error, stackTrace) => AsyncValue.error(error, stackTrace),
  );
});

class LogFilterController extends StateNotifier<Set<String>> {
  LogFilterController() : super(<String>{});

  void toggleTag(String tag) {
    final updated = Set<String>.from(state);
    if (updated.contains(tag)) {
      updated.remove(tag);
    } else {
      updated.add(tag);
    }
    state = updated;
  }

  void clear() {
    if (state.isEmpty) {
      return;
    }
    state = <String>{};
  }
}
