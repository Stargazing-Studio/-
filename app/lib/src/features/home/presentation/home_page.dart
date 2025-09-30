import 'package:flutter/material.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ling_yan_tian_ji/src/core/network/api_client.dart';
import 'package:ling_yan_tian_ji/src/core/storage/local_cache.dart';
import 'package:ling_yan_tian_ji/src/features/common/data/mock_data.dart';
import 'package:ling_yan_tian_ji/src/features/common/models/game_entities.dart';
import 'package:ling_yan_tian_ji/src/features/home/application/command_center_controller.dart';
import 'package:ling_yan_tian_ji/src/features/home/application/live_updates_controller.dart';
// 移除事件筛选与日志叙述所需的筛选控制器引用
import 'package:ling_yan_tian_ji/src/shared/widgets/loading_animations.dart';
import 'package:ling_yan_tian_ji/src/shared/widgets/interactive_animations.dart';
import 'package:ling_yan_tian_ji/src/shared/widgets/main_navigation_bar.dart';

final DateFormat _historyTimestampFormat = DateFormat('yyyy-MM-dd HH:mm');

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 删除“事件变化时底部弹出的最近事件”SnackBar：
    // 原逻辑在收到指令反馈时通过 ScaffoldMessenger 弹出底部通知。
    // 现按需求移除，事件回响请在“事件编年史”的列表与头部信息中查看。

    final profileState = ref.watch(playerProfileProvider);
    // 删除事件叙述与筛选：不再读取日志相关 Provider
    final commandState = ref.watch(homeCommandControllerProvider);
    final liveState = ref.watch(homeLiveUpdatesProvider);
    // 显式“开始修行”入口：手动调用 /profile 完成玩家初始化（设置 Cookie）
    Future<void> _initializePlayer() async {
      // 显式加载遮罩：直到玩家档案与初试事件生成完成（/profile 返回）
      // ignore: use_build_context_synchronously
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => Dialog(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2.8),
                ),
                const SizedBox(width: 16),
                const Text('正在生成初始角色与事件…'),
              ],
            ),
          ),
        ),
      );
      try {
        final api = ref.read(apiClientProvider);
        await api.fetchProfile();
        // 刷新并等待 Provider 完成，确保 UI 同步
        ref.invalidate(playerProfileProvider);
        await ref.read(playerProfileProvider.future);
        // 刷新编年史（若 WS 到达稍晚，确保时间线已可见）
        try {
          await ref.read(chronicleLogsProvider.notifier).refresh();
        } catch (_) {}
        // 保存本地缓存（player_id + 档案），便于后续快速恢复
        try {
          final api2 = ref.read(apiClientProvider);
          final pid = await api2.whoAmI();
          if (pid != null) {
            await LocalCache.savePlayerId(pid);
            final profileNow = await ref.read(playerProfileProvider.future);
            await LocalCache.saveProfile(pid, profileNow);
          }
        } catch (_) {}
        // 重新连接实时通道以携带新的 Cookie（加入玩家私有频道）
        try {
          await ref.read(homeLiveUpdatesProvider.notifier).reconnect();
        } catch (_) {}
        // 成功提示
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('玩家已初始化')),
        );
      } catch (e) {
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('初始化失败：$e')),
        );
      } finally {
        // ignore: use_build_context_synchronously
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
      }
    }
    final isSocketReady = liveState.maybeWhen(
      data: (state) => state.status == HomeSocketStatus.connected,
      orElse: () => false,
    );
    return Scaffold(
      appBar: AppBar(
        title: const Text('灵衍天纪 · 天机问答'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () => context.go('/profile'),
            tooltip: '修士档案',
          ),
          IconButton(
            icon: const Icon(Icons.pets_outlined),
            onPressed: () => context.go('/companions'),
            tooltip: '灵仆灵宠',
          ),
          // 新增：开始修行按钮（初始化玩家信息）
          IconButton(
            icon: const Icon(Icons.play_circle_outline),
            onPressed: _initializePlayer,
            tooltip: '开始修行',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        child: Column(
          children: [
            // 聊天消息列表（从旧到新）
            Expanded(child: _ChatList(commandState: commandState)),
            const SizedBox(height: 8),
            _CommandSection(
              profileState: profileState,
              commandState: commandState,
              isSocketReady: isSocketReady,
            ),
          ],
        ),
      ),
      bottomNavigationBar: const MainNavigationBar(),
    );
  }
}


// 头部不再展示初始事件，仅以聊天列表承载内容

class _CommandSection extends ConsumerWidget {
  const _CommandSection({
    required this.profileState,
    required this.commandState,
    required this.isSocketReady,
  });

  final AsyncValue<PlayerProfile> profileState;
  final HomeCommandState commandState;
  final bool isSocketReady;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return profileState.when(
      data: (profile) => _CommandBar(
        profile: profile,
        commandState: commandState,
        isSocketReady: isSocketReady,
        onSubmit: (input) => ref
            .read(homeCommandControllerProvider.notifier)
            .submitCommand(input)
            .then((value) => value != null),
        onClearHistory: () =>
            ref.read(homeCommandControllerProvider.notifier).clearHistory(),
      ),
      loading: () => const _LoadingPane(message: '指令通道初始化中…'),
      error: (error, stackTrace) => _ErrorPane(
        message: '指令通道未就绪',
        detail: error.toString(),
        actionLabel: '开始', // 明确“开始”动作以初始化玩家
        onRetry: () async {
          ref.invalidate(playerProfileProvider);
          await ref.read(playerProfileProvider.future);
        },
      ),
    );
  }
}

class _ChatList extends StatefulWidget {
  const _ChatList({required this.commandState});

  final HomeCommandState commandState;

  @override
  State<_ChatList> createState() => _ChatListState();
}

class _ChatListState extends State<_ChatList> {
  final _controller = ScrollController();
  int _prevLength = 0;

  void _scrollToBottom() {
    if (!_controller.hasClients) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_controller.hasClients) return;
      _controller.animateTo(
        _controller.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  void initState() {
    super.initState();
    _prevLength = widget.commandState.history.length;
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  @override
  void didUpdateWidget(covariant _ChatList oldWidget) {
    super.didUpdateWidget(oldWidget);
    final cur = widget.commandState.history.length;
    if (cur != _prevLength) {
      _prevLength = cur;
      _scrollToBottom();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.commandState.history.reversed.toList(); // 从旧到新
    return ListView.builder(
      controller: _controller,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: items.length,
      itemBuilder: (ctx, i) {
        final rec = items[i];
        final hasUser = rec.content.trim().isNotEmpty;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (hasUser)
              Align(
                alignment: Alignment.centerRight,
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  constraints: const BoxConstraints(maxWidth: 420),
                  decoration: BoxDecoration(
                    color: const Color(0xFF5C6BC0),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(rec.content, style: const TextStyle(color: Colors.white, height: 1.4)),
                ),
              ),
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                constraints: const BoxConstraints(maxWidth: 520),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(rec.feedback, style: const TextStyle(height: 1.5)),
              ),
            ),
          ],
        );
      },
    );
  }
}

// 删除事件叙述相关组件：_LogsSection/_NarrativeFeed/_DialogueBubble/_DialogueTypingIndicator



class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ),
    );
  }
}

class _LoadingPane extends StatelessWidget {
  const _LoadingPane({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 12),
              Text(message),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorPane extends StatelessWidget {
  const _ErrorPane({
    required this.message,
    required this.detail,
    required this.onRetry,
    this.actionLabel = '重试',
  });

  final String message;
  final String detail;
  final Future<void> Function() onRetry;
  final String actionLabel;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Colors.redAccent),
              const SizedBox(height: 12),
              Text(
                message,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                detail,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.play_arrow_rounded),
                label: Text(actionLabel),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// 删除事件筛选组件 _LogFilterBar

class _CommandBar extends StatefulWidget {
  const _CommandBar({
    required this.profile,
    required this.commandState,
    required this.isSocketReady,
    required this.onSubmit,
    required this.onClearHistory,
  });

  final PlayerProfile profile;
  final HomeCommandState commandState;
  final bool isSocketReady;
  final Future<bool> Function(String) onSubmit;
  final VoidCallback onClearHistory;

  @override
  State<_CommandBar> createState() => _CommandBarState();
}

class _CommandBarState extends State<_CommandBar> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _focusNode = FocusNode();
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.commandState;
    final canSubmit = widget.isSocketReady && !state.isSubmitting;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeInOut,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  enabled: widget.isSocketReady,
                  minLines: 1,
                  maxLines: _isExpanded ? 6 : 2,
                  style: const TextStyle(fontSize: 16),
                  decoration: InputDecoration(
                    hintText:
                        '${widget.profile.name}，输入想法，例如：“我想巡查丹霞秘境的灵潮变化。”',
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isExpanded ? Icons.expand_less : Icons.expand_more,
                      ),
                      onPressed: () =>
                          setState(() => _isExpanded = !_isExpanded),
                    ),
                  ),
                  onSubmitted: (_) => _handleSubmit(),
                ),
              ),
              const SizedBox(width: 12),
              CultivationInteractions.combined(
                child: ElevatedButton(
                  onPressed: canSubmit ? _handleSubmit : null,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    child: state.isSubmitting
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CultivationLoadingIndicators.cultivation(
                              size: 20.0,
                              color: Colors.white,
                              duration: const Duration(milliseconds: 1500),
                            ),
                          )
                        : const Text('提交'),
                  ),
                ),
                enableRipple: canSubmit,
                enableScale: canSubmit,
                enableGlow: canSubmit,
                rippleColor: const Color(0xFF5C6BC0),
                glowColor: const Color(0xFF5C6BC0),
              ),
            ],
          ),
          if (!widget.isSocketReady)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text(
                '实时通道未就绪，暂不可提交指令。',
                style: TextStyle(color: Color(0xFFF6C147)),
              ),
            ),
          const SizedBox(height: 12),
          // 删除快捷指令区块
          // 根据需求：移除“指令历史”展示与再提交入口，仅保留当前会话输入与事件编年史。
        ],
      ),
    );
  }

  Future<void> _handleSubmit() async {
    final text = _controller.text.trim();
    if (text.isEmpty) {
      return;
    }
    final success = await widget.onSubmit(text);
    if (success) {
      _controller.clear();
      setState(() {});
    }
  }

  // 删除再次提交与快捷指令辅助方法
}

// 删除快捷指令组件 _QuickCommandChip




