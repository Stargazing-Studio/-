import 'package:flutter_test/flutter_test.dart';

import 'package:ling_yan_tian_ji/src/features/home/application/log_filter_controller.dart';

void main() {
  group('LogFilterController', () {
    test('toggleTag adds and removes filters', () {
      final controller = LogFilterController();
      expect(controller.state, isEmpty);

      controller.toggleTag('秘境');
      expect(controller.state, contains('秘境'));

      controller.toggleTag('秘境');
      expect(controller.state, isEmpty);
    });

    test('clear() resets filters to empty set', () {
      final controller = LogFilterController();
      controller.toggleTag('飞升');
      controller.toggleTag('丹药');
      expect(controller.state.length, 2);

      controller.clear();
      expect(controller.state, isEmpty);
    });
  });
}
