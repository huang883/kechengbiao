import '../../shared/untimed_task_tile.dart';

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:schedule_core/schedule_core.dart';

import '../../application/app_controller.dart';
import '../../shared/ui.dart';
import 'course_editor.dart';
import '../../shared/timetable_selector.dart';
import '../tasks/tasks_page.dart';
import '../settings/replacement_settings.dart';

class SchedulePage extends ConsumerWidget {
  const SchedulePage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final app = ref.watch(appProvider),
        snapshot = ref.read(appProvider).snapshot;
    if (snapshot == null) {
      return EmptyState(
        icon: Icons.calendar_view_week_outlined,
        title: '你的周课表',
        body: '先导入课程，就能查看每周真正要上的课。',
        button: FilledButton(
          onPressed: () => context.go('/import'),
          child: const Text('导入课表'),
        ),
      );
    }
    final range = SemesterWeekCalculator(snapshot.semester)
        .getDateRangeForWeek(app.selectedWeek);
    final today = DateTime.utc(app.now.year, app.now.month, app.now.day);
    final currentStart = today.subtract(
      Duration(days: (today.weekday - snapshot.semester.weekStartDay + 7) % 7),
    );
    final weekDistance = range.start.difference(currentStart).inDays ~/ 7;
    final relativeWeek = switch (weekDistance) {
      0 => '本周',
      -1 => '上一周',
      1 => '下一周',
      < 0 => '前 ${-weekDistance} 周',
      _ => '后 $weekDistance 周',
    };
    // Re-evaluate week rules on every build/week change, not only the heading.
    final rules = CourseFilterService(
      snapshot.semester,
      snapshot.schedules,
      daysOff: snapshot.daysOff,
      replacements: snapshot.replacements,
      lessonTransfers: snapshot.lessonTransfers,
    ).getCoursesForWeek(app.selectedWeek);
    final dates = [
      for (var day = 0; day < 7; day++) range.start.add(Duration(days: day)),
    ];
    final off = snapshot.daysOff
        .where(
          (d) =>
              !d.date.isBefore(range.start) &&
              !d.date.isAfter(range.end) &&
              !snapshot.replacements.any(
                (r) => dateText(r.targetDate) == dateText(d.date),
              ),
        )
        .toList();
    final replacements = snapshot.replacements
        .where(
          (r) =>
              !r.targetDate.isBefore(range.start) &&
              !r.targetDate.isAfter(range.end),
        )
        .toList();
    final days = dates.map((date) {
      final timeline = app.timeline(date);
      return TimelineResult(
        timeline.items
            .where((i) => i.sourceType != 'task' || !i.completed)
            .toList(),
        timeline.unconfiguredSchedules,
      );
    }).toList();
    final untimed = app.tasks
        .where(
          (t) =>
              !t.hasTime &&
              !t.completed &&
              !t.date.isBefore(range.start) &&
              !t.date.isAfter(range.end),
        )
        .toList();
    final all = days.expand((d) => d.items).toList();
    final missing = days.expand((d) => d.unconfiguredSchedules).toList();
    int minute(String clock) {
      final p = clock.split(':').map(int.parse).toList();
      return p[0] * 60 + p[1];
    }

    final bells = <int, Set<String>>{};
    for (final t in snapshot.classTimes) {
      bells.putIfAbsent(minute(t.startTime), () => {}).add('上');
      bells.putIfAbsent(minute(t.endTime), () => {}).add('下');
    }
    final starts = [
      for (final i in all) i.startDateTime.hour * 60 + i.startDateTime.minute,
      ...bells.keys,
    ];
    final ends = [
      for (final i in all) i.endDateTime.hour * 60 + i.endDateTime.minute,
      ...bells.keys,
    ];
    final firstHour = math.max(
      0,
      starts.isEmpty ? 7 : starts.reduce(math.min) ~/ 60 - 1,
    );
    final lastHour = math.min(
      24,
      ends.isEmpty ? 20 : (ends.reduce(math.max) / 60).ceil() + 1,
    );
    final ticks = <int, String>{
      for (final e in bells.entries) e.key: e.value.join('/'),
    };
    for (var h = firstHour; h <= lastHour; h++) {
      if (!bells.keys.any((m) => (m - h * 60).abs() < 12)) ticks[h * 60] = '';
    }
    final tickMinutes = ticks.keys.toList()..sort();
    const pixelsPerMinute = 1.25;
    final height = (lastHour - firstHour) * 60 * pixelsPerMinute;
    return GestureDetector(
      onHorizontalDragEnd: (d) {
        if ((d.primaryVelocity ?? 0).abs() > 180) {
          app.changeWeek(app.selectedWeek + (d.primaryVelocity! < 0 ? 1 : -1));
        }
      },
      child: Column(
        children: [
          TimetableSelector(app: app),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                IconButton(
                  tooltip: '上一周',
                  onPressed: app.selectedWeek > 1
                      ? () => app.changeWeek(app.selectedWeek - 1)
                      : null,
                  icon: const Icon(Icons.chevron_left),
                ),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        '第 ${app.selectedWeek} 周',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        '${dateText(range.start)} — ${dateText(range.end)}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: '下一周',
                  onPressed: app.selectedWeek < snapshot.semester.totalWeeks
                      ? () => app.changeWeek(app.selectedWeek + 1)
                      : null,
                  icon: const Icon(Icons.chevron_right),
                ),
                Tooltip(
                  message: app.currentWeek == null ? '当前日期不在此学期内' : '回到本周',
                  child: TextButton(
                    onPressed: app.currentWeek == null
                        ? null
                        : () => app.changeWeek(app.currentWeek!),
                    child: Text(relativeWeek),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
            child: Text(
              '${rules.length} 条课程安排 · ${all.where((i) => i.sourceType == 'task').length + untimed.length} 项未完成待办',
              style: const TextStyle(color: Colors.black54, fontSize: 12),
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () => openReplacements(context),
              icon: const Icon(Icons.swap_horiz),
              label: const Text('调课'),
            ),
          ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, box) {
                final cardWidth = math.max(48.0, (box.maxWidth - 40) / 7);
                final dayWidths = [
                  for (final day in days)
                    cardWidth * _lanes(day.items, pixelsPerMinute).count,
                ];
                final offsets = [
                  for (var i = 0; i < 7; i++)
                    dayWidths.take(i).fold<double>(0, (a, b) => a + b),
                ];
                final width = 40 + dayWidths.fold<double>(0, (a, b) => a + b);
                return SingleChildScrollView(
                  key: const ValueKey('week-horizontal-scroll'),
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: width,
                    height: box.maxHeight,
                    child: Column(
                      children: [
                        Row(
                          children: [
                            const SizedBox(width: 40),
                            for (
                              var dayIndex = 0;
                              dayIndex < dates.length;
                              dayIndex++
                            )
                              SizedBox(
                                width: dayWidths[dayIndex],
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color:
                                        dateText(dates[dayIndex]) ==
                                            dateText(app.now)
                                        ? const Color(0xFFDDECE4)
                                        : Colors.white,
                                  ),
                                  child: Column(
                                    children: [
                                      Text(
                                        '周${'一二三四五六日'[dates[dayIndex].weekday - 1]}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Text(
                                        '${dates[dayIndex].month}/${dates[dayIndex].day}',
                                        style: const TextStyle(
                                          fontSize: 10,
                                          color: Colors.black54,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                        Expanded(
                          child: ListView(
                            children: [
                              if (width > box.maxWidth + 1)
                                const Padding(
                                  padding: EdgeInsets.all(8),
                                  child: Text(
                                    '重叠课程和待办并排显示，可左右滑动查看',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.black54,
                                    ),
                                  ),
                                ),
                              if (untimed.isNotEmpty) ...[
                                const Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  child: Text('不指定时间的待办'),
                                ),
                                for (final task in untimed)
                                  UntimedTaskTile(
                                    app: app,
                                    task: task,
                                    showDate: true,
                                  ),
                              ],
                              if (off.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Text(
                                    '停课：${off.map((d) => "${d.date.month}/${d.date.day} ${d.reason}").join("、")}（待办不受影响）',
                                  ),
                                ),
                              for (final t in snapshot.lessonTransfers.where(
                                (t) =>
                                    !t.targetDate.isBefore(range.start) &&
                                    !t.targetDate.isAfter(range.end),
                              ))
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  child: Text(
                                    '${t.targetDate.month}/${t.targetDate.day} ${sectionLabel(t.targetStart, t.targetEnd)}：${lessonTransferLabel(snapshot.semester, t)}',
                                  ),
                                ),
                              for (final r in replacements)
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  child: Text(
                                    '${r.targetDate.month}/${r.targetDate.day}：${replacementLabel(snapshot.semester, r)}',
                                  ),
                                ),
                              SizedBox(
                                height: height + 50,
                                child: Stack(
                                  children: [
                                    Positioned.fill(
                                      child: GestureDetector(
                                        key: const ValueKey(
                                          'course-grid-empty',
                                        ),
                                        behavior: HitTestBehavior.opaque,
                                        onTapUp: (event) {
                                          final x = event.localPosition.dx - 40;
                                          if (x < 0) return;
                                          final day = List.generate(7, (i) => i)
                                              .firstWhere(
                                                (i) =>
                                                    x <
                                                    offsets[i] + dayWidths[i],
                                                orElse: () => 6,
                                              );
                                          if (SemesterWeekCalculator(
                                                snapshot.semester,
                                              ).getWeekForDate(dates[day]) ==
                                              null) {
                                            message(
                                              context,
                                              '该日期不在当前学期内，请选择学期内的日期',
                                            );
                                            return;
                                          }
                                          final minute =
                                              (firstHour * 60 +
                                                      event.localPosition.dy /
                                                          pixelsPerMinute)
                                                  .floor()
                                                  .clamp(0, 1438);
                                          openCourseEditor(
                                            context,
                                            app,
                                            date: dates[day],
                                            minute: minute,
                                          );
                                        },
                                      ),
                                    ),
                                    for (final m in tickMinutes)
                                      Positioned(
                                        top:
                                            (m - firstHour * 60) *
                                            pixelsPerMinute,
                                        left: 0,
                                        right: 0,
                                        child: Row(
                                          children: [
                                            SizedBox(
                                              width: 40,
                                              child: Text(
                                                '${(m ~/ 60).toString().padLeft(2, '0')}:${(m % 60).toString().padLeft(2, '0')}${ticks[m]!.isEmpty ? '' : ' ${ticks[m]}'}',
                                                maxLines: 1,
                                                style: TextStyle(
                                                  fontSize: 8,
                                                  height: 1,
                                                  color: ticks[m]!.contains('下')
                                                      ? const Color(0xFF98623F)
                                                      : Colors.black54,
                                                ),
                                              ),
                                            ),
                                            Expanded(
                                              child: Divider(
                                                height: 1,
                                                color: ticks[m]!.contains('下')
                                                    ? const Color(0xFFE5CDBB)
                                                    : const Color(0xFFE2E6DF),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    for (var day = 0; day < 7; day++)
                                      ..._cards(
                                        context,
                                        app,
                                        days[day].items,
                                        offsets[day],
                                        dayWidths[day],
                                        firstHour,
                                        pixelsPerMinute,
                                      ),
                                  ],
                                ),
                              ),
                              if (missing.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    children: [
                                      InfoCard(
                                        '${missing.length} 条课程缺少上课钟点，暂列在下方。',
                                        onTap: () => context.go('/settings'),
                                      ),
                                      for (final rule in missing)
                                        Card(
                                          child: ListTile(
                                            title: Text(
                                              snapshot.courses
                                                  .singleWhere(
                                                    (c) =>
                                                        c.id == rule.courseId,
                                                  )
                                                  .name,
                                            ),
                                            subtitle: Text(
                                              '周${'一二三四五六日'[rule.weekday - 1]} 第 ${rule.startSection}—${rule.endSection} 节 · ${rule.classroom}',
                                            ),
                                            onTap: () => openCourseEditor(
                                              context,
                                              app,
                                              schedule: rule,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              if (all.isEmpty &&
                                  missing.isEmpty &&
                                  untimed.isEmpty)
                                const Padding(
                                  padding: EdgeInsets.all(24),
                                  child: Text(
                                    '这一周没有课程或待办',
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              const SizedBox(height: 30),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _cards(
    BuildContext context,
    AppController app,
    List<TimelineItem> items,
    double offset,
    double width,
    int first,
    double scale,
  ) {
    final layout = _lanes(items, scale);
    final positions = layout.positions, count = layout.count;
    return [
      for (var i = 0; i < items.length; i++)
        Positioned(
          left: 40 + offset + positions[i] * width / count + 1,
          width: width / count - 2,
          top:
              (items[i].startDateTime.hour * 60 +
                  items[i].startDateTime.minute -
                  first * 60) *
              scale,
          height: math.max(
            items[i].sourceType == 'task' ? 48 : 12,
            items[i].endDateTime.difference(items[i].startDateTime).inMinutes *
                    scale -
                2,
          ),
          child: Material(
            key: ValueKey('week-card-${items[i].id}'),
            color: courseColor(
              items[i].color,
              items[i].title,
            ).withValues(alpha: items[i].completed ? 0.35 : 0.88),
            borderRadius: BorderRadius.circular(7),
            child: InkWell(
              borderRadius: BorderRadius.circular(7),
              onTap: () => items[i].sourceType == 'task'
                  ? openTaskEditor(
                      context,
                      app,
                      app.tasks.singleWhere((t) => t.id == items[i].sourceId),
                    )
                  : openCourseEditor(
                      context,
                      app,
                      schedule:
                          items[i].schedule ??
                          app.snapshot!.schedules.singleWhere(
                            (s) => s.id == items[i].sourceId,
                          ),
                    ),
              child: ClipRect(
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Text(
                    items[i].sourceType == 'task'
                        ? '${clockText(items[i].startDateTime)}\n待办 · ${items[i].title}'
                        : '${items[i].title}\n${clockText(items[i].startDateTime)}—${clockText(items[i].endDateTime)}\n${items[i].subtitle}',
                    overflow: TextOverflow.fade,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      height: 1.25,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
    ];
  }

  ({List<int> positions, int count}) _lanes(
    List<TimelineItem> items,
    double scale,
  ) {
    final lanes = <DateTime>[];
    final positions = <int>[];
    for (final item in items) {
      var lane = lanes.indexWhere((end) => !end.isAfter(item.startDateTime));
      if (lane < 0) {
        lane = lanes.length;
        lanes.add(_visualEnd(item, scale));
      } else {
        lanes[lane] = _visualEnd(item, scale);
      }
      positions.add(lane);
    }
    return (positions: positions, count: math.max(1, lanes.length));
  }

  DateTime _visualEnd(TimelineItem item, double scale) =>
      item.startDateTime.add(
        Duration(
          minutes: math.max(
            item.endDateTime.difference(item.startDateTime).inMinutes,
            item.sourceType == 'task'
                ? (50 / scale).ceil()
                : (14 / scale).ceil(),
          ),
        ),
      );
}
