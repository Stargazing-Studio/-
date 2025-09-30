import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'package:ling_yan_tian_ji/src/core/config/app_config.dart';
import 'package:ling_yan_tian_ji/src/features/common/data/mock_data.dart';
import 'package:ling_yan_tian_ji/src/features/common/models/game_entities.dart';
import 'package:ling_yan_tian_ji/src/core/storage/local_cache.dart';
import 'package:ling_yan_tian_ji/src/core/network/api_client.dart';

final homeLiveUpdatesProvider = StateNotifierProvider<
    HomeLiveUpdatesController, AsyncValue<HomeLiveUpdatesState>>((ref) {
  return HomeLiveUpdatesController(ref);
});

class HomeLiveUpdatesController
    extends StateNotifier<AsyncValue<HomeLiveUpdatesState>> {
  HomeLiveUpdatesController(
    this._ref, {
    bool autoConnect = true,
  })  : _autoConnect = autoConnect,
        super(const AsyncValue<HomeLiveUpdatesState>.loading()) {
    if (_autoConnect) {
      _connect();
    }
  }

  final Ref _ref;
  final bool _autoConnect;
  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _subscription;
  bool _disposed = false;

  Future<void> _connect() async {
    if (_disposed) {
      return;
    }
    final config = _ref.read(appConfigProvider);
    state = const AsyncValue<HomeLiveUpdatesState>.loading();
    try {
      final uri = Uri.parse(config.wsChroniclesUrl);
      _channel = WebSocketChannel.connect(uri);
      _subscription = _channel!.stream.listen(
        _handleMessage,
        onError: (error, stackTrace) {
          _setDisconnected('实时通道异常：$error');
        },
        onDone: () {
          _setDisconnected('实时通道已关闭');
        },
      );
      state = AsyncValue.data(
        HomeLiveUpdatesState(
          status: HomeSocketStatus.connected,
          lastHeartbeatAt: DateTime.now(),
          recentEvents: const [],
        ),
      );
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  void _handleMessage(dynamic payload) {
    final data = _decodePayload(payload);
    if (data == null) {
      return;
    }
    final type = data['type'] as String?;
    if (type == 'snapshot') {
      // 1) 刷新时间线列表
      final items = (data['logs'] as List<dynamic>)
          .map((item) => ChronicleLog.fromJson(item as Map<String, dynamic>))
          .toList();
      _ref.read(chronicleLogsProvider.notifier).replaceAll(items);
      // 2) 将最新一条作为最近事件，便于首页头部直接展示
      final events = items
          .map(
            (log) => LiveUpdateEvent(
              id: log.id,
              title: log.title,
              summary: log.summary,
              tags: log.tags,
              timestamp: log.timestamp,
            ),
          )
          .toList();
      _updateState(
        (value) => value.copyWith(
          status: HomeSocketStatus.connected,
          lastHeartbeatAt: DateTime.now(),
          recentEvents: events.take(6).toList(),
          lastEvent: events.isNotEmpty ? events.first : value.lastEvent,
          disconnectReason: null,
        ),
      );
      // 持久化最新时间线（snapshot）
      () async {
        try {
          final pid = await LocalCache.loadPlayerId() ?? await _ref.read(apiClientProvider).whoAmI();
          if (pid != null) {
            final logs = _ref.read(chronicleLogsProvider).valueOrNull ?? <ChronicleLog>[];
            await LocalCache.saveLogs(pid, logs);
          }
        } catch (_) {}
      }();
    } else if (type == 'chronicle_update') {
      final log = ChronicleLog.fromJson(data['log'] as Map<String, dynamic>);
      _ref.read(chronicleLogsProvider.notifier).prependLog(log);
      final event = LiveUpdateEvent(
        id: log.id,
        title: log.title,
        summary: log.summary,
        tags: log.tags,
        timestamp: log.timestamp,
      );
      _updateState(
        (value) {
          final updates = [event, ...value.recentEvents].take(6).toList();
          return value.copyWith(
            status: HomeSocketStatus.connected,
            lastHeartbeatAt: DateTime.now(),
            recentEvents: updates,
            lastEvent: event,
            disconnectReason: null,
          );
        },
      );
    }
  }

  Map<String, dynamic>? _decodePayload(dynamic payload) {
    if (payload == null) {
      return null;
    }
    if (payload is Map<String, dynamic>) {
      return payload;
    }
    if (payload is String) {
      return jsonDecode(payload) as Map<String, dynamic>;
    }
    if (payload is List<int>) {
      return jsonDecode(utf8.decode(payload)) as Map<String, dynamic>;
    }
    return null;
  }

  void _updateState(
    HomeLiveUpdatesState Function(HomeLiveUpdatesState value) transform,
  ) {
    state = state.whenData(transform);
  }

  void _setDisconnected(String message) {
    state = state.whenData(
      (value) => value.copyWith(
        status: HomeSocketStatus.disconnected,
        disconnectReason: message,
      ),
    );
  }

  Future<void> reconnect() async {
    await _closeChannel();
    await _connect();
  }

  void markDisconnected([String? reason]) {
    _setDisconnected(reason ?? '连接已断开');
  }

  Future<void> _closeChannel() async {
    await _subscription?.cancel();
    await _channel?.sink.close();
    _subscription = null;
    _channel = null;
  }

  @override
  void dispose() {
    _disposed = true;
    _closeChannel();
    super.dispose();
  }
}

enum HomeSocketStatus { connecting, connected, disconnected }

class HomeLiveUpdatesState {
  const HomeLiveUpdatesState({
    required this.status,
    required this.lastHeartbeatAt,
    required this.recentEvents,
    this.lastEvent,
    this.disconnectReason,
  });

  final HomeSocketStatus status;
  final DateTime? lastHeartbeatAt;
  final List<LiveUpdateEvent> recentEvents;
  final LiveUpdateEvent? lastEvent;
  final String? disconnectReason;

  HomeLiveUpdatesState copyWith({
    HomeSocketStatus? status,
    DateTime? lastHeartbeatAt,
    List<LiveUpdateEvent>? recentEvents,
    LiveUpdateEvent? lastEvent,
    String? disconnectReason,
  }) {
    return HomeLiveUpdatesState(
      status: status ?? this.status,
      lastHeartbeatAt: lastHeartbeatAt ?? this.lastHeartbeatAt,
      recentEvents: recentEvents ?? this.recentEvents,
      lastEvent: lastEvent ?? this.lastEvent,
      disconnectReason: disconnectReason ?? this.disconnectReason,
    );
  }
}

class LiveUpdateEvent {
  const LiveUpdateEvent({
    required this.id,
    required this.title,
    required this.summary,
    required this.tags,
    required this.timestamp,
  });

  final String id;
  final String title;
  final String summary;
  final List<String> tags;
  final DateTime timestamp;

  ChronicleLog toChronicleLog() {
    return ChronicleLog(
      id: id,
      title: title,
      summary: summary,
      tags: tags,
      timestamp: timestamp,
    );
  }
}
