import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:schedule_core/schedule_core.dart';

import '../../application/app_controller.dart';
import '../../shared/ui.dart';
import 'replacement_settings.dart';

DateTime readSchoolDate(String value) {
  final text = value.trim();
  final date = DateTime.tryParse('${text}T00:00:00Z');
  if (date == null || dateText(date) != text) {
    throw const FormatException('请输入有效日期 YYYY-MM-DD');
  }
  return date;
}

class CalendarSettings extends StatelessWidget {
  final AppController app;
  const CalendarSettings({super.key, required this.app});
  @override
  Widget build(BuildContext context) {
    final snapshot = app.snapshot!, s = snapshot.semester;
    return Column(
      children: [
        ReplacementSettings(app: app),
        Card(
          child: ListTile(
            title: const Text('周起始与第一周'),
            subtitle: Text(
              '星期${'一二三四五六日'[s.weekStartDay - 1]}起算 · 起点 ${dateText(s.startDate)}',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => showDialog<void>(
              context: context,
              builder: (_) => _CalendarEditor(app: app),
            ),
          ),
        ),
        Card(
          child: ListTile(
            title: const Text('节假日停课'),
            subtitle: Text('已设置 ${snapshot.daysOff.length} 天 · 不影响个人待办'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => showModalBottomSheet<void>(
              context: context,
              isScrollControlled: true,
              useSafeArea: true,
              builder: (_) => const _DaysOffSheet(),
            ),
          ),
        ),
      ],
    );
  }
}

class _CalendarEditor extends StatefulWidget {
  final AppController app;
  const _CalendarEditor({required this.app});
  @override
  State<_CalendarEditor> createState() => _CalendarEditorState();
}

class _CalendarEditorState extends State<_CalendarEditor> {
  late int weekday;
  late final TextEditingController start;
  bool saving = false;
  @override
  void initState() {
    super.initState();
    final s = widget.app.snapshot!.semester;
    weekday = s.weekStartDay;
    start = TextEditingController(
      text: dateText(SemesterWeekCalculator(s).getDateRangeForWeek(1).start),
    );
  }

  @override
  void dispose() {
    start.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('周起始与第一周'),
    content: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('按学校实际教学周填写。第一周起始日期必须是所选星期；保存后会重置手动周次校正。'),
          const SizedBox(height: 16),
          DropdownButtonFormField<int>(
            initialValue: weekday,
            decoration: const InputDecoration(labelText: '每周第一天'),
            items: [
              for (var d = 1; d <= 7; d++)
                DropdownMenuItem(
                  value: d,
                  child: Text('星期${'一二三四五六日'[d - 1]}'),
                ),
            ],
            onChanged: saving
                ? null
                : (value) {
                    if (value == null) return;
                    setState(() {
                      try {
                        final date = readSchoolDate(start.text);
                        start.text = dateText(
                          date.add(
                            Duration(days: (value - date.weekday + 7) % 7),
                          ),
                        );
                      } on FormatException {
                        /* Keep invalid input visible for correction. */
                      }
                      weekday = value;
                    });
                  },
          ),
          const SizedBox(height: 16),
          TextField(
            controller: start,
            enabled: !saving,
            decoration: const InputDecoration(
              labelText: '第一周起始日期',
              hintText: 'YYYY-MM-DD',
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
                  await widget.app.saveCalendar(
                    readSchoolDate(start.text),
                    weekday,
                  );
                  if (context.mounted) Navigator.pop(context);
                } catch (e) {
                  if (context.mounted) message(context, friendlyError(e));
                } finally {
                  if (mounted) setState(() => saving = false);
                }
              },
        child: const Text('保存学期周设置'),
      ),
    ],
  );
}

class _DaysOffSheet extends ConsumerWidget {
  const _DaysOffSheet();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final app = ref.watch(appProvider), snapshot = app.snapshot!;
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * .85,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text('节假日停课', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 12),
          const Text(
            '所列日期的课程、课程冲突和课程提醒暂停，个人待办照常。只按学校确认的日期添加；连休需逐日添加；当天若设有调课覆盖，以调入课程为准。',
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () => showDialog<void>(
              context: context,
              builder: (_) => _DayOffEditor(app: app),
            ),
            icon: const Icon(Icons.add),
            label: const Text('添加停课日期'),
          ),
          if (snapshot.daysOff.isEmpty)
            const Padding(padding: EdgeInsets.all(24), child: Text('尚未设置停课日期')),
          for (final day in snapshot.daysOff)
            Card(
              child: ListTile(
                title: Text('${dateText(day.date)} · ${day.reason}'),
                onTap: () => showDialog<void>(
                  context: context,
                  builder: (_) => _DayOffEditor(app: app, existing: day),
                ),
                trailing: IconButton(
                  tooltip: '删除 ${dateText(day.date)}',
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (c) => AlertDialog(
                        title: const Text('恢复当天课程？'),
                        content: Text(
                          '删除 ${dateText(day.date)} 的停课设置，课程将按原课表显示。',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(c, false),
                            child: const Text('取消'),
                          ),
                          FilledButton(
                            onPressed: () => Navigator.pop(c, true),
                            child: const Text('恢复课程'),
                          ),
                        ],
                      ),
                    );
                    if (confirmed == true && context.mounted) {
                      await action(context, () => app.removeDayOff(day.date));
                    }
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _DayOffEditor extends StatefulWidget {
  final AppController app;
  final ClassDayOff? existing;
  const _DayOffEditor({required this.app, this.existing});
  @override
  State<_DayOffEditor> createState() => _DayOffEditorState();
}

class _DayOffEditorState extends State<_DayOffEditor> {
  late final TextEditingController date, reason;
  bool saving = false;
  @override
  void initState() {
    super.initState();
    final s = widget.app.snapshot!.semester;
    final now = DateTime.utc(
      widget.app.now.year,
      widget.app.now.month,
      widget.app.now.day,
    );
    final initial =
        widget.existing?.date ??
        (now.isBefore(s.startDate) || now.isAfter(s.endDate)
            ? s.startDate
            : now);
    date = TextEditingController(text: dateText(initial));
    reason = TextEditingController(text: widget.existing?.reason ?? '学校停课');
  }

  @override
  void dispose() {
    date.dispose();
    reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.existing == null ? '添加停课日期' : '修改停课说明'),
    content: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: date,
            enabled: !saving && widget.existing == null,
            decoration: const InputDecoration(labelText: '停课日期 YYYY-MM-DD'),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: reason,
            enabled: !saving,
            decoration: const InputDecoration(labelText: '停课说明'),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [
              for (final name in ['中秋节', '国庆节', '元旦', '学校停课'])
                ActionChip(
                  label: Text(name),
                  onPressed: saving ? null : () => reason.text = name,
                ),
            ],
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
                  await widget.app.saveDayOff(
                    ClassDayOff(
                      date: readSchoolDate(date.text),
                      reason: reason.text,
                    ),
                  );
                  if (context.mounted) Navigator.pop(context);
                } catch (e) {
                  if (context.mounted) message(context, friendlyError(e));
                } finally {
                  if (mounted) setState(() => saving = false);
                }
              },
        child: const Text('保存停课日期'),
      ),
    ],
  );
}
