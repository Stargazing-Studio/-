import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ling_yan_tian_ji/src/app.dart';
import 'package:ling_yan_tian_ji/src/core/config/app_config.dart';
import 'package:ling_yan_tian_ji/src/core/network/api_client.dart';
import 'package:ling_yan_tian_ji/src/features/common/models/game_entities.dart';
import 'package:ling_yan_tian_ji/src/features/home/application/live_updates_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('首页黄金路径：加载、提交指令并刷新列表', (tester) async {
    final binding = tester.binding;
    binding.window.physicalSizeTestValue = const Size(1280, 2400);
    binding.window.devicePixelRatioTestValue = 1.0;
    addTearDown(() {
      binding.window.clearPhysicalSizeTestValue();
      binding.window.clearDevicePixelRatioTestValue();
    });
    final overrides = [
      appConfigProvider.overrideWithValue(
        const AppConfig(
          apiBaseUrl: 'http://integration.test',
          wsChroniclesUrl: 'ws://integration.test/ws/chronicles',
        ),
      ),
      apiClientProvider.overrideWithValue(_FakeApiClient()),
      homeLiveUpdatesProvider.overrideWith((ref) => _FakeLiveUpdatesController(ref)),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: overrides,
        child: const DaoYanApp(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('宁昭'), findsOneWidget);
    expect(find.text('灵台巡查日报'), findsOneWidget);

    const testCommand = '测试黄金路径指令';
    await tester.enterText(find.byType(TextField), testCommand);
    await tester.tap(find.widgetWithText(ElevatedButton, '提交'));
    await tester.pumpAndSettle();

    expect(find.text(testCommand), findsWidgets);
    expect(find.textContaining('天机反馈'), findsWidgets);

    await tester.tap(find.text('秘境状况'));
    await tester.pump();
    expect(find.widgetWithText(FilterChip, '秘境'), findsWidgets);
  });
}

class _FakeApiClient extends ApiClient {
  _FakeApiClient() : super(Dio());

  final DateTime _now = DateTime(2025, 2, 14, 9, 0);

  @override
  Future<PlayerProfile> fetchProfile() async {
    return const PlayerProfile(
      id: 'player-1024',
      name: '宁昭',
      realm: '金丹后期',
      guild: '天衍盟',
      factionReputation: {
        '丹霞宗': 62,
        '无极居': 38,
      },
      attributes: {
        '灵力': 14280,
        '体魄': 11860,
      },
      techniques: [
        TechniqueSummary(
          id: 'tech-aurora',
          name: '玄光凝星诀',
          type: TechniqueType.core,
          mastery: 87,
          synergies: ['太初养灵篇'],
        ),
      ],
      achievements: ['丹霞供奉长老'],
      ascensionProgress: AscensionProgress(
        stage: '元婴初显',
        score: 2680,
        nextMilestone: '完成《玄武锻身录》终章',
      ),
    );
  }

  @override
  Future<List<ChronicleLog>> fetchChronicles() async {
    return [
      ChronicleLog(
        id: 'log-1',
        title: '灵台巡查日报',
        summary: '巡查丹霞秘境灵潮波动，稳定异常节点。',
        tags: const ['秘境', '巡防'],
        timestamp: _now,
      ),
    ];
  }

  @override
  Future<List<AscensionChallenge>> fetchAscensionChallenges() async {
    return [
      const AscensionChallenge(
        id: 'asc-1',
        title: '玄光凌霄试炼',
        difficulty: '高',
        requirements: ['保持灵压稳定在 85% 以上'],
        rewards: ['玄光星尘 x12'],
      ),
    ];
  }

  @override
  Future<List<Companion>> fetchCompanions() async {
    return [
      const Companion(
        id: 'comp-1',
        name: '银焰灵狐',
        role: CompanionRole.guardian,
        personality: '沉稳谨慎',
        bondLevel: 76,
        skills: ['焰刃连斩'],
        mood: '专注',
        fatigue: 12,
        traits: ['远程侦察'],
      ),
    ];
  }

  @override
  Future<List<SecretRealm>> fetchSecretRealms() async {
    return [
      const SecretRealm(
        id: 'realm-1',
        name: '丹霞流辉谷',
        tier: 4,
        schedule: '每周三开放',
        environment: {'灵气浓度': 1.8},
        recommendedPower: 7800,
        dynamicEvents: ['赤焰风暴将至'],
      ),
    ];
  }

  @override
  Future<List<PillRecipe>> fetchPillRecipes() async {
    return [
      const PillRecipe(
        id: 'pill-1',
        name: '固本醒神丹',
        grade: '四品',
        baseEffects: ['筑基成功率 +22%'],
        materials: [
          RecipeMaterial(name: '星蕴草', quantity: 3, origin: '星河折影渊'),
        ],
        difficulty: 68,
      ),
    ];
  }

  @override
  Future<List<CommandHistoryEntry>> fetchCommandHistory() async {
    return [];
  }

  int _commandCounter = 0;

  @override
  Future<CommandResponseData> submitCommand(String content) async {
    _commandCounter += 1;
    final createdAt = _now.add(Duration(minutes: _commandCounter));
    final entry = CommandHistoryEntry(
      id: 'cmd-$_commandCounter',
      content: content,
      feedback: '天机反馈：$content',
      createdAt: createdAt,
    );
    final log = ChronicleLog(
      id: 'log-cmd-$_commandCounter',
      title: '即时播报',
      summary: '天机阁记录了指令：$content',
      tags: const ['指令'],
      timestamp: createdAt,
    );
    return CommandResponseData(command: entry, log: log);
  }
}

class _FakeLiveUpdatesController extends HomeLiveUpdatesController {
  _FakeLiveUpdatesController(super.ref) : super(autoConnect: false) {
    state = AsyncValue.data(
      HomeLiveUpdatesState(
        status: HomeSocketStatus.connected,
        lastHeartbeatAt: DateTime.now(),
        recentEvents: const [],
      ),
    );
  }
}
