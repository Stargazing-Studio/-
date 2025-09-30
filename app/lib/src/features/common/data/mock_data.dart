import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'dart:async' show unawaited;
import 'package:ling_yan_tian_ji/src/core/network/api_client.dart';
import 'package:ling_yan_tian_ji/src/core/storage/local_cache.dart';
import 'package:ling_yan_tian_ji/src/features/common/models/game_entities.dart';

final playerProfileProvider = FutureProvider<PlayerProfile>((ref) async {
  final api = ref.watch(apiClientProvider);
  // 优先使用本地 player_id，避免请求 /whoami 生成新身份
  try {
    final cachedPid = await LocalCache.loadPlayerId();
    if (cachedPid != null) {
      final cached = await LocalCache.loadProfile(cachedPid);
      if (cached != null) {
        // 后台必定触发一次 /profile，确保后端被请求
        unawaited(api.fetchProfile().then((fresh) async {
          try { await LocalCache.saveProfile(cachedPid, fresh); } catch (_) {}
        }).catchError((_) {}));
        return cached;
      }
    }
  } catch (_) {}
  // 首次无缓存：请求后端并写入本地
  try {
    final profile = await api.fetchProfile();
    try {
      final pid = await api.whoAmI();
      if (pid != null) {
        await LocalCache.savePlayerId(pid);
        await LocalCache.saveProfile(pid, profile);
      }
    } catch (_) {}
    return profile;
  } on DioException catch (e) {
    // 世界/玩家被清空时，清理本地缓存避免展示旧数据
    try {
      final pid = await LocalCache.loadPlayerId();
      if (pid != null) {
        await LocalCache.clearFor(pid);
      }
      await LocalCache.clearPlayerId();
    } catch (_) {}
    rethrow;
  }
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
      // 本地优先：使用已缓存的 pid 避免 /whoami 生成新身份
      try {
        final cachedPid = await LocalCache.loadPlayerId();
        if (cachedPid != null) {
          final cached = await LocalCache.loadLogs(cachedPid);
          if (cached.isNotEmpty) {
            state = AsyncValue.data(_truncate(cached));
          }
        }
      } catch (_) {}
      // 远端覆盖并更新本地
      final logs = await api.fetchChronicles();
      final truncated = _truncate(logs);
      state = AsyncValue.data(truncated);
      try {
        final pid = await LocalCache.loadPlayerId() ?? await api.whoAmI();
        if (pid != null) {
          await LocalCache.saveLogs(pid, truncated);
        }
      } catch (_) {}
    } on DioException catch (e) {
      // 若服务端已清空世界/玩家，则显示空列表而非错误
      state = const AsyncValue<List<ChronicleLog>>.data(<ChronicleLog>[]);
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
