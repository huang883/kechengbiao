import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/app_controller.dart';
import '../../shared/ui.dart';
import 'pomodoro_controller.dart';
import 'focus_pages.dart';

class PomodoroPage extends ConsumerWidget {
  const PomodoroPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timer = ref.watch(appProvider).pomodoro;
    return ListenableBuilder(
      listenable: timer,
      builder: (context, _) => ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          if (timer.focusBridge != null)
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) =>
                          FocusStatisticsPage(bridge: timer.focusBridge!),
                    ),
                  ),
                  icon: const Icon(Icons.bar_chart),
                  label: const Text('专注统计'),
                ),
                TextButton.icon(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) =>
                          FocusWhitelistPage(bridge: timer.focusBridge!),
                    ),
                  ),
                  icon: const Icon(Icons.apps),
                  label: const Text('白名单'),
                ),
              ],
            ),
          const Text('一次只专注一件事。', style: TextStyle(color: Colors.black54)),
          if (timer.focusBridge != null) ...[
            const SizedBox(height: 8),
            Text(
              '本月剩余提前退出机会：${timer.exitsRemaining}/2 次',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              timer.restricted
                  ? '应用限制已开启 · 暂停期间限制继续'
                  : timer.focusReady
                  ? '应用限制已就绪，开始专注时自动开启'
                  : '开始专注前需授权应用限制',
              style: const TextStyle(color: Colors.black54),
            ),
          ],
          const SizedBox(height: 20),
          SegmentedButton<FocusPhase>(
            segments: const [
              ButtonSegment(value: FocusPhase.focus, label: Text('专注')),
              ButtonSegment(value: FocusPhase.shortBreak, label: Text('短休息')),
              ButtonSegment(value: FocusPhase.longBreak, label: Text('长休息')),
            ],
            selected: {timer.phase},
            onSelectionChanged: timer.busy || timer.restricted
                ? null
                : (s) async {
                    if (s.single == timer.phase) return;
                    if (await _confirm(
                          context,
                          timer,
                          '切换阶段？',
                          '当前阶段的计时将重置。',
                        ) &&
                        context.mounted) {
                      await action(context, () => timer.select(s.single));
                    }
                  },
          ),
          const SizedBox(height: 24),
          Center(
            child: LayoutBuilder(
              builder: (context, box) {
                final size = math.min(260.0, box.maxWidth);
                return SizedBox(
                  width: size,
                  height: size,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox.expand(
                        child: CircularProgressIndicator(
                          value: timer.progress,
                          strokeWidth: 10,
                          backgroundColor: const Color(0xFFE2EAE4),
                          color: timer.phase == FocusPhase.focus
                              ? const Color(0xFFC97055)
                              : mint,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(28),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              timer.phaseTitle,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            FittedBox(
                              child: Text(
                                timer.display,
                                style: const TextStyle(
                                  fontSize: 56,
                                  fontWeight: FontWeight.w700,
                                  fontFeatures: [FontFeature.tabularFigures()],
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              timer.running
                                  ? '计时中'
                                  : timer.progress > 0
                                  ? '已暂停'
                                  : '准备开始',
                              style: const TextStyle(color: Colors.black54),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 22),
          Center(
            child: Text(
              '每完成 ${timer.longEvery} 次专注，进入长休息 · 本轮 ${timer.rounds % timer.longEvery}/${timer.longEvery}',
              style: const TextStyle(color: Colors.black54),
            ),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: timer.busy
                ? null
                : () async {
                    if (timer.running) {
                      await action(context, timer.pause);
                    } else {
                      await startProtectedFocus(context, timer);
                    }
                  },
            icon: Icon(timer.running ? Icons.pause : Icons.play_arrow),
            label: Text(
              timer.running
                  ? '暂停'
                  : timer.progress > 0
                  ? '继续'
                  : '开始${timer.phaseTitle}',
            ),
          ),
          if (timer.restricted) ...[
            TextButton(
              onPressed: timer.busy
                  ? null
                  : () => showFocusExit(context, timer),
              child: const Text('提前退出'),
            ),
            TextButton(
              onPressed: () async {
                final yes = await showDialog<bool>(
                  context: context,
                  builder: (c) => AlertDialog(
                    title: const Text('安全解除限制'),
                    content: const Text(
                      '遇到紧急情况或限制异常时，可立即解除。会记为中断，不计正常完成，也不消耗普通退出次数。',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(c, false),
                        child: const Text('继续专注'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(c, true),
                        child: const Text('解除限制'),
                      ),
                    ],
                  ),
                );
                if (yes == true && context.mounted) {
                  await action(context, () => timer.focusAction('safetyExit'));
                }
              },
              child: const Text('安全解除限制'),
            ),
          ],
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton.icon(
                onPressed: timer.busy || timer.restricted
                    ? null
                    : () async {
                        if (await _confirm(
                              context,
                              timer,
                              '重置计时？',
                              '本阶段重新计时，不计入已完成专注。',
                            ) &&
                            context.mounted) {
                          await action(context, timer.reset);
                        }
                      },
                icon: const Icon(Icons.replay),
                label: const Text('重置'),
              ),
              const SizedBox(width: 16),
              TextButton.icon(
                onPressed: timer.busy || timer.restricted
                    ? null
                    : () async {
                        if (await _confirm(
                              context,
                              timer,
                              '跳过本阶段？',
                              '未完成的专注不计入统计，下一阶段等待你开始。',
                            ) &&
                            context.mounted) {
                          await action(context, timer.skip);
                        }
                      },
                icon: const Icon(Icons.skip_next),
                label: const Text('下一阶段'),
              ),
            ],
          ),
          if (timer.completion != null) InfoCard(timer.completion!),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _stat('今日完成', '${timer.today[0]} 次')),
              const SizedBox(width: 12),
              Expanded(child: _stat('今日专注', '${timer.today[1]} 分钟')),
            ],
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: const Icon(Icons.tune),
              title: const Text('时长与循环'),
              subtitle: Text(
                '专注 ${timer.focusMinutes} 分钟 · 短休 ${timer.shortMinutes} · 长休 ${timer.longMinutes}',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: timer.busy || timer.restricted
                  ? null
                  : () async {
                      if (await _confirm(
                            context,
                            timer,
                            '修改时长？',
                            '修改后当前阶段将重新计时，已完成统计保留。',
                          ) &&
                          context.mounted) {
                        await showDialog<void>(
                          context: context,
                          builder: (_) => _Durations(timer: timer),
                        );
                      }
                    },
            ),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('阶段结束提醒'),
            subtitle: const Text('专注或休息结束后提醒，下一阶段手动开始'),
            value: timer.reminders,
            onChanged: timer.busy
                ? null
                : (v) => action(context, () => timer.setReminders(v)),
          ),
          if (timer.warning != null) InfoCard(timer.warning!),
          if (timer.reminders)
            TextButton(
              onPressed: () => action(context, timer.requestExact),
              child: const Text('开启精确提醒'),
            ),
          const Text(
            '专注限制需要系统辅助功能持续运行。进程被终止、权限撤销或系统运行空档会记为中断；可随时在系统设置中关闭服务。',
            style: TextStyle(fontSize: 12, color: Colors.black54),
          ),
        ],
      ),
    );
  }

  Widget _stat(String label, String value) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.black54)),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    ),
  );
  Future<bool> _confirm(
    BuildContext context,
    PomodoroController timer,
    String title,
    String body,
  ) async {
    if (!timer.running && timer.progress == 0) return true;
    return await showDialog<bool>(
          context: context,
          builder: (c) => AlertDialog(
            title: Text(title),
            content: Text(body),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(c, false),
                child: const Text('取消'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(c, true),
                child: const Text('确定'),
              ),
            ],
          ),
        ) ??
        false;
  }
}

class _Durations extends StatefulWidget {
  final PomodoroController timer;
  const _Durations({required this.timer});
  @override
  State<_Durations> createState() => _DurationsState();
}

class _DurationsState extends State<_Durations> {
  late final fields = [
    for (final n in [
      widget.timer.focusMinutes,
      widget.timer.shortMinutes,
      widget.timer.longMinutes,
      widget.timer.longEvery,
    ])
      TextEditingController(text: '$n'),
  ];
  bool saving = false;
  @override
  void dispose() {
    for (final f in fields) {
      f.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('时长与循环'),
    content: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < 4; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: TextField(
                controller: fields[i],
                keyboardType: TextInputType.number,
                enabled: !saving,
                decoration: InputDecoration(
                  labelText: [
                    '专注分钟（1—180）',
                    '短休息分钟（1—60）',
                    '长休息分钟（1—60）',
                    '长休息间隔次数（2—12）',
                  ][i],
                ),
              ),
            ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: saving ? null : () => Navigator.pop(context),
        child: const Text('取消'),
      ),
      FilledButton(
        onPressed: saving
            ? null
            : () async {
                setState(() => saving = true);
                try {
                  final v = fields
                      .map((c) => int.tryParse(c.text.trim()) ?? 0)
                      .toList();
                  await widget.timer.configure(v[0], v[1], v[2], v[3]);
                  if (context.mounted) Navigator.pop(context);
                } catch (e) {
                  if (context.mounted) message(context, friendlyError(e));
                } finally {
                  if (mounted) setState(() => saving = false);
                }
              },
        child: const Text('保存设置'),
      ),
    ],
  );
}
