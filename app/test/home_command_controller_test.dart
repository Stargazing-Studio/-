import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ling_yan_tian_ji/src/core/network/api_client.dart';
import 'package:ling_yan_tian_ji/src/features/common/models/game_entities.dart';
import 'package:ling_yan_tian_ji/src/features/home/application/command_center_controller.dart';

void main() {
  group('HomeCommandController', () {
    test('submitCommand stores command record and feedback', () async {
      final container = ProviderContainer(
        overrides: [
          apiClientProvider.overrideWithValue(_FakeApiClient()),
        ],
      );
      addTearDown(container.dispose);

      final controller =
          container.read(homeCommandControllerProvider.notifier);

      expect(controller.state.history, isEmpty);
      final record = await controller.submitCommand('测试指令');

      expect(record, isNotNull);
      expect(controller.state.history, isNotEmpty);
      expect(controller.state.history.first.content, '测试指令');
      expect(controller.state.history.first.feedback, contains('测试指令'));
      expect(controller.state.isSubmitting, isFalse);
      expect(controller.state.lastFeedback, contains('测试指令'));
    });

    test('clearHistory removes stored records', () async {
      final container = ProviderContainer(
        overrides: [
          apiClientProvider.overrideWithValue(_FakeApiClient()),
        ],
      );
      addTearDown(container.dispose);

      final controller =
          container.read(homeCommandControllerProvider.notifier);
      await controller.submitCommand('第一次指令');
      await controller.submitCommand('第二次指令');

      expect(controller.state.history.length, 2);

      controller.clearHistory();
      expect(controller.state.history, isEmpty);
    });
  });
}

class _FakeApiClient extends ApiClient {
  _FakeApiClient() : super(Dio());

  int _counter = 0;

  @override
  Future<CommandResponseData> submitCommand(String content) async {
    _counter++;
    final now = DateTime.now();
    final entry = CommandHistoryEntry(
      id: 'cmd-$_counter',
      content: content,
      feedback: '天机回应：$content',
      createdAt: now,
    );
    final log = ChronicleLog(
      id: 'log-$_counter',
      title: '测试事件',
      summary: '收到指令：$content',
      tags: const ['测试'],
      timestamp: now,
    );
    return CommandResponseData(command: entry, log: log);
  }
}
