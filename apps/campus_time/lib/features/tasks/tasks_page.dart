import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:schedule_core/schedule_core.dart';

import '../../application/app_controller.dart';
import '../../shared/ui.dart';

Future<void> openTaskEditor(
  BuildContext context,
  AppController app, [
  TaskEvent? task,
]) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  builder: (_) => TaskEditor(app: app, task: task),
);

class TasksPage extends ConsumerStatefulWidget {
  const TasksPage({super.key});
  @override
  ConsumerState<TasksPage> createState() => _TasksPageState();
}

class _TasksPageState extends ConsumerState<TasksPage> {
  String filter = '今天';
  @override
  Widget build(BuildContext context) {
    final app = ref.watch(appProvider),
        today = DateTime.utc(
          ref.read(appProvider).now.year,
          ref.read(appProvider).now.month,
          ref.read(appProvider).now.day,
        );
    final monday = today.subtract(Duration(days: today.weekday - 1));
    final items = app.tasks
        .where(
          (t) => switch (filter) {
            '今天' => dateText(t.date) == dateText(today),
            '本周' =>
              !t.date.isBefore(monday) &&
                  t.date.isBefore(monday.add(const Duration(days: 7))),
            '已完成' => t.completed,
            _ => true,
          },
        )
        .toList();
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
      children: [
        const Text('给重要的事，留一点时间。', style: TextStyle(color: Colors.black54)),
        const SizedBox(height: 20),
        Wrap(
          spacing: 8,
          children: [
            for (final name in ['今天', '本周', '全部', '已完成'])
              ChoiceChip(
                label: Text(name),
                selected: filter == name,
                onSelected: (_) => setState(() => filter = name),
              ),
          ],
        ),
        SectionTitle(
          '${items.length} 项待办',
          trailing: TextButton.icon(
            onPressed: () => openTaskEditor(context, app),
            icon: const Icon(Icons.add),
            label: const Text('新增'),
          ),
        ),
        if (items.isEmpty)
          const EmptyState(
            icon: Icons.check_circle_outline,
            title: '这里暂时没有待办',
            body: '复习、运动或约定，都可以按任意时间安排。',
          ),
        for (final task in items)
          Card(
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 6,
              ),
              leading: Checkbox(
                value: task.completed,
                onChanged: (v) =>
                    action(context, () => app.completeTask(task.id, v!)),
              ),
              title: Text(
                task.title,
                style: TextStyle(
                  decoration: task.completed
                      ? TextDecoration.lineThrough
                      : null,
                ),
              ),
              subtitle: Text(
                '${dateText(task.date)}\n${task.hasTime ? '${task.startTime} — ${task.endTime}' : '不指定时间'}',
              ),
              isThreeLine: true,
              trailing: IconButton(
                icon: const Icon(Icons.edit_outlined),
                tooltip: '编辑待办',
                onPressed: () => openTaskEditor(context, app, task),
              ),
              onTap: () => openTaskEditor(context, app, task),
            ),
          ),
      ],
    );
  }
}

class TaskEditor extends StatefulWidget {
  final AppController app;
  final TaskEvent? task;
  const TaskEditor({super.key, required this.app, this.task});
  @override
  State<TaskEditor> createState() => _TaskEditorState();
}

class _TaskEditorState extends State<TaskEditor> {
  late final TextEditingController title, start, end, note;
  late DateTime date;
  late final String id;
  int? reminder;
  bool saving = false;
  late bool hasTime;
  @override
  void initState() {
    super.initState();
    final t = widget.task;
    hasTime = t?.hasTime ?? true;
    title = TextEditingController(text: t?.title);
    start = TextEditingController(text: t?.startTime);
    end = TextEditingController(text: t?.endTime);
    note = TextEditingController(text: t?.description);
    date =
        t?.date ??
        DateTime.utc(
          widget.app.now.year,
          widget.app.now.month,
          widget.app.now.day,
        );
    id = t?.id ?? DateTime.now().microsecondsSinceEpoch.toString();
    reminder = t?.reminderMinutes;
  }

  @override
  void dispose() {
    for (final c in [title, start, end, note]) {
      c.dispose();
    }
    super.dispose();
  }

  TaskEvent value() => TaskEvent(
    id: id,
    title: title.text.trim(),
    date: date,
    startTime: hasTime ? start.text.trim() : null,
    endTime: hasTime ? end.text.trim() : null,
    description: note.text.trim(),
    completed: widget.task?.completed ?? false,
    reminderMinutes: hasTime ? reminder : null,
  );
  Future<void> chooseTime(TextEditingController c) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(widget.app.now),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (picked != null && mounted) {
      setState(
        () => c.text =
            '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    List<TimelineItem> conflicts = [];
    try {
      conflicts = widget.app.conflicts(value());
    } catch (_) {
      /* Incomplete form. */
    }
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * .82,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(
              widget.task == null ? '新建待办' : '编辑待办',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 24),
            TextField(
              controller: title,
              decoration: const InputDecoration(
                labelText: '做什么',
                hintText: '例如：概率论复习',
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              icon: const Icon(Icons.calendar_today_outlined),
              label: Text(dayLabel(date)),
              onPressed: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: date,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2100),
                );
                if (picked != null && mounted) {
                  setState(
                    () => date = DateTime.utc(
                      picked.year,
                      picked.month,
                      picked.day,
                    ),
                  );
                }
              },
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('指定时间'),
              subtitle: const Text('关闭后仅安排日期，不占用时间轴'),
              value: hasTime,
              onChanged: (value) => setState(() {
                hasTime = value;
                if (!value) reminder = null;
              }),
            ),
            if (hasTime)
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: start,
                      keyboardType: TextInputType.datetime,
                      decoration: InputDecoration(
                        labelText: '开始 HH:mm',
                        hintText: '10:17',
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.schedule),
                          onPressed: () => chooseTime(start),
                        ),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: end,
                      keyboardType: TextInputType.datetime,
                      decoration: InputDecoration(
                        labelText: '结束 HH:mm',
                        hintText: '11:35',
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.schedule),
                          onPressed: () => chooseTime(end),
                        ),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 16),
            TextField(
              controller: note,
              maxLines: 2,
              decoration: const InputDecoration(labelText: '备注（选填）'),
            ),
            const SizedBox(height: 16),
            if (!hasTime)
              const Text(
                '不指定时间的待办不发送定时提醒，可随时补充时间。',
                style: TextStyle(color: Colors.black54, fontSize: 12),
              ),
            if (hasTime)
              DropdownButtonFormField<int>(
                initialValue: reminder ?? -1,
                decoration: const InputDecoration(labelText: '提前提醒'),
                items: [
                  for (final n in [-1, 0, 5, 10, 15, 30, 60])
                    DropdownMenuItem(
                      value: n,
                      child: Text(
                        n < 0
                            ? '不提醒'
                            : n == 0
                            ? '开始时'
                            : '提前 $n 分钟',
                      ),
                    ),
                ],
                onChanged: (n) => setState(() => reminder = n! < 0 ? null : n),
              ),
            if (hasTime && !widget.app.reminderEnabled && reminder != null)
              const Padding(
                padding: EdgeInsets.only(top: 10),
                child: Text(
                  '请到设置中开启通知权限与提醒。',
                  style: TextStyle(color: Colors.black54),
                ),
              ),
            if (conflicts.isNotEmpty)
              InfoCard(
                '与 ${conflicts.map((i) => i.title).join('、')} 时间冲突。你仍然可以保存。',
              ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: saving
                  ? null
                  : () async {
                      setState(() => saving = true);
                      try {
                        await widget.app.saveTask(
                          value(),
                          editing: widget.task != null,
                        );
                        if (context.mounted) Navigator.pop(context);
                      } catch (e) {
                        if (context.mounted) message(context, friendlyError(e));
                      } finally {
                        if (mounted) setState(() => saving = false);
                      }
                    },
              icon: const Icon(Icons.check),
              label: Text(saving ? '保存中…' : '保存待办'),
            ),
            if (widget.task != null)
              TextButton(
                onPressed: saving
                    ? null
                    : () async {
                        final yes = await showDialog<bool>(
                          context: context,
                          builder: (c) => AlertDialog(
                            title: const Text('删除这项待办？'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(c, false),
                                child: const Text('取消'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(c, true),
                                child: const Text('删除'),
                              ),
                            ],
                          ),
                        );
                        if (yes == true && context.mounted) {
                          await action(context, () async {
                            await widget.app.deleteTask(id);
                            if (context.mounted) Navigator.pop(context);
                          });
                        }
                      },
                child: const Text('删除待办', style: TextStyle(color: Colors.red)),
              ),
          ],
        ),
      ),
    );
  }
}
