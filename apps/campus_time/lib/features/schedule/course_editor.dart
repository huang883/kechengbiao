import 'package:flutter/material.dart';
import 'package:schedule_core/schedule_core.dart';

import '../../application/app_controller.dart';
import '../../shared/ui.dart';

Future<void> openCourseEditor(
  BuildContext context,
  AppController app, {
  CourseSchedule? schedule,
  DateTime? date,
  int? minute,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  builder: (_) =>
      CourseEditor(app: app, schedule: schedule, date: date, minute: minute),
);

class CourseEditor extends StatefulWidget {
  final AppController app;
  final CourseSchedule? schedule;
  final DateTime? date;
  final int? minute;
  const CourseEditor({
    super.key,
    required this.app,
    this.schedule,
    this.date,
    this.minute,
  });
  @override
  State<CourseEditor> createState() => _CourseEditorState();
}

class _CourseEditorState extends State<CourseEditor> {
  late final snapshot = widget.app.snapshot!;
  late final CourseSchedule? original = widget.schedule == null
      ? null
      : snapshot.schedules.firstWhere(
          (s) =>
              s.id ==
              (widget.schedule!.originalScheduleId ?? widget.schedule!.id),
        );
  late final LessonTransfer? transfer = snapshot.lessonTransfers
      .where(
        (t) =>
            widget.schedule?.id == 'transfer:${t.id}' ||
            (widget.schedule?.id.startsWith('transfer:${t.id}:') ?? false),
      )
      .firstOrNull;
  bool editingTransfer = false;
  final scopeDrafts = <bool, Map<String, dynamic>>{};
  CourseSchedule? get displayed => editingTransfer ? widget.schedule : original;
  late final Course? course = original == null
      ? null
      : snapshot.courses.firstWhere((c) => c.id == original!.courseId);
  late final name = TextEditingController(text: course?.name ?? '');
  late final room = TextEditingController(text: displayed?.classroom ?? '');
  late int weekday, startSection, endSection;
  late String startTime, endTime;
  late bool custom;
  late Set<int> weeks;
  bool saving = false;
  String? error;
  String clock(int minute) =>
      '${(minute ~/ 60).toString().padLeft(2, '0')}:${(minute % 60).toString().padLeft(2, '0')}';
  int minutes(String time) {
    final p = time.split(':').map(int.parse).toList();
    return p[0] * 60 + p[1];
  }

  @override
  void initState() {
    super.initState();
    loadScope();
  }

  void loadScope() {
    final day = widget.date ?? widget.app.now;
    weekday = displayed?.weekday ?? day.weekday;
    weeks =
        (editingTransfer
            ? {
                SemesterWeekCalculator(snapshot.semester)
                    .getWeekForDate(transfer!.targetDate)!,
              }
            : original?.activeWeeks.toSet()) ??
        {
          SemesterWeekCalculator(snapshot.semester).getWeekForDate(day) ??
              widget.app.selectedWeek,
        };
    final at = (widget.minute ?? 8 * 60).clamp(0, 1438);
    final nearest = snapshot.classTimes
        .where((t) => minutes(t.startTime) <= at && minutes(t.endTime) > at)
        .firstOrNull;
    startSection = displayed?.startSection ?? nearest?.section ?? 1;
    endSection = displayed?.endSection ?? startSection;
    custom = displayed != null
        ? displayed!.customStartTime != null
        : nearest == null;
    final time = displayed == null
        ? null
        : ClassTimeService().getClassTime(displayed!, snapshot.classTimes);
    startTime = time?.start ?? clock(at);
    endTime = time?.end ?? clock((at + 45).clamp(1, 1439));
    if (original == null && !custom) syncTimes();
  }

  void switchScope(bool next) {
    if (next == editingTransfer) return;
    scopeDrafts[editingTransfer] = {
      'room': room.text,
      'weekday': weekday,
      'startSection': startSection,
      'endSection': endSection,
      'startTime': startTime,
      'endTime': endTime,
      'custom': custom,
      'weeks': Set<int>.of(weeks),
    };
    setState(() {
      editingTransfer = next;
      error = null;
      final draft = scopeDrafts[next];
      if (draft == null) {
        loadScope();
        room.text = displayed?.classroom ?? '';
      } else {
        room.text = draft['room'] as String;
        weekday = draft['weekday'] as int;
        startSection = draft['startSection'] as int;
        endSection = draft['endSection'] as int;
        startTime = draft['startTime'] as String;
        endTime = draft['endTime'] as String;
        custom = draft['custom'] as bool;
        weeks = Set<int>.of(draft['weeks'] as Set<int>);
      }
    });
  }

  void syncTimes() {
    startTime =
        snapshot.classTimes
            .where((t) => t.section == startSection)
            .firstOrNull
            ?.startTime ??
        startTime;
    endTime =
        snapshot.classTimes
            .where((t) => t.section == endSection)
            .firstOrNull
            ?.endTime ??
        endTime;
  }

  @override
  void dispose() {
    name.dispose();
    room.dispose();
    super.dispose();
  }

  Future<void> pickTime(bool start) async {
    final value = start ? startTime : endTime;
    final selected = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: minutes(value) ~/ 60,
        minute: minutes(value) % 60,
      ),
      initialEntryMode: TimePickerEntryMode.input,
      builder: (c, child) => MediaQuery(
        data: MediaQuery.of(c).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (selected != null && mounted) {
      setState(() {
        if (start) {
          startTime = clock(selected.hour * 60 + selected.minute);
        } else {
          endTime = clock(selected.hour * 60 + selected.minute);
        }
      });
    }
  }

  Future<void> save() async {
    if (saving) return;
    if (name.text.trim().isEmpty ||
        weeks.isEmpty ||
        startSection > endSection ||
        (custom && startTime.compareTo(endTime) >= 0)) {
      setState(() => error = '请填写课程名称，选择至少一周，并确保结束时间晚于开始时间');
      return;
    }
    setState(() {
      saving = true;
      error = null;
    });
    try {
      final id = 'manual_${DateTime.now().microsecondsSinceEpoch}';
      final c = Course(
        id: course?.id ?? id,
        name: name.text.trim(),
        teacher: course?.teacher ?? '',
        color: course?.color ?? 'default',
        remark: course?.remark ?? '',
      );
      final s = CourseSchedule(
        id: original?.id ?? '${id}_schedule',
        courseId: c.id,
        semesterId: snapshot.semester.id,
        weekday: weekday,
        startSection: startSection,
        endSection: endSection,
        classroom: room.text.trim(),
        activeWeeks: weeks.toList()..sort(),
        remark: original?.remark ?? '',
        customStartTime: custom ? startTime : null,
        customEndTime: custom ? endTime : null,
      );
      if (editingTransfer) {
        final range = SemesterWeekCalculator(snapshot.semester)
            .getDateRangeForWeek(weeks.single);
        final date = range.start.add(
          Duration(days: (weekday - snapshot.semester.weekStartDay + 7) % 7),
        );
        await widget.app.editTransferredCourse(
          snapshot.semester.id,
          transfer!.id,
          c,
          s,
          date,
        );
      } else {
        await widget.app.saveCourse(c, s, creating: original == null);
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() {
          saving = false;
          error = friendlyError(e);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
    child: SizedBox(
      height: MediaQuery.sizeOf(context).height * .88,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 8, 0),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    transfer != null
                        ? (editingTransfer ? '编辑这次调课' : '编辑原排课')
                        : original == null
                        ? '新建课程'
                        : '编辑课程',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                IconButton(
                  tooltip: '关闭课程编辑',
                  onPressed: saving ? null : () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                if (transfer != null) ...[
                  const Text('修改范围'),
                  const SizedBox(height: 8),
                  SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment(value: false, label: Text('修改原排课')),
                      ButtonSegment(value: true, label: Text('只改这次调课')),
                    ],
                    selected: {editingTransfer},
                    onSelectionChanged: saving
                        ? null
                        : (v) => switchScope(v.single),
                  ),
                  const SizedBox(height: 12),
                ],
                if (original != null && transfer == null)
                  const Text(
                    '名称应用于本课表中这门课的所有排课；地点、星期、时间和周次只修改当前这条排课。',
                    style: TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                if (widget.schedule?.adjustmentLabel.isNotEmpty ?? false)
                  Text(
                    '${widget.schedule!.adjustmentLabel}\n${transfer != null ? (editingTransfer ? '只修改这次调课的目标时间和地点，原排课保持不变。' : '修改原排课的时间和周次，保留已调课程的目标时间。') : '正在编辑整天调课引用的来源排课。'}',
                  ),
                TextField(
                  key: const ValueKey('course-name'),
                  controller: name,
                  maxLength: 100,
                  decoration: const InputDecoration(labelText: '课程名称'),
                ),
                TextField(
                  key: const ValueKey('course-room'),
                  controller: room,
                  maxLength: 100,
                  decoration: const InputDecoration(labelText: '上课地点'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  key: ValueKey('weekday-$editingTransfer-$weekday'),
                  initialValue: weekday,
                  decoration: const InputDecoration(labelText: '星期'),
                  items: [
                    for (var i = 1; i <= 7; i++)
                      DropdownMenuItem(
                        value: i,
                        child: Text('星期${'一二三四五六日'[i - 1]}'),
                      ),
                  ],
                  onChanged: saving
                      ? null
                      : (v) => setState(() => weekday = v!),
                ),
                const SizedBox(height: 16),
                SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment(value: false, label: Text('按节次')),
                    ButtonSegment(value: true, label: Text('自定义钟点')),
                  ],
                  selected: {custom},
                  onSelectionChanged: (v) => setState(() {
                    custom = v.single;
                    if (!custom) syncTimes();
                  }),
                ),
                const SizedBox(height: 12),
                if (!custom) ...[
                  for (final isStart in [true, false])
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: DropdownButtonFormField<int>(
                        key: ValueKey(
                          'section-${isStart ? startSection : endSection}-$isStart',
                        ),
                        initialValue: isStart ? startSection : endSection,
                        isExpanded: true,
                        decoration: InputDecoration(
                          labelText: isStart ? '开始节次' : '结束节次',
                        ),
                        items: [
                          for (final n in ({
                            startSection,
                            endSection,
                            ...snapshot.classTimes.map((t) => t.section),
                          }.toList()..sort()))
                            DropdownMenuItem(
                              value: n,
                              child: Text(
                                '第 $n 节  ${snapshot.classTimes.where((t) => t.section == n).map((t) => '${t.startTime}—${t.endTime}').firstOrNull ?? '钟点未配置'}',
                              ),
                            ),
                        ],
                        onChanged: (v) => setState(() {
                          if (isStart) {
                            startSection = v!;
                            if (endSection < startSection) {
                              endSection = startSection;
                            }
                          } else {
                            endSection = v!;
                          }
                          syncTimes();
                        }),
                      ),
                    ),
                  Text('上课时间：$startTime—$endTime'),
                ] else
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => pickTime(true),
                          child: Text('上课 $startTime'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => pickTime(false),
                          child: Text('下课 $endTime'),
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Expanded(child: Text('生效周次')),
                    if (!editingTransfer)
                      TextButton(
                        onPressed: () => setState(
                          () => weeks = {
                            for (
                              var w = 1;
                              w <= snapshot.semester.totalWeeks;
                              w++
                            )
                              w,
                          },
                        ),
                        child: const Text('全选'),
                      ),
                    TextButton(
                      onPressed: () =>
                          setState(() => weeks = {widget.app.selectedWeek}),
                      child: const Text('仅当前周'),
                    ),
                  ],
                ),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    for (var w = 1; w <= snapshot.semester.totalWeeks; w++)
                      FilterChip(
                        label: Text('$w'),
                        selected: weeks.contains(w),
                        onSelected: (v) => setState(() {
                          if (editingTransfer) {
                            weeks = {w};
                            return;
                          }
                          if (v) {
                            weeks.add(w);
                          } else {
                            weeks.remove(w);
                          }
                        }),
                      ),
                  ],
                ),
                const Text(
                  '节假日停课与已保存的调课规则仍然生效。',
                  style: TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (error != null)
                  Text(
                    error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: saving ? null : save,
                    child: Text(saving ? '正在保存…' : '保存课程'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
