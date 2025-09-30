import 'dart:convert';
import 'dart:html' as html;

import 'package:ling_yan_tian_ji/src/features/common/models/game_entities.dart';
import 'package:ling_yan_tian_ji/src/core/network/api_client.dart';

class LocalCacheKeys {
  static String playerId() => 'player_id';
  static String profile(String pid) => 'player:$pid:profile';
  static String logs(String pid) => 'player:$pid:logs';
  static String commands(String pid) => 'player:$pid:commands';
}

class LocalCache {
  static Future<void> savePlayerId(String pid) async {
    html.window.localStorage[LocalCacheKeys.playerId()] = pid;
  }

  static Future<String?> loadPlayerId() async {
    return html.window.localStorage[LocalCacheKeys.playerId()];
  }

  static Future<void> saveProfile(String pid, PlayerProfile profile) async {
    html.window.localStorage[LocalCacheKeys.profile(pid)] = jsonEncode(profile.toJson());
  }

  static Future<PlayerProfile?> loadProfile(String pid) async {
    final s = html.window.localStorage[LocalCacheKeys.profile(pid)];
    if (s == null) return null;
    final map = jsonDecode(s) as Map<String, dynamic>;
    return PlayerProfile.fromJson(map);
  }

  static Future<void> saveLogs(String pid, List<ChronicleLog> logs) async {
    final data = logs
        .map((e) => {
              'id': e.id,
              'title': e.title,
              'summary': e.summary,
              'tags': e.tags,
              'timestamp': e.timestamp.toIso8601String(),
            })
        .toList();
    html.window.localStorage[LocalCacheKeys.logs(pid)] = jsonEncode(data);
  }

  static Future<List<ChronicleLog>> loadLogs(String pid) async {
    final s = html.window.localStorage[LocalCacheKeys.logs(pid)];
    if (s == null) return [];
    final list = jsonDecode(s) as List<dynamic>;
    return list
        .map((e) => ChronicleLog.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static Future<void> saveCommands(String pid, List<CommandHistoryEntry> cmds) async {
    final data = cmds
        .map((c) => {
              'id': c.id,
              'content': c.content,
              'feedback': c.feedback,
              'created_at': c.createdAt.toIso8601String(),
            })
        .toList();
    html.window.localStorage[LocalCacheKeys.commands(pid)] = jsonEncode(data);
  }

  static Future<List<CommandHistoryEntry>> loadCommands(String pid) async {
    final s = html.window.localStorage[LocalCacheKeys.commands(pid)];
    if (s == null) return [];
    final list = jsonDecode(s) as List<dynamic>;
    return list
        .map((e) => CommandHistoryEntry.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static Future<void> clearFor(String pid) async {
    html.window.localStorage.remove(LocalCacheKeys.profile(pid));
    html.window.localStorage.remove(LocalCacheKeys.logs(pid));
    html.window.localStorage.remove(LocalCacheKeys.commands(pid));
  }

  static Future<void> clearPlayerId() async {
    html.window.localStorage.remove(LocalCacheKeys.playerId());
  }

  static Future<void> clearAll() async {
    final toRemove = <String>[];
    for (var i = 0; i < html.window.localStorage.length; i++) {
      final key = html.window.localStorage.keys.elementAt(i);
      if (key == LocalCacheKeys.playerId() || key.startsWith('player:')) {
        toRemove.add(key);
      }
    }
    for (final k in toRemove) {
      html.window.localStorage.remove(k);
    }
  }
}
