import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:schedule_core/schedule_core.dart';

import '../../application/app_controller.dart';
import '../../shared/ui.dart';
import 'calendar_settings.dart' show readSchoolDate;
import 'lesson_transfer_editor.dart';

void openReplacements(BuildContext context) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  showDragHandle: true,
  builder: (_) => const _ReplacementSheet(),
);

class ReplacementSettings extends StatelessWidget {
  final AppController app;
  const ReplacementSettings({super.key, required this.app});
  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      title: const Text('课程调课'),
      subtitle: Text(
        '${app.snapshot!.lessonTransfers.length} 条单节调课 · ${app.snapshot!.replacements.length} 天整天调课',
      ),
      trailing: const Icon(Icons.swap_horiz),
      onTap: () => openReplacements(context),
    ),
  );
}

class _ReplacementSheet extends ConsumerWidget {
  const _ReplacementSheet();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final app = ref.watch(appProvider), snapshot = app.snapshot!;
    return DraggableScrollableSheet(
      initialChildSize: .85,
      minChildSize: .25,
      maxChildSize: .95,
      expand: false,
      shouldCloseOnMinExtent: true,
      builder: (context, scrollController) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 12, 0),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '课程调课',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ),
                TextButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                  label: const Text('关闭'),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              controller: scrollController,
              padding: const EdgeInsets.all(24),
              children: [
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: () => openLessonTransfer(context, app),
                  icon: const Icon(Icons.swap_horiz),
                  label: const Text('添加单节调课'),
                ),
                LessonTransferCards(app: app),
                const Divider(),
                const Text('整天调课：复制来源当天原始课表，来源日保持不变。单节调课优先；个人待办不变。'),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () => showDialog<void>(
                    context: context,
                    builder: (_) => _ReplacementEditor(app: app),
                  ),
                  icon: const Icon(Icons.add),
                  label: const Text('添加整天调课'),
                ),
                for (final r in snapshot.replacements)
                  Card(
                    child: ListTile(
                      title: Text(
                        '${dateText(r.targetDate)} · 星期${'一二三四五六日'[r.targetDate.weekday - 1]}',
                      ),
                      subtitle: Text(replacementLabel(snapshot.semester, r)),
                      onTap: () => showDialog<void>(
                        context: context,
                        builder: (_) =>
                            _ReplacementEditor(app: app, existing: r),
                      ),
                      trailing: IconButton(
                        tooltip: '撤销 ${dateText(r.targetDate)}',
                        icon: const Icon(Icons.undo),
                        onPressed: () async {
                          final yes = await showDialog<bool>(
                            context: context,
                            builder: (c) => AlertDialog(
                              title: const Text('撤销这次调课？'),
                              content: Text(
                                '${dateText(r.targetDate)} 将恢复原课表和停课设置。',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(c, false),
                                  child: const Text('取消'),
                                ),
                                FilledButton(
                                  onPressed: () => Navigator.pop(c, true),
                                  child: const Text('撤销调课'),
                                ),
                              ],
                            ),
                          );
                          if (yes == true && context.mounted) {
                            await action(
                              context,
                              () => app.removeReplacement(r.targetDate),
                            );
                          }
                        },
                      ),
                    ),
                  ),
                if (snapshot.replacements.isEmpty &&
                    snapshot.lessonTransfers.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(24),
                    child: Text('尚未设置调课'),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReplacementEditor extends StatefulWidget {
  final AppController app;
  final ClassDayReplacement? existing;
  const _ReplacementEditor({required this.app, this.existing});
  @override
  State<_ReplacementEditor> createState() => _ReplacementEditorState();
}

class _ReplacementEditorState extends State<_ReplacementEditor> {
  late final TextEditingController source, target;
  bool saving = false;
  @override
  void initState() {
    super.initState();
    final s = widget.app.snapshot!.semester;
    final today = widget.app.now;
    final date = SemesterWeekCalculator(s).getWeekForDate(today) == null
        ? s.startDate
        : today;
    source = TextEditingController(
      text: dateText(widget.existing?.sourceDate ?? date),
    );
    target = TextEditingController(
      text: dateText(widget.existing?.targetDate ?? date),
    );
  }

  @override
  void dispose() {
    source.dispose();
    target.dispose();
    super.dispose();
  }

  Future<void> pick(TextEditingController field) async {
    final s = widget.app.snapshot!.semester;
    var initial = s.startDate;
    try {
      initial = readSchoolDate(field.text);
    } on FormatException {
      /* Keep typing available. */
    }
    if (initial.isBefore(s.startDate) || initial.isAfter(s.endDate)) {
      initial = s.startDate;
    }
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: s.startDate,
      lastDate: s.endDate,
    );
    if (date != null && mounted) setState(() => field.text = dateText(date));
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.existing == null ? '添加调课' : '修改调课来源'),
    content: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('选择来源原课表及被覆盖的一天。来源日已有的停课或调课不参与复制。'),
          const SizedBox(height: 16),
          TextField(
            controller: source,
            enabled: !saving,
            decoration: InputDecoration(
              labelText: '来源日期 YYYY-MM-DD',
              suffixIcon: IconButton(
                tooltip: '选择来源日期',
                onPressed: saving ? null : () => pick(source),
                icon: const Icon(Icons.calendar_month),
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: target,
            enabled: !saving && widget.existing == null,
            decoration: InputDecoration(
              labelText: '覆盖日期 YYYY-MM-DD',
              suffixIcon: widget.existing != null
                  ? null
                  : IconButton(
                      tooltip: '选择覆盖日期',
                      onPressed: saving ? null : () => pick(target),
                      icon: const Icon(Icons.calendar_month),
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
                  final r = ClassDayReplacement(
                    sourceDate: readSchoolDate(source.text),
                    targetDate: readSchoolDate(target.text),
                  );
                  final snap = widget.app.snapshot!,
                      calc = SemesterWeekCalculator(snap.semester);
                  if (calc.getWeekForDate(r.sourceDate) == null ||
                      calc.getWeekForDate(r.targetDate) == null) {
                    throw const FormatException('来源和目标日期必须在当前学期的有效教学周内');
                  }
                  final rules = CourseFilterService(
                    snap.semester,
                    snap.schedules,
                  ).getCoursesForDate(r.sourceDate);
                  final old = widget.app.timeline(r.targetDate);
                  final count =
                      old.items.where((i) => i.sourceType == 'course').length +
                      old.unconfiguredSchedules.length;
                  final yes = await showDialog<bool>(
                    context: context,
                    builder: (c) => AlertDialog(
                      title: const Text('确认覆盖课程'),
                      content: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${dateText(r.targetDate)}（第 ${calc.getWeekForDate(r.targetDate)} 周星期${'一二三四五六日'[r.targetDate.weekday - 1]}）\n${replacementLabel(snap.semester, r)}',
                            ),
                            const SizedBox(height: 12),
                            Text('目标原有 $count 条课程将被替换为 ${rules.length} 条。'),
                            if (rules.isEmpty)
                              const Text('来源当天原课表为空，保存后目标当天将没有课程。'),
                            for (final rule in rules)
                              Text(
                                '• ${snap.courses.singleWhere((c) => c.id == rule.courseId).name} · 第 ${rule.startSection}—${rule.endSection} 节',
                              ),
                            const SizedBox(height: 12),
                            const Text('来源日和个人待办不变；目标日即使原本停课，也按调入课程上课。'),
                          ],
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(c, false),
                          child: const Text('返回修改'),
                        ),
                        FilledButton(
                          onPressed: () => Navigator.pop(c, true),
                          child: const Text('确认调课'),
                        ),
                      ],
                    ),
                  );
                  if (yes == true) {
                    await widget.app.saveReplacement(r);
                    if (context.mounted) Navigator.pop(context);
                  }
                } catch (e) {
                  if (context.mounted) message(context, friendlyError(e));
                } finally {
                  if (mounted) setState(() => saving = false);
                }
              },
        child: const Text('预览调课'),
      ),
    ],
  );
}
