import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:ling_yan_tian_ji/src/features/common/models/game_entities.dart';
import 'package:ling_yan_tian_ji/src/core/network/api_client.dart';

class LocalCacheKeys {
  static String playerId() => 'player_id';
  static String profile(String pid) => 'player:$pid:profile';
  static String logs(String pid) => 'player:$pid:logs';
  static String commands(String pid) => 'player:$pid:commands';
}

class LocalCache {
  static Future<SharedPreferences> _prefs() async => SharedPreferences.getInstance();

  static Future<void> savePlayerId(String pid) async {
    final p = await _prefs();
    await p.setString(LocalCacheKeys.playerId(), pid);
  }

  static Future<String?> loadPlayerId() async {
    final p = await _prefs();
    return p.getString(LocalCacheKeys.playerId());
  }

  static Future<void> saveProfile(String pid, PlayerProfile profile) async {
    final p = await _prefs();
    final json = jsonEncode(profile.toJson());
    await p.setString(LocalCacheKeys.profile(pid), json);
  }

  static Future<PlayerProfile?> loadProfile(String pid) async {
    final p = await _prefs();
    final s = p.getString(LocalCacheKeys.profile(pid));
    if (s == null) return null;
    final map = jsonDecode(s) as Map<String, dynamic>;
    return PlayerProfile.fromJson(map);
  }

  static Future<void> saveLogs(String pid, List<ChronicleLog> logs) async {
    final p = await _prefs();
    final data = logs
        .map((e) => {
              'id': e.id,
              'title': e.title,
              'summary': e.summary,
              'tags': e.tags,
              'timestamp': e.timestamp.toIso8601String(),
            })
        .toList();
    await p.setString(LocalCacheKeys.logs(pid), jsonEncode(data));
  }

  static Future<List<ChronicleLog>> loadLogs(String pid) async {
    final p = await _prefs();
    final s = p.getString(LocalCacheKeys.logs(pid));
    if (s == null) return [];
    final list = jsonDecode(s) as List<dynamic>;
    return list
        .map((e) => ChronicleLog.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static Future<void> saveCommands(String pid, List<CommandHistoryEntry> cmds) async {
    final p = await _prefs();
    final data = cmds
        .map((c) => {
              'id': c.id,
              'content': c.content,
              'feedback': c.feedback,
              'created_at': c.createdAt.toIso8601String(),
            })
        .toList();
    await p.setString(LocalCacheKeys.commands(pid), jsonEncode(data));
  }

  static Future<List<CommandHistoryEntry>> loadCommands(String pid) async {
    final p = await _prefs();
    final s = p.getString(LocalCacheKeys.commands(pid));
    if (s == null) return [];
    final list = jsonDecode(s) as List<dynamic>;
    return list
        .map((e) => CommandHistoryEntry.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ===== clear helpers =====
  static Future<void> clearFor(String pid) async {
    final p = await _prefs();
    await p.remove(LocalCacheKeys.profile(pid));
    await p.remove(LocalCacheKeys.logs(pid));
    await p.remove(LocalCacheKeys.commands(pid));
  }

  static Future<void> clearPlayerId() async {
    final p = await _prefs();
    await p.remove(LocalCacheKeys.playerId());
  }

  static Future<void> clearAll() async {
    final p = await _prefs();
    final keys = p.getKeys();
    for (final k in keys) {
      if (k == LocalCacheKeys.playerId() || k.startsWith('player:')) {
        await p.remove(k);
      }
    }
  }
}
