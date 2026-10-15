import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:schedule_core/schedule_core.dart';

import '../../application/app_controller.dart';
import '../../shared/ui.dart';
import '../../shared/course_color_picker.dart';
import '../../shared/default_class_times.dart';
import 'calendar_settings.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final app = ref.watch(appProvider),
        snapshot = ref.read(appProvider).snapshot;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      children: [
        const SectionTitle('学期与作息'),
        if (snapshot == null)
          InfoCard('导入课表后，可配置学期与上课时间。', onTap: () => context.go('/import')),
        if (snapshot != null) ...[
          DropdownButtonFormField<String>(
            key: ValueKey(snapshot.semester.id),
            initialValue: snapshot.semester.id,
            isExpanded: true,
            decoration: const InputDecoration(labelText: '当前学期'),
            items: [
              for (final s in app.semesters)
                DropdownMenuItem(
                  value: s.id,
                  child: Text(s.name, overflow: TextOverflow.ellipsis),
                ),
            ],
            onChanged: (id) => action(context, () => app.selectSemester(id!)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              '${dateText(snapshot.semester.startDate)} 至 ${dateText(snapshot.semester.endDate)} · ${snapshot.semester.totalWeeks} 周',
              style: const TextStyle(color: Colors.black54, fontSize: 12),
            ),
          ),
          CalendarSettings(app: app),
          Card(
            child: ListTile(
              title: const Text('校正当前教学周'),
              subtitle: Text(
                app.currentWeek == null
                    ? '今天不在这个学期内'
                    : '当前第 ${app.currentWeek} 周',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () async {
                final controller = TextEditingController(
                  text: app.currentWeek?.toString() ?? '',
                );
                final value = await showDialog<int>(
                  context: context,
                  builder: (c) => AlertDialog(
                    title: const Text('今天是第几周？'),
                    content: TextField(
                      controller: controller,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: '教学周'),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(c),
                        child: const Text('取消'),
                      ),
                      FilledButton(
                        onPressed: () =>
                            Navigator.pop(c, int.tryParse(controller.text)),
                        child: const Text('保存'),
                      ),
                    ],
                  ),
                );
                Future<void>.delayed(
                  const Duration(seconds: 1),
                  controller.dispose,
                );
                if (value != null && context.mounted) {
                  await action(context, () => app.calibrateWeek(value));
                }
              },
            ),
          ),
          Card(
            child: ListTile(
              title: const Text('学校上课时间'),
              subtitle: Text('已配置 ${snapshot.classTimes.length} 节 · 点击填写实际钟点'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => showModalBottomSheet<void>(
                context: context,
                isScrollControlled: true,
                useSafeArea: true,
                builder: (_) => ClassTimesEditor(app: app),
              ),
            ),
          ),
          const SectionTitle('课程颜色'),
          for (final course in snapshot.courses)
            Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: courseColor(course.color, course.name),
                  radius: 10,
                ),
                title: Text(course.name),
                onTap: () async {
                  final color = await showDialog<String>(
                    context: context,
                    builder: (c) => CourseColorPicker(
                      name: course.name,
                      initial: courseColor(course.color, course.name),
                    ),
                  );
                  if (color != null && context.mounted) {
                    await action(
                      context,
                      () => app.saveColor(course.id, color),
                    );
                  }
                },
              ),
            ),
        ],
        const SectionTitle('本地提醒'),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('课程与待办提醒'),
          subtitle: const Text('课程提前 10 分钟；待办按单项设置'),
          value: app.reminderEnabled,
          onChanged: (v) => action(context, () => app.enableReminders(v)),
        ),
        const Text(
          '每次打开 App 或修改日程时更新未来 7 天提醒。时间按北京时间安排；系统省电策略可能延迟通知。',
          style: TextStyle(color: Colors.black54, fontSize: 12, height: 1.6),
        ),
        if (app.notificationWarning != null) InfoCard(app.notificationWarning!),
        const SectionTitle('关于课间'),
        const Text(
          '0.1.14 · 课表与待办保存在本机\n卸载应用会删除本机数据。',
          style: TextStyle(height: 1.7, color: Colors.black54),
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('开源许可'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => showLicensePage(
            context: context,
            applicationName: '课间',
            applicationVersion: '0.1.14',
          ),
        ),
      ],
    );
  }
}

class ClassTimesEditor extends StatefulWidget {
  final AppController app;
  const ClassTimesEditor({super.key, required this.app});
  @override
  State<ClassTimesEditor> createState() => _ClassTimesEditorState();
}

class _ClassTimesEditorState extends State<ClassTimesEditor> {
  late final List<(TextEditingController, TextEditingController)> rows;
  bool saving = false;
  @override
  void initState() {
    super.initState();
    final s = widget.app.snapshot!;
    final count = s.schedules.fold<int>(
      11,
      (max, s) => s.endSection > max ? s.endSection : max,
    );
    rows = List.generate(count, (i) {
      final configured = s.classTimes.isEmpty
          ? defaultClassTimes(s.semester.id)
          : s.classTimes;
      final t = configured.where((t) => t.section == i + 1).firstOrNull;
      return (
        TextEditingController(text: t?.startTime ?? ''),
        TextEditingController(text: t?.endTime ?? ''),
      );
    });
  }

  @override
  void dispose() {
    for (final row in rows) {
      row.$1.dispose();
      row.$2.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
    child: SizedBox(
      height: MediaQuery.sizeOf(context).height * .85,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text('学校上课时间', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 12),
          const Text(
            '默认采用海南师范大学校历的 11 节作息，可逐项修改。点击保存作息后生效；整行留空表示未知。',
            style: TextStyle(color: Colors.black54, height: 1.6),
          ),
          TextButton.icon(
            onPressed: saving
                ? null
                : () {
                    setState(() {
                      for (final t in defaultClassTimes(
                        widget.app.snapshot!.semester.id,
                      )) {
                        rows[t.section - 1].$1.text = t.startTime;
                        rows[t.section - 1].$2.text = t.endTime;
                      }
                    });
                  },
            icon: const Icon(Icons.schedule),
            label: const Text('填入默认 11 节作息'),
          ),
          const SizedBox(height: 20),
          for (var i = 0; i < rows.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                children: [
                  SizedBox(width: 50, child: Text('第 ${i + 1} 节')),
                  Expanded(
                    child: TextField(
                      controller: rows[i].$1,
                      keyboardType: TextInputType.datetime,
                      decoration: const InputDecoration(
                        labelText: '开始',
                        hintText: 'HH:mm',
                      ),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Text('—'),
                  ),
                  Expanded(
                    child: TextField(
                      controller: rows[i].$2,
                      keyboardType: TextInputType.datetime,
                      decoration: const InputDecoration(
                        labelText: '结束',
                        hintText: 'HH:mm',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          FilledButton(
            onPressed: saving
                ? null
                : () async {
                    setState(() => saving = true);
                    try {
                      final times = <ClassTimeConfig>[];
                      for (var i = 0; i < rows.length; i++) {
                        final start = rows[i].$1.text.trim(),
                            end = rows[i].$2.text.trim();
                        if (start.isEmpty && end.isEmpty) continue;
                        times.add(
                          ClassTimeConfig(
                            semesterId: widget.app.snapshot!.semester.id,
                            section: i + 1,
                            startTime: start,
                            endTime: end,
                          ),
                        );
                      }
                      await widget.app.saveTimes(times);
                      if (context.mounted) Navigator.pop(context);
                    } catch (e) {
                      if (context.mounted) message(context, friendlyError(e));
                    } finally {
                      if (mounted) setState(() => saving = false);
                    }
                  },
            child: const Text('保存作息'),
          ),
        ],
      ),
    ),
  );
}
