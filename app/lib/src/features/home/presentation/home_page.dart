import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:ling_yan_tian_ji/src/features/common/data/mock_data.dart';
import 'package:ling_yan_tian_ji/src/features/common/models/game_entities.dart';
import 'package:ling_yan_tian_ji/src/features/home/application/command_center_controller.dart';
import 'package:ling_yan_tian_ji/src/features/home/application/live_updates_controller.dart';
import 'package:ling_yan_tian_ji/src/features/home/application/log_filter_controller.dart';
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
    final logsState = ref.watch(filteredLogsProvider);
    final availableTags = ref.watch(availableLogTagsProvider);
    final activeFilters = ref.watch(logFilterProvider);
    final commandState = ref.watch(homeCommandControllerProvider);
    final liveState = ref.watch(homeLiveUpdatesProvider);

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
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _DialogueHeader(
              status: liveState.valueOrNull?.status ??
                  liveState.when(
                    data: (value) => value.status,
                    loading: () => HomeSocketStatus.connecting,
                    error: (_, __) => HomeSocketStatus.disconnected,
                  ),
              lastEvent: liveState.valueOrNull?.lastEvent,
              disconnectReason: liveState.valueOrNull?.disconnectReason,
            ),
            const SizedBox(height: 12),
            if (availableTags.isNotEmpty) ...[
              _LogFilterBar(
                tags: availableTags,
                activeFilters: activeFilters,
                onToggle: (tag) =>
                    ref.read(logFilterProvider.notifier).toggleTag(tag),
                onClear: () => ref.read(logFilterProvider.notifier).clear(),
              ),
              const SizedBox(height: 8),
            ],
                        Expanded(
              child: _LogsSection(
                logsState: logsState,
                onRetry: () async {
                  await ref.read(chronicleLogsProvider.notifier).refresh();
                },
                isLoading: commandState.isSubmitting,
              ),
            ),
            const SizedBox(height: 12),
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


class _DialogueHeader extends StatelessWidget {
  const _DialogueHeader({
    required this.status,
    required this.lastEvent,
    this.disconnectReason,
  });

  final HomeSocketStatus status;
  final LiveUpdateEvent? lastEvent;
  final String? disconnectReason;

  String get _statusLabel {
    switch (status) {
      case HomeSocketStatus.connected:
        return '天机连线：已接通';
      case HomeSocketStatus.connecting:
        return '天机连线：初始化中';
      case HomeSocketStatus.disconnected:
        return '天机连线：已断开';
    }
  }

  Color get _statusColor {
    switch (status) {
      case HomeSocketStatus.connected:
        return const Color(0xFF26A69A);
      case HomeSocketStatus.connecting:
        return const Color(0xFFF6C147);
      case HomeSocketStatus.disconnected:
        return const Color(0xFFE57373);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final latest = lastEvent;
    final summary =
        latest?.summary ?? '尚无最新回响，向天机提出你的第一个问题吧。';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: _statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _statusColor.withValues(alpha: 0.4)),
                  ),
                  child: Text(
                    _statusLabel,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: _statusColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    latest?.title ?? '天机灵筏已就绪',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              summary,
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
            if (status == HomeSocketStatus.disconnected &&
                disconnectReason != null) ...[
              const SizedBox(height: 10),
              Text(
                '提示：$disconnectReason',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: const Color(0xFFE57373)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

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
        onRetry: () async {
          ref.invalidate(playerProfileProvider);
          await ref.read(playerProfileProvider.future);
        },
      ),
    );
  }
}

class _LogsSection extends StatelessWidget {
  const _LogsSection({
    required this.logsState,
    required this.onRetry,
    required this.isLoading,
  });

  final AsyncValue<List<ChronicleLog>> logsState;
  final Future<void> Function() onRetry;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return logsState.when(
      data: (logs) => _NarrativeFeed(
        logs: logs,
        isLoading: isLoading,
      ),
      loading: () => const _LoadingPane(message: '正在同步事件流…'),
      error: (error, _) => _ErrorPane(
        message: '事件流暂不可用',
        detail: error.toString(),
        onRetry: onRetry,
      ),
    );
  }
}

class _NarrativeFeed extends StatelessWidget {
  const _NarrativeFeed({
    required this.logs,
    required this.isLoading,
  });

  final List<ChronicleLog> logs;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    if (logs.isEmpty) {
      return const _EmptyState(message: '暂无天机回响，尝试发起新的询问。');
    }

    final itemCount = logs.length + (isLoading ? 1 : 0);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: ListView.builder(
          reverse: true,
          padding: const EdgeInsets.only(bottom: 4),
          physics: const BouncingScrollPhysics(),
          itemCount: itemCount,
          itemBuilder: (context, index) {
            if (isLoading && index == 0) {
              return const _DialogueTypingIndicator();
            }
            final logIndex = isLoading ? index - 1 : index;
            final log = logs[logIndex];
            return Padding(
              padding:
                  EdgeInsets.only(bottom: logIndex == logs.length - 1 ? 0 : 14),
              child: _DialogueBubble(log: log),
            );
          },
        ),
      ),
    );
  }
}

class _DialogueBubble extends StatelessWidget {
  const _DialogueBubble({required this.log});

  final ChronicleLog log;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final timeLabel = _historyTimestampFormat.format(log.timestamp.toLocal());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.auto_awesome, color: Color(0xFF5C6BC0), size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                log.title,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              timeLabel,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        DecoratedBox(
          decoration: BoxDecoration(
            color: const Color(0x1A5C6BC0),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              log.summary,
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
            ),
          ),
        ),
        if (log.tags.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: log.tags
                .map(
                  (tag) => Chip(
                    label: Text('#$tag'),
                    visualDensity: VisualDensity.compact,
                    backgroundColor: const Color(0x1426A69A),
                  ),
                )
                .toList(),
          ),
        ],
      ],
    );
  }
}

class _DialogueTypingIndicator extends StatelessWidget {
  const _DialogueTypingIndicator();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2.2),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '天机推演中……',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ),
        ],
      ),
    );
  }
}



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
  });

  final String message;
  final String detail;
  final Future<void> Function() onRetry;

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
                icon: const Icon(Icons.refresh),
                label: const Text('重试'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LogFilterBar extends StatelessWidget {
  const _LogFilterBar({
    required this.tags,
    required this.activeFilters,
    required this.onToggle,
    required this.onClear,
  });

  final List<String> tags;
  final Set<String> activeFilters;
  final ValueChanged<String> onToggle;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    if (tags.isEmpty) {
      return const SizedBox.shrink();
    }
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        const Text('事件筛选：', style: TextStyle(fontWeight: FontWeight.w600)),
        ...tags.map((tag) {
          final selected = activeFilters.contains(tag);
          return FilterChip(
            label: Text(tag),
            selected: selected,
            onSelected: (_) => onToggle(tag),
            selectedColor: const Color(0x6626A69A),
          );
        }),
        if (activeFilters.isNotEmpty)
          TextButton.icon(
            onPressed: onClear,
            icon: const Icon(Icons.refresh),
            label: const Text('重置筛选'),
          ),
      ],
    );
  }
}

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
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              CultivationInteractions.spiritRipple(
                child: _QuickCommandChip(
                  label: '秘境状况',
                  enabled: canSubmit,
                  onTap: () =>
                      _applyQuickCommand('查询丹霞秘境当前灵潮强度。'),
                ),
                rippleColor: const Color(0xFF26A69A),
              ),
              CultivationInteractions.spiritRipple(
                child: _QuickCommandChip(
                  label: '飞升进展',
                  enabled: canSubmit,
                  onTap: () =>
                      _applyQuickCommand('汇报飞升试炼排队情况。'),
                ),
                rippleColor: const Color(0xFF5C6BC0),
              ),
              CultivationInteractions.spiritRipple(
                child: _QuickCommandChip(
                  label: '灵仆状态',
                  enabled: canSubmit,
                  onTap: () =>
                      _applyQuickCommand('询问紫曜灵仆·沐瑶的疲劳与心情。'),
                ),
                rippleColor: const Color(0xFFE91E63),
              ),
              CultivationInteractions.spiritRipple(
                child: _QuickCommandChip(
                  label: '功法调整',
                  enabled: canSubmit,
                  onTap: () =>
                      _applyQuickCommand('分析玄霜裂空剑与紫微星阙大阵的协同策略。'),
                ),
                rippleColor: const Color(0xFFFFD54F),
              ),
              CultivationInteractions.hoverGlow(
                child: _QuickCommandChip(
                  label: '事件日志',
                  enabled: true,
                  // 修复无法返回主页：使用 push 保留返回栈
                  onTap: () => context.push('/chronicles'),
                ),
                glowColor: const Color(0xFF9C27B0),
              ),
            ],
          ),
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

  Future<void> _handleResubmit(String text) async {
    _controller
      ..text = text
      ..selection = TextSelection.fromPosition(
        TextPosition(offset: text.length),
      );
    await _handleSubmit();
  }

  void _applyQuickCommand(String text) {
    _controller
      ..text = text
      ..selection = TextSelection.fromPosition(
        TextPosition(offset: text.length),
      );
    if (!_isExpanded) {
      setState(() => _isExpanded = true);
    }
    _focusNode.requestFocus();
  }
}

class _QuickCommandChip extends StatelessWidget {
  const _QuickCommandChip({
    required this.label,
    required this.onTap,
    required this.enabled,
  });

  final String label;
  final VoidCallback onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text(label),
      onPressed: enabled ? onTap : null,
      backgroundColor: const Color(0x3326A69A),
      labelStyle: const TextStyle(fontWeight: FontWeight.w600),
    );
  }
}




