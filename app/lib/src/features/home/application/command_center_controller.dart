import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:dio/dio.dart';
import 'package:ling_yan_tian_ji/src/core/network/api_client.dart';

final homeCommandControllerProvider =
    StateNotifierProvider<HomeCommandController, HomeCommandState>(
  (ref) => HomeCommandController(ref),
);

class HomeCommandController extends StateNotifier<HomeCommandState> {
  HomeCommandController(this._ref) : super(const HomeCommandState());

  final Ref _ref;

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
