import 'package:flutter/material.dart';
import 'package:schedule_core/schedule_core.dart';

import '../../application/app_controller.dart';
import '../../shared/ui.dart';
import 'calendar_settings.dart' show readSchoolDate;

Future<void> openLessonTransfer(
  BuildContext context,
  AppController app, {
  LessonTransfer? existing,
}) => showDialog<void>(
  context: context,
  builder: (_) => _Editor(app: app, existing: existing),
);

class LessonTransferCards extends StatelessWidget {
  final AppController app;
  const LessonTransferCards({super.key, required this.app});
  @override
  Widget build(BuildContext context) => Column(
    children: [
      for (final t in app.snapshot!.lessonTransfers)
        Card(
          child: ListTile(
            title: Text(
              '${app.snapshot!.courses.singleWhere((c) => c.id == app.snapshot!.schedules.singleWhere((s) => s.id == t.scheduleId).courseId).name}\n${dateText(t.targetDate)} ${sectionLabel(t.targetStart, t.targetEnd)}',
            ),
            subtitle: Text(
              '${lessonTransferLabel(app.snapshot!.semester, t)}\n${t.keepSource ? '原课保留' : '原课所选节次已移走'}',
            ),
            onTap: () => openLessonTransfer(context, app, existing: t),
            trailing: IconButton(
              tooltip: '撤销单节调课',
              icon: const Icon(Icons.undo),
              onPressed: () async {
                final yes = await showDialog<bool>(
                  context: context,
                  builder: (c) => AlertDialog(
                    title: const Text('撤销单节调课？'),
                    content: const Text('恢复来源和目标原有的课程安排，保留其他调课与停课设置。'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(c, false),
                        child: const Text('取消'),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.pop(c, true),
                        child: const Text('确认撤销'),
                      ),
                    ],
                  ),
                );
                if (yes == true && context.mounted) {
                  await action(context, () => app.removeLessonTransfer(t.id));
                }
              },
            ),
          ),
        ),
    ],
  );
}

class _Editor extends StatefulWidget {
  final AppController app;
  final LessonTransfer? existing;
  const _Editor({required this.app, this.existing});
  @override
  State<_Editor> createState() => _EditorState();
}

class _EditorState extends State<_Editor> {
  late final TextEditingController source, target;
  String? scheduleId;
  int first = 1, last = 1, destination = 1;
  bool keep = false, saving = false;
  SemesterSnapshot get snapshot => widget.app.snapshot!;
  List<CourseSchedule> get rules {
    try {
      return CourseFilterService(
        snapshot.semester,
        snapshot.schedules,
      ).getCoursesForDate(readSchoolDate(source.text));
    } on FormatException {
      return [];
    }
  }

  CourseSchedule? get selected =>
      rules.where((s) => s.id == scheduleId).firstOrNull;
  String dateLabel(String value) {
    try {
      final d = readSchoolDate(value),
          w = SemesterWeekCalculator(snapshot.semester).getWeekForDate(d);
      return w == null ? '日期不在当前学期内' : '第 $w 周星期${'一二三四五六日'[d.weekday - 1]}';
    } on FormatException {
      return '请输入有效日期';
    }
  }

  @override
  void initState() {
    super.initState();
    final t = widget.existing;
    final day =
        SemesterWeekCalculator(snapshot.semester)
                .getWeekForDate(widget.app.now) ==
            null
        ? snapshot.semester.startDate
        : widget.app.now;
    source = TextEditingController(text: dateText(t?.sourceDate ?? day));
    target = TextEditingController(text: dateText(t?.targetDate ?? day));
    if (t != null) {
      scheduleId = t.scheduleId;
      first = t.sourceStart;
      last = t.sourceEnd;
      destination = t.targetStart;
      keep = t.keepSource;
    } else {
      choose(rules.firstOrNull);
    }
  }

  void choose(CourseSchedule? s) {
    scheduleId = s?.id;
    first = s?.startSection ?? 1;
    last = s?.endSection ?? 1;
    destination = first;
  }

  @override
  void dispose() {
    source.dispose();
    target.dispose();
    super.dispose();
  }

  Future<void> pick(TextEditingController field) async {
    var date = snapshot.semester.startDate;
    try {
      date = readSchoolDate(field.text);
    } on FormatException {
      /* Picker opens inside semester. */
    }
    if (date.isBefore(snapshot.semester.startDate) ||
        date.isAfter(snapshot.semester.endDate)) {
      date = snapshot.semester.startDate;
    }
    final d = await showDatePicker(
      context: context,
      initialDate: date,
      firstDate: snapshot.semester.startDate,
      lastDate: snapshot.semester.endDate,
    );
    if (d != null && mounted) {
      setState(() {
        field.text = dateText(d);
        if (field == source) choose(rules.firstOrNull);
      });
    }
  }

  Widget dateField(TextEditingController field, String title) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      TextField(
        controller: field,
        enabled: !saving,
        onChanged: (_) => setState(() {
          if (field == source) choose(rules.firstOrNull);
        }),
        decoration: InputDecoration(
          labelText: title,
          hintText: 'YYYY-MM-DD',
          suffixIcon: IconButton(
            tooltip: '选择$title',
            onPressed: saving ? null : () => pick(field),
            icon: const Icon(Icons.calendar_month),
          ),
        ),
      ),
      Text(
        dateLabel(field.text),
        style: const TextStyle(color: Colors.black54),
      ),
      const SizedBox(height: 12),
    ],
  );
  Widget section(
    String title,
    int value,
    List<int> options,
    ValueChanged<int> change,
  ) => DropdownButtonFormField<int>(
    key: ValueKey('$title:$value:${options.join(',')}'),
    initialValue: options.contains(value) ? value : null,
    isExpanded: true,
    decoration: InputDecoration(labelText: title),
    items: [
      for (final n in options)
        DropdownMenuItem(value: n, child: Text('第 $n 节')),
    ],
    onChanged: saving
        ? null
        : (n) {
            if (n != null) setState(() => change(n));
          },
  );
  @override
  Widget build(BuildContext context) {
    final rule = selected;
    final sections = snapshot.classTimes.map((s) => s.section).toList()..sort();
    return AlertDialog(
      title: Text(widget.existing == null ? '单节调课' : '修改单节调课'),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('选择原课表中的课程，可只调其中一节。目标原有课程保留，停课日也可单独安排调入课程。'),
              const SizedBox(height: 16),
              dateField(source, '来源日期'),
              if (rules.isEmpty) const Text('来源当天原课表没有课程，请选择其他日期。'),
              if (rules.isNotEmpty)
                DropdownButtonFormField<String>(
                  key: ValueKey('course:${source.text}:$scheduleId'),
                  initialValue: scheduleId,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: '来源课程'),
                  items: [
                    for (final s in rules)
                      DropdownMenuItem(
                        value: s.id,
                        child: Text(
                          '${snapshot.courses.singleWhere((c) => c.id == s.courseId).name} · ${sectionLabel(s.startSection, s.endSection)}',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                  onChanged: saving
                      ? null
                      : (id) => setState(
                          () => choose(rules.singleWhere((s) => s.id == id)),
                        ),
                ),
              if (rule != null) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: section(
                        '来源起始节',
                        first,
                        [
                          for (
                            var n = rule.startSection;
                            n <= rule.endSection;
                            n++
                          )
                            n,
                        ],
                        (n) {
                          first = n;
                          if (last < n) last = n;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: section('来源结束节', last, [
                        for (var n = first; n <= rule.endSection; n++) n,
                      ], (n) => last = n),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 20),
              dateField(target, '目标日期'),
              section('目标起始节', destination, sections, (n) => destination = n),
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  '目标：${sectionLabel(destination, destination + last - first)} · 共 ${last - first + 1} 节',
                ),
              ),
              if (sections.isEmpty) const Text('请先配置学校上课时间。'),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('保留原课'),
                subtitle: const Text('关闭时移走来源所选节次，其余节次保留'),
                value: keep,
                onChanged: saving ? null : (v) => setState(() => keep = v),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: saving ? null : () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: saving || rule == null || sections.isEmpty
              ? null
              : preview,
          child: const Text('预览单节调课'),
        ),
      ],
    );
  }

  Future<void> preview() async {
    setState(() => saving = true);
    try {
      final t = LessonTransfer(
        id:
            widget.existing?.id ??
            'lesson_${DateTime.now().microsecondsSinceEpoch}',
        scheduleId: scheduleId!,
        sourceDate: readSchoolDate(source.text),
        targetDate: readSchoolDate(target.text),
        sourceStart: first,
        sourceEnd: last,
        targetStart: destination,
        keepSource: keep,
      );
      final calc = SemesterWeekCalculator(snapshot.semester);
      if (calc.getWeekForDate(t.sourceDate) == null ||
          calc.getWeekForDate(t.targetDate) == null) {
        throw const FormatException('日期必须在当前学期内');
      }
      if (!snapshot.classTimes.any((c) => c.section == t.targetEnd)) {
        throw const FormatException('目标结束节超出已配置的上课节次');
      }
      final affected = widget.app
          .timeline(t.targetDate)
          .items
          .where(
            (i) =>
                i.schedule != null &&
                i.schedule!.startSection <= t.targetEnd &&
                i.schedule!.endSection >= t.targetStart,
          )
          .toList();
      final yes = await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
          title: const Text('确认单节调课'),
          content: SingleChildScrollView(
            child: Text(
              '${snapshot.courses.singleWhere((c) => c.id == selected!.courseId).name}\n${lessonTransferLabel(snapshot.semester, t)}\n\n调至 ${dateText(t.targetDate)}（${dateLabel(target.text)}）${sectionLabel(t.targetStart, t.targetEnd)}\n${keep ? '来源所选节次保留' : '来源所选节次移走，其他节次保留'}\n\n${affected.isEmpty ? '目标所选节次当前无课程。' : '与目标原有课程时间冲突：${affected.map((i) => i.title).toSet().join('、')}。调入课程与原有课程均保留，请检查安排。'}\n保存后可修改或撤销。',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text('返回修改'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(c, true),
              child: const Text('确认保存'),
            ),
          ],
        ),
      );
      if (yes == true) {
        await widget.app.saveLessonTransfer(t);
        if (mounted) Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) message(context, friendlyError(e));
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }
}
