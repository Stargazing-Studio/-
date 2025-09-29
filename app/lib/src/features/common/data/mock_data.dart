import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ling_yan_tian_ji/src/core/network/api_client.dart';
import 'package:ling_yan_tian_ji/src/features/common/models/game_entities.dart';

final playerProfileProvider = FutureProvider<PlayerProfile>((ref) async {
  final api = ref.watch(apiClientProvider);
  return api.fetchProfile();
});

final companionsProvider = FutureProvider<List<Companion>>((ref) async {
  final api = ref.watch(apiClientProvider);
  return api.fetchCompanions();
});

final secretRealmsProvider = FutureProvider<List<SecretRealm>>((ref) async {
  final api = ref.watch(apiClientProvider);
  return api.fetchSecretRealms();
});

final ascensionChallengesProvider =
    FutureProvider<List<AscensionChallenge>>((ref) async {
  final api = ref.watch(apiClientProvider);
  return api.fetchAscensionChallenges();
});

final pillRecipesProvider = FutureProvider<List<PillRecipe>>((ref) async {
  final api = ref.watch(apiClientProvider);
  return api.fetchPillRecipes();
});

final chronicleLogsProvider = StateNotifierProvider<ChronicleLogsController,
    AsyncValue<List<ChronicleLog>>>((ref) {
  return ChronicleLogsController(ref);
});

class ChronicleLogsController
    extends StateNotifier<AsyncValue<List<ChronicleLog>>> {
  ChronicleLogsController(this._ref)
      : super(const AsyncValue<List<ChronicleLog>>.loading()) {
    _loadInitial();
  }

  static const int _maxEntries = 128;

  final Ref _ref;

  Future<void> refresh() => _loadInitial();

  Future<void> _loadInitial() async {
    state = const AsyncValue<List<ChronicleLog>>.loading();
    try {
      final api = _ref.read(apiClientProvider);
      final logs = await api.fetchChronicles();
      state = AsyncValue.data(_truncate(logs));
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  void replaceAll(List<ChronicleLog> logs) {
    state = AsyncValue.data(_truncate(logs));
  }

  void prependLog(ChronicleLog log) {
    final current = state.valueOrNull ?? <ChronicleLog>[];
    final merged = [log, ...current.where((item) => item.id != log.id)];
    state = AsyncValue.data(_truncate(merged));
  }

  List<ChronicleLog> _truncate(List<ChronicleLog> source) {
    return source.take(_maxEntries).toList(growable: false);
  }
}
