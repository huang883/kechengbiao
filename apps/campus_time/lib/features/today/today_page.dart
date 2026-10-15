import '../../shared/untimed_task_tile.dart';
import '../schedule/course_editor.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:schedule_core/schedule_core.dart';

import '../../application/app_controller.dart';
import '../../shared/ui.dart';
import '../tasks/tasks_page.dart';

class TodayPage extends ConsumerWidget {
  const TodayPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final app = ref.watch(appProvider), now = ref.read(appProvider).now;
    final timeline = app.timeline(now);
    final off = app.snapshot?.daysOff
        .where((d) => dateText(d.date) == dateText(now))
        .firstOrNull;
    final classes = timeline.items
        .where((i) => i.sourceType == 'course')
        .toList();
    final active = classes
        .where(
          (i) => !now.isBefore(i.startDateTime) && now.isBefore(i.endDateTime),
        )
        .toList();
    final next = classes.where((i) => i.startDateTime.isAfter(now)).firstOrNull;
    final focus = active.firstOrNull ?? next;
    final pending = app.tasks
        .where((t) => dateText(t.date) == dateText(now) && !t.completed)
        .length;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 100),
      children: [
        Text(dayLabel(now), style: const TextStyle(color: Colors.black54)),
        const SizedBox(height: 8),
        Text(
          app.currentWeek == null ? '把今天安排好' : '第 ${app.currentWeek} 教学周',
          style: Theme.of(context).textTheme.headlineMedium
              ?.copyWith(fontWeight: FontWeight.w800, color: ink),
        ),
        const SizedBox(height: 20),
        if (app.snapshot == null)
          EmptyState(
            icon: Icons.auto_stories_outlined,
            title: '从一份课表开始',
            body: '导入学校 PDF，检查课程后确认保存。\n待办也可以独立使用。',
            button: FilledButton.icon(
              onPressed: () => context.go('/import'),
              icon: const Icon(Icons.upload_file),
              label: const Text('导入我的课表'),
            ),
          )
        else
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: ink,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  active.isNotEmpty
                      ? '正在上课'
                      : next != null
                      ? '下一节课程'
                      : '今天的节奏',
                  style: const TextStyle(color: Color(0xFFB9DCCE)),
                ),
                const SizedBox(height: 12),
                Text(
                  focus?.title ??
                      (timeline.unconfiguredSchedules.isNotEmpty
                          ? '先补充上课时间'
                          : '暂无后续课程'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 23,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  focus == null
                      ? '给学习与生活留一点空间。'
                      : '${clockText(focus.startDateTime)} — ${clockText(focus.endDateTime)}\n${focus.subtitle}',
                  style: const TextStyle(color: Colors.white70, height: 1.7),
                ),
              ],
            ),
          ),
        if (off != null &&
            !(app.snapshot?.replacements.any(
                  (r) => dateText(r.targetDate) == dateText(now),
                ) ??
                false))
          InfoCard('${off.reason}：常规课程停课，单节调入课程和个人待办照常。'),
        for (final r in app.snapshot?.replacements ?? <ClassDayReplacement>[])
          if (dateText(r.targetDate) == dateText(now))
            InfoCard(replacementLabel(app.snapshot!.semester, r)),
        if (timeline.unconfiguredSchedules.isNotEmpty)
          InfoCard(
            '今天有 ${timeline.unconfiguredSchedules.length} 条课程缺少上课钟点，设置后即可显示时间轴。',
            onTap: () => context.go('/settings'),
          ),
        if (app.notificationWarning != null) InfoCard(app.notificationWarning!),
        Row(
          children: [
            Expanded(
              child: _count(
                '${classes.where((i) => i.endDateTime.isAfter(now)).length}',
                '剩余课程',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(child: _count('$pending', '待完成事项')),
          ],
        ),
        if (app.tasks.any(
          (t) => !t.hasTime && dateText(t.date) == dateText(now),
        )) ...[
          const SectionTitle('不指定时间的待办'),
          for (final task in app.tasks.where(
            (t) => !t.hasTime && dateText(t.date) == dateText(now),
          ))
            UntimedTaskTile(app: app, task: task),
        ],
        SectionTitle(
          '今日时间轴',
          trailing: TextButton.icon(
            onPressed: () => openTaskEditor(context, app),
            icon: const Icon(Icons.add),
            label: const Text('待办'),
          ),
        ),
        if (timeline.items.isEmpty)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('暂无已配置时间的安排。', style: TextStyle(color: Colors.black54)),
          ),
        for (final item in timeline.items)
          Card(
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 10,
              ),
              leading: Container(
                width: 4,
                height: 46,
                color: courseColor(item.color, item.title),
              ),
              title: Text(
                item.title,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  decoration: item.completed
                      ? TextDecoration.lineThrough
                      : null,
                ),
              ),
              subtitle: Text(
                '${clockText(item.startDateTime)} — ${clockText(item.endDateTime)}\n${item.subtitle}',
              ),
              trailing: item.sourceType == 'task'
                  ? Checkbox(
                      value: item.completed,
                      onChanged: (v) => action(
                        context,
                        () => app.completeTask(item.sourceId, v!),
                      ),
                    )
                  : const Icon(Icons.school_outlined, color: Colors.black38),
              onTap: item.sourceType == 'task'
                  ? () => openTaskEditor(
                      context,
                      app,
                      app.tasks.singleWhere((t) => t.id == item.sourceId),
                    )
                  : () => openCourseEditor(
                      context,
                      app,
                      schedule:
                          item.schedule ??
                          app.snapshot!.schedules.singleWhere(
                            (s) => s.id == item.sourceId,
                          ),
                    ),
            ),
          ),
        if (timeline.unconfiguredSchedules.isNotEmpty) ...[
          const SectionTitle('待配置时间的课程'),
          for (final s in timeline.unconfiguredSchedules)
            Card(
              child: ListTile(
                onTap: () => openCourseEditor(context, app, schedule: s),
                title: Text(
                  app.snapshot!.courses
                      .singleWhere((c) => c.id == s.courseId)
                      .name,
                ),
                subtitle: Text(
                  '第 ${s.startSection}—${s.endSection} 节 · ${s.classroom}',
                ),
              ),
            ),
        ],
      ],
    );
  }

  Widget _count(String count, String label) => Container(
    margin: const EdgeInsets.only(top: 16),
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
    ),
    child: Row(
      children: [
        Text(
          count,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: mint,
          ),
        ),
        const SizedBox(width: 12),
        Text(label, style: const TextStyle(color: Colors.black54)),
      ],
    ),
  );
}
