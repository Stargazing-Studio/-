import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:dio/dio.dart';
import 'package:ling_yan_tian_ji/src/core/network/api_client.dart';
import 'dart:async';
import 'package:ling_yan_tian_ji/src/core/storage/local_cache.dart';

final homeCommandControllerProvider =
    StateNotifierProvider<HomeCommandController, HomeCommandState>(
  (ref) => HomeCommandController(ref),
);

class HomeCommandController extends StateNotifier<HomeCommandState> {
  HomeCommandController(this._ref) : super(const HomeCommandState()) {
    // 首次加载时从服务端拉取历史，填充聊天记录
    scheduleMicrotask(_loadInitialHistory);
  }

  final Ref _ref;

  Future<void> _loadInitialHistory() async {
    try {
      final api = _ref.read(apiClientProvider);
      final items = await api.fetchCommandHistory();
      final records = items
          .map((c) => CommandRecord(
                id: c.id,
                content: c.content,
                feedback: c.feedback,
                timestamp: c.createdAt,
              ))
          .toList();
      // 以时间倒序（最近在前）存储，显示时按从旧到新渲染
      final limited = records.take(HomeCommandState.historyLimit).toList();
      state = state.copyWith(history: limited);
    } catch (_) {
      // 忽略加载错误，不阻断页面
    }
  }

  Future<CommandRecord?> submitCommand(String rawText) async {
    final text = rawText.trim();
    if (text.isEmpty) {
      return null;
    }
    state = state.copyWith(isSubmitting: true, lastFeedback: null);
    try {
      final api = _ref.read(apiClientProvider);
      final response = await api.submitCommand(text);
      final command = response.command;
      final record = CommandRecord(
        id: command.id,
        content: command.content,
        feedback: command.feedback,
        timestamp: command.createdAt,
      );
      final updatedHistory = <CommandRecord>[record, ...state.history]
          .take(HomeCommandState.historyLimit)
          .toList();
      state = state.copyWith(
        isSubmitting: false,
        history: updatedHistory,
        lastFeedback: command.feedback,
      );
      // 持久化对话记录（命令历史）
      () async {
        try {
          final pid = await LocalCache.loadPlayerId() ?? await _ref.read(apiClientProvider).whoAmI();
          if (pid != null) {
            // 将本地 CommandRecord 转换为 API 的 CommandHistoryEntry 结构存储
            final converted = updatedHistory
                .map((r) => CommandHistoryEntry(
                      id: r.id,
                      content: r.content,
                      feedback: r.feedback,
                      createdAt: r.timestamp,
                    ))
                .toList();
            await LocalCache.saveCommands(pid, converted);
          }
        } catch (_) {}
      }();
      return record;
    } catch (error) {
      var message = '指令发送失败：$error';
      if (error is DioException) {
        final data = error.response?.data;
        if (data is Map && data['detail'] != null) {
          message = '指令发送失败：${data['detail']}';
        } else if (error.message != null) {
          message = '指令发送失败：${error.message}';
        }
      }
      state = state.copyWith(
        isSubmitting: false,
        lastFeedback: message,
      );
      return null;
    }
  }

  void acknowledgeFeedback() {
    if (state.lastFeedback == null) {
      return;
    }
    state = state.copyWith(lastFeedback: null);
  }

  void clearHistory() {
    if (state.history.isEmpty) {
      return;
    }
    state = state.copyWith(history: const []);
  }
}

class HomeCommandState {
  const HomeCommandState({
    this.history = const [],
    this.isSubmitting = false,
    this.lastFeedback,
  });

  static const historyLimit = 20;

  final List<CommandRecord> history;
  final bool isSubmitting;
  final String? lastFeedback;

  HomeCommandState copyWith({
    List<CommandRecord>? history,
    bool? isSubmitting,
    String? lastFeedback,
  }) {
    return HomeCommandState(
      history: history ?? this.history,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      lastFeedback: lastFeedback,
    );
  }
}

class CommandRecord {
  const CommandRecord({
    required this.id,
    required this.content,
    required this.feedback,
    required this.timestamp,
  });

  final String id;
  final String content;
  final String feedback;
  final DateTime timestamp;
}
