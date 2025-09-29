import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ling_yan_tian_ji/src/core/network/api_client.dart';
import 'package:ling_yan_tian_ji/src/features/common/data/mock_data.dart';
import 'package:ling_yan_tian_ji/src/features/common/models/game_entities.dart';

void main() {
  List<ChronicleLog> logsOf(ChronicleLogsController controller) {
    return controller.state.maybeWhen(
      data: (logs) => logs,
      orElse: () => <ChronicleLog>[],
    );
  }

  group('ChronicleLogsController', () {
    test('initial bootstrap loads default logs', () async {
      final fakeApi = _LogsFakeApiClient();
      final container = ProviderContainer(
        overrides: [apiClientProvider.overrideWithValue(fakeApi)],
      );
      addTearDown(container.dispose);

      final controller =
          container.read(chronicleLogsProvider.notifier);
      await controller.refresh();

      final logs = logsOf(controller);
      expect(logs, isNotEmpty);
      expect(fakeApi.fetchCount, greaterThanOrEqualTo(1));
    });

    test('prependLog inserts new log at the top', () async {
      final fakeApi = _LogsFakeApiClient();
      final container = ProviderContainer(
        overrides: [apiClientProvider.overrideWithValue(fakeApi)],
      );
      addTearDown(container.dispose);

      final controller =
          container.read(chronicleLogsProvider.notifier);
      await controller.refresh();

      final log = ChronicleLog(
        id: 'test-log',
        title: '测试事件',
        summary: '用于验证新增事件写入列表。',
        tags: const ['测试'],
        timestamp: DateTime.now(),
      );

      controller.prependLog(log);
      final logs = logsOf(controller);
      expect(logs.first.id, log.id);
    });

    test('refresh emits loading state before providing data', () async {
      final fakeApi = _LogsFakeApiClient();
      final container = ProviderContainer(
        overrides: [apiClientProvider.overrideWithValue(fakeApi)],
      );
      addTearDown(container.dispose);

      final controller =
          container.read(chronicleLogsProvider.notifier);
      await controller.refresh();

      expect(controller.state.isLoading, isFalse);
      expect(logsOf(controller), isNotEmpty);
    });
  });
}

class _LogsFakeApiClient extends ApiClient {
  _LogsFakeApiClient() : super(Dio());

  int fetchCount = 0;

  @override
  Future<List<ChronicleLog>> fetchChronicles() async {
    fetchCount++;
    return [
      ChronicleLog(
        id: 'log-1',
        title: '测试日志',
        summary: '用于测试的事件日志。',
        tags: const ['测试'],
        timestamp: DateTime.now(),
      ),
    ];
  }
}
