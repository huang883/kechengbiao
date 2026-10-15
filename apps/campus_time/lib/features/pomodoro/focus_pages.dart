import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../shared/ui.dart';
import 'focus_bridge.dart';
import 'focus_stats.dart';
import 'pomodoro_controller.dart';

Future<void> startProtectedFocus(
  BuildContext context,
  PomodoroController timer,
) async {
  if (timer.focusBridge == null ||
      timer.phase != FocusPhase.focus ||
      timer.restricted) {
    await action(context, timer.start);
    return;
  }
  await timer.refreshFocus();
  if (!context.mounted) return;
  if (!timer.focusReady || timer.focusStatus['consent'] != true) {
    final accept = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('开启专注应用限制'),
        content: const SingleChildScrollView(
          child: Text(
            '开始专注后，课间会使用辅助功能检测切换到的应用包名，并遮挡非白名单应用。'
            '不读取屏幕内容、输入文字或通讯录，应用列表和专注记录只保存在本机，不上传。\n\n'
            '请先设置白名单。课间、电话、系统设置等必要功能始终允许使用。暂停计时仍保留限制。'
            '普通提前退出每月2次，每次确认需等待5秒；安全退出和撤销权限始终可用。\n\n'
            '这不是系统锁屏。系统省电或权限变化可能使专注中断。'
            '同意后请在系统辅助功能中开启“课间专注限制”，返回后再次点击开始。',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('暂不开启'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('同意并前往授权'),
          ),
        ],
      ),
    );
    if (accept == true && context.mounted) {
      await action(context, () async {
        await timer.focusBridge!.call('consent');
        await timer.focusBridge!.call('settings');
      });
    }
    return;
  }
  if (context.mounted) await action(context, timer.start);
}

Future<void> showFocusExit(
  BuildContext context,
  PomodoroController timer,
) async {
  await timer.refreshFocus();
  if (!context.mounted || !timer.restricted) return;
  await showDialog<void>(
    context: context,
    builder: (_) => FocusExitDialog(timer: timer),
  );
}

class FocusExitDialog extends StatefulWidget {
  final PomodoroController timer;

  /// Injectable monotonic clock for widget regression tests.
  final int Function()? elapsedMilliseconds;
  const FocusExitDialog({
    super.key,
    required this.timer,
    this.elapsedMilliseconds,
  });
  @override
  State<FocusExitDialog> createState() => _FocusExitDialogState();
}

class _FocusExitDialogState extends State<FocusExitDialog> {
  final watch = Stopwatch();
  Timer? ticker;
  String? token, error;
  bool submitting = false;
  int get elapsed =>
      widget.elapsedMilliseconds?.call() ?? watch.elapsedMilliseconds;
  int get seconds => math.max(0, ((5000 - elapsed) / 1000).ceil());
  @override
  void initState() {
    super.initState();
    if (widget.timer.exitsRemaining > 0) unawaited(arm());
  }

  Future<void> arm() async {
    try {
      final value = await widget.timer.focusBridge!.call('armExit') as String;
      if (!mounted) {
        await widget.timer.focusBridge!.call('cancelExit', {'token': value});
        return;
      }
      token = value;
      watch.start();
      ticker = Timer.periodic(const Duration(milliseconds: 100), (_) {
        if (mounted) setState(() {});
      });
      setState(() {});
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    }
  }

  @override
  void dispose() {
    ticker?.cancel();
    watch.stop();
    if (token != null) {
      unawaited(
        widget.timer.focusBridge!
            .call('cancelExit', {'token': token})
            .catchError((Object _) => null),
      );
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final remaining = widget.timer.exitsRemaining;
    if (remaining == 0) {
      return AlertDialog(
        title: const Text('本月提前退出机会已用完'),
        content: const Text(
          '本月剩余次数：0/2 次\n\n你已经使用了本月全部 2 次普通提前退出机会。\n请继续完成本次专注。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('返回专注'),
          ),
        ],
      );
    }
    return AlertDialog(
      title: const Text('确定提前退出本次专注吗？'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('你正在进行专注计时。'),
          const SizedBox(height: 16),
          Text(
            '本月剩余次数：$remaining/2 次',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
          ),
          const SizedBox(height: 16),
          const Text('提前退出将消耗 1 次机会，并结束当前专注。'),
          if (error != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('继续专注'),
        ),
        FilledButton(
          onPressed: token == null || seconds > 0 || submitting
              ? null
              : () async {
                  setState(() => submitting = true);
                  try {
                    await widget.timer.focusBridge!.call('confirmExit', {
                      'token': token,
                    });
                    await widget.timer.refreshFocus();
                    if (context.mounted) Navigator.pop(context);
                  } catch (e) {
                    if (mounted) {
                      setState(() {
                        error = e.toString();
                        submitting = false;
                      });
                    }
                  }
                },
          child: Text(
            submitting
                ? '正在退出…'
                : seconds > 0 || token == null
                ? '确认退出（${token == null ? 5 : seconds}s）'
                : '确认退出',
          ),
        ),
      ],
    );
  }
}

class FocusWhitelistPage extends StatefulWidget {
  final FocusBridge bridge;
  const FocusWhitelistPage({super.key, required this.bridge});
  @override
  State<FocusWhitelistPage> createState() => _FocusWhitelistPageState();
}

class _FocusWhitelistPageState extends State<FocusWhitelistPage> {
  List<Map> apps = [];
  Set<String> selected = {};
  String query = '';
  String? error;
  bool loading = true, saving = false, locked = false;
  @override
  void initState() {
    super.initState();
    unawaited(load());
  }

  Future<void> load() async {
    try {
      final status = await widget.bridge.status();
      final data = await widget.bridge.call('apps') as List;
      if (mounted) {
        setState(() {
          apps = data.cast<Map>();
          selected = apps
              .where((a) => a['selected'] == true)
              .map((a) => a['package'] as String)
              .toSet();
          locked = status['active'] != null;
          loading = false;
          error = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          error = e.toString();
          loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('应用白名单'),
      actions: [
        TextButton(
          onPressed: loading || saving || locked
              ? null
              : () async {
                  setState(() => saving = true);
                  try {
                    await widget.bridge.call('whitelist', {
                      'packages': selected.toList(),
                    });
                    if (context.mounted) Navigator.pop(context);
                  } catch (e) {
                    if (mounted) setState(() => error = e.toString());
                  } finally {
                    if (mounted) setState(() => saving = false);
                  }
                },
          child: Text(saving ? '保存中…' : '保存'),
        ),
      ],
    ),
    body: Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '已选择 ${selected.length} 个应用',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              const Text('电话、课间、桌面和必要系统功能始终允许使用。仅列出有启动入口的应用，卸载记录会自动清理。'),
              if (locked) const InfoCard('专注期间白名单保持不变，结束后可修改。'),
              const SizedBox(height: 12),
              TextField(
                onChanged: (v) => setState(() => query = v.toLowerCase()),
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  hintText: '搜索应用名称或包名',
                ),
              ),
              if (error != null) InfoCard(error!),
            ],
          ),
        ),
        if (loading)
          const CircularProgressIndicator()
        else
          Expanded(
            child: ListView(
              children: [
                for (final app in apps.where(
                  (a) => '${a['name']} ${a['package']}'.toLowerCase().contains(
                    query,
                  ),
                ))
                  CheckboxListTile(
                    value: selected.contains(app['package']),
                    onChanged: locked || saving || app['mandatory'] == true
                        ? null
                        : (v) => setState(() {
                            if (v == true) {
                              selected.add(app['package'] as String);
                            } else {
                              selected.remove(app['package']);
                            }
                          }),
                    secondary: app['icon'] is Uint8List
                        ? Image.memory(
                            app['icon'] as Uint8List,
                            width: 40,
                            height: 40,
                          )
                        : const Icon(Icons.apps),
                    title: Text(app['name'] as String),
                    subtitle: Text(
                      app['mandatory'] == true
                          ? '系统必要功能 · 始终允许'
                          : app['package'] as String,
                    ),
                  ),
                if (apps.isEmpty)
                  TextButton(onPressed: load, child: const Text('重新读取应用列表')),
              ],
            ),
          ),
      ],
    ),
  );
}

class FocusStatisticsPage extends StatefulWidget {
  final FocusBridge bridge;
  const FocusStatisticsPage({super.key, required this.bridge});
  @override
  State<FocusStatisticsPage> createState() => _FocusStatisticsPageState();
}

class _FocusStatisticsPageState extends State<FocusStatisticsPage> {
  Map? data;
  String? error;
  FocusRange range = FocusRange.week;
  int? selected;
  @override
  void initState() {
    super.initState();
    unawaited(load());
  }

  Future<void> load() async {
    try {
      final result = await widget.bridge.call('history') as Map;
      if (mounted) {
        setState(() {
          data = result;
          error = null;
        });
      }
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final stats = data == null
        ? null
        : FocusStatistics(data!, range, DateTime.now());
    final records =
        stats?.records(selected == null ? null : stats.buckets[selected!]) ??
        [];
    return Scaffold(
      appBar: AppBar(
        title: const Text('专注统计'),
        actions: [
          IconButton(
            onPressed: load,
            icon: const Icon(Icons.refresh),
            tooltip: '刷新',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          SegmentedButton<FocusRange>(
            segments: [
              for (final r in FocusRange.values)
                ButtonSegment(
                  value: r,
                  label: Text(['本周', '本月', '本年', '近5年'][r.index]),
                ),
            ],
            selected: {range},
            onSelectionChanged: (s) => setState(() {
              range = s.single;
              selected = null;
            }),
          ),
          const SizedBox(height: 16),
          if (error != null) InfoCard(error!),
          if (stats == null && error == null)
            const Center(child: CircularProgressIndicator()),
          if (stats != null) ...[
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                metric('已完成次数', '${stats.completedCount} 次'),
                metric('已完成总时长', focusDuration(stats.completedMs)),
                metric('实际计时时长', focusDuration(stats.timerMs)),
                metric('有效限制时长', focusDuration(stats.restrictedMs)),
                metric('提前退出', '${stats.earlyCount} 次'),
                metric('中断', '${stats.interruptedCount} 次'),
                metric('平均完成时长', focusDuration(stats.averageMs)),
              ],
            ),
            const SizedBox(height: 20),
            const Text(
              '正常完成专注时长',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Text(
              '点击柱状图查看对应记录 · 单位：分钟',
              style: TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, box) {
                final width = math.max(
                  box.maxWidth,
                  stats.buckets.length * 36.0,
                );
                final maxMs = math.max(
                  60000,
                  stats.buckets.fold<int>(
                    0,
                    (m, b) => math.max(m, b.completedMs),
                  ),
                );
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: width,
                    height: 190,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        for (var i = 0; i < stats.buckets.length; i++)
                          Expanded(
                            child: Semantics(
                              button: true,
                              label:
                                  '${stats.buckets[i].label}，${focusDuration(stats.buckets[i].completedMs)}',
                              child: InkWell(
                                onTap: () => setState(
                                  () => selected = selected == i ? null : i,
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Text(
                                      (stats.buckets[i].completedMs / 60000)
                                          .toStringAsFixed(1),
                                      style: const TextStyle(fontSize: 10),
                                    ),
                                    const SizedBox(height: 4),
                                    Container(
                                      width: 22,
                                      height: math.max(
                                        3,
                                        140 *
                                            stats.buckets[i].completedMs /
                                            maxMs,
                                      ),
                                      decoration: BoxDecoration(
                                        color: selected == i
                                            ? const Color(0xFFC97055)
                                            : mint,
                                        borderRadius: BorderRadius.circular(5),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      stats.buckets[i].label,
                                      style: const TextStyle(fontSize: 11),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            const Text(
              '时长按当前时区的实际区间拆分；次数按结束日期归属。平均值按本范围内结束的完整已完成会话计算。有效限制时长包含暂停期间。旧版汇总不补造限制记录。',
              style: TextStyle(fontSize: 12, color: Colors.black54),
            ),
            Row(
              children: [
                Expanded(
                  child: Text(
                    selected == null
                        ? '历史记录'
                        : '${stats.buckets[selected!].label} · 历史记录',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (selected != null)
                  TextButton(
                    onPressed: () => setState(() => selected = null),
                    child: const Text('显示全部'),
                  ),
              ],
            ),
            if (records.isEmpty) const InfoCard('这个时间范围还没有专注记录。'),
            for (final record in records)
              Card(
                child: ExpansionTile(
                  title: Text(focusReason(record['state'] as String)),
                  subtitle: Text(
                    '${stamp(record['started'])} · ${focusDuration(record['timer_ms'] as num)}',
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          '开始：${stamp(record['started'])}\n结束：${stamp(record['ended'])}\n'
                          '计划时长：${focusDuration(record['planned'] as num)}\n实际计时：${focusDuration(record['timer_ms'] as num)}\n'
                          '有效限制：${focusDuration(record['restricted_ms'] as num)}\n'
                          '正常完成：${record['state'] == 'completed' ? '是' : '否'}\n消耗退出机会：${record['consumed'] == 1 ? '是' : '否'}',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget metric(String label, String value) => SizedBox(
    width: 155,
    child: Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: Colors.black54)),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
            ),
          ],
        ),
      ),
    ),
  );
  String stamp(dynamic value) => value == null
      ? '尚未结束'
      : DateTime.fromMillisecondsSinceEpoch((value as num).toInt())
            .toString()
            .split('.')
            .first;
}
