import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:schedule_core/schedule_core.dart';

import '../../application/app_controller.dart';
import '../../shared/ui.dart';
import 'week_start_dialog.dart';

class ImportPage extends ConsumerStatefulWidget {
  const ImportPage({super.key});
  @override
  ConsumerState<ImportPage> createState() => _ImportPageState();
}

class _ImportPageState extends ConsumerState<ImportPage> {
  bool busy = false, checked = false;
  int? checkedRevision;
  Future<void> pick() async {
    setState(() => busy = true);
    try {
      final file = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );
      if (file != null) {
        if ((await file.length() ?? 0) > 20 * 1024 * 1024) {
          throw const FormatException('文件超过 20 MB，请选择学校导出的课表 PDF');
        }
        if (!mounted) return;
        await ref.read(appProvider).importBytes(await file.readAsBytes());
        checked = false;
      }
    } catch (e) {
      if (mounted) message(context, friendlyError(e));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = ref.watch(appProvider), draft = ref.read(appProvider).draft;
    final errors = app.draftIssues.where((i) => i.severity == 'error').toList();
    final weekStart = draft?.reviewed.semester['weekStartDay'];
    final needsWeek = weekStart is! int || weekStart < 1 || weekStart > 7;
    final recordErrors = errors
        .where((i) => i.recordId != null)
        .map((i) => i.recordId!)
        .toSet();
    final semesterErrors = errors
        .where(
          (i) =>
              i.recordId == null && !i.code.toLowerCase().contains('weekstart'),
        )
        .toList();
    final count = draft == null
        ? 0
        : draft.reviewed.records.length - draft.exclusions.length;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      children: [
        const Text(
          '导入新增独立课表，已有课表会保留。\n同一份 PDF 重复导入会打开已有课表。',
          style: TextStyle(color: Colors.black54),
        ),
        const SizedBox(height: 18),
        OutlinedButton.icon(
          onPressed: busy ? null : pick,
          icon: const Icon(Icons.upload_file_outlined),
          label: Text(busy ? '正在读取课表…' : '选择学校课表 PDF'),
        ),
        if (busy)
          const Padding(
            padding: EdgeInsets.all(20),
            child: LinearProgressIndicator(),
          ),
        if (draft == null && !busy)
          const EmptyState(
            icon: Icons.fact_check_outlined,
            title: '先预览，再保存',
            body: '支持已验证的学校单页课表版式。\n课程不会在识别后自动进入正式课表。',
          ),
        if (draft != null) ...[
          if (draft.committed)
            InfoCard(
              '这份课表已经导入。可到周课表或设置中查看。',
              onTap: () => action(context, () async {
                await app.selectSemester('semester_${draft.id}');
                if (context.mounted) context.go('/schedule');
              }),
            ),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    needsWeek
                        ? '导入前，请确认周起始日'
                        : '已确认：每周从星期${'一二三四五六日'[(weekStart) - 1]}开始',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '周起始日是每周的第一天，请按学校校历选择。',
                    style: TextStyle(color: Colors.black54),
                  ),
                  if (!draft.committed)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: FilledButton.icon(
                        onPressed: busy
                            ? null
                            : () => confirmWeekStart(context, app),
                        icon: const Icon(Icons.calendar_today_outlined),
                        label: Text(needsWeek ? '确认周起始日' : '修改周起始日'),
                      ),
                    ),
                ],
              ),
            ),
          ),
          SemesterEditor(
            key: ValueKey('${draft.id}:${draft.revision}'),
            app: app,
            draft: draft,
          ),
          SectionTitle('课程预览 · $count 条'),
          if (needsWeek)
            InfoCard(
              '尚未确认周起始日，点击这里选择并保存。',
              onTap: () => confirmWeekStart(context, app),
            ),
          if (semesterErrors.isNotEmpty)
            const InfoCard('学期日期或总周数仍需检查，请修改后保存学期信息。'),
          if (recordErrors.isNotEmpty)
            InfoCard(
              '仍有 ${recordErrors.length} 条课程信息不完整：${draft.reviewed.records.where((r) => recordErrors.contains(r.id)).map((r) => r.fields['name']).join('、')}。请在对应课程卡片修正，或勾选“此次不导入这条记录”。',
            ),
          const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: Text(
              '课表未提供钟点时间，导入后请在设置中补充学校作息。',
              style: TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ),
          for (final record in draft.reviewed.records)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            record.fields['name'] == unclear
                                ? '待确认课程'
                                : record.fields['name'] as String,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              decoration:
                                  draft.exclusions.containsKey(record.id)
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                          ),
                        ),
                        if (!draft.committed)
                          IconButton(
                            tooltip: '修正课程',
                            icon: const Icon(Icons.edit_outlined, size: 20),
                            onPressed: () => showModalBottomSheet<void>(
                              context: context,
                              isScrollControlled: true,
                              useSafeArea: true,
                              builder: (_) =>
                                  RecordEditor(app: app, record: record),
                            ),
                          ),
                      ],
                    ),
                    Text(
                      '星期：${_display(record.fields['weekday'])} · 第 ${_display(record.fields['startSection'])}—${_display(record.fields['endSection'])} 节\n${_display(record.fields['classroom'])}',
                      style: const TextStyle(height: 1.6),
                    ),
                    const SizedBox(height: 6),
                    if (recordErrors.contains(record.id))
                      const Padding(
                        padding: EdgeInsets.only(bottom: 8),
                        child: Text(
                          '待处理：排课信息不完整，请修正或明确选择此次不导入。',
                          style: TextStyle(
                            color: Color(0xFF936B28),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    Text(
                      '周次：${record.fields['activeWeeks'] is List ? (record.fields['activeWeeks'] as List).join('、') : '未明确'}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    ),
                    if (!draft.committed)
                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                        controlAffinity: ListTileControlAffinity.leading,
                        value: draft.exclusions.containsKey(record.id),
                        title: const Text(
                          '此次不导入这条记录',
                          style: TextStyle(fontSize: 13),
                        ),
                        onChanged: (value) => action(context, () async {
                          final exclusions = {...app.draft!.exclusions};
                          if (value == true) {
                            exclusions[record.id] = '用户在预览中明确选择不导入';
                          } else {
                            exclusions.remove(record.id);
                          }
                          await app.editDraft(exclusions: exclusions);
                          if (mounted) setState(() => checked = false);
                        }),
                      ),
                    ExpansionTile(
                      tilePadding: EdgeInsets.zero,
                      title: const Text('查看原文', style: TextStyle(fontSize: 12)),
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: SelectableText(
                            (record.source['rawBlock'] ??
                                    record.source['rawText'] ??
                                    '')
                                .toString(),
                            style: const TextStyle(fontSize: 12, height: 1.5),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          if (!draft.committed) ...[
            if (needsWeek)
              FilledButton(
                onPressed: busy ? null : () => confirmWeekStart(context, app),
                child: const Text('先确认周起始日'),
              ),
            CheckboxListTile(
              value: checked && checkedRevision == draft.revision,
              onChanged: (v) => setState(() {
                checked = v!;
                checkedRevision = draft.revision;
              }),
              title: const Text('我已检查课程与学期信息'),
              contentPadding: EdgeInsets.zero,
            ),
            FilledButton.icon(
              onPressed:
                  busy ||
                      !checked ||
                      checkedRevision != draft.revision ||
                      errors.isNotEmpty ||
                      count == 0
                  ? null
                  : () async {
                      setState(() => busy = true);
                      try {
                        await app.confirmDraft();
                        if (context.mounted) {
                          message(context, '已导入课表，请补充学校作息');
                          context.go('/schedule');
                        }
                      } catch (e) {
                        if (context.mounted) message(context, friendlyError(e));
                      } finally {
                        if (mounted) setState(() => busy = false);
                      }
                    },
              icon: const Icon(Icons.check_circle_outline),
              label: Text('确认导入 $count 条排课'),
            ),
          ],
        ],
      ],
    );
  }

  String _display(Object? value) =>
      value == unclear || value == null ? '未明确' : '$value';
}

class SemesterEditor extends StatefulWidget {
  final AppController app;
  final ImportDraft draft;
  const SemesterEditor({super.key, required this.app, required this.draft});
  @override
  State<SemesterEditor> createState() => _SemesterEditorState();
}

class _SemesterEditorState extends State<SemesterEditor> {
  late final Map<String, TextEditingController> fields;
  bool saving = false;
  @override
  void initState() {
    super.initState();
    final s = widget.draft.reviewed.semester;
    fields = {
      for (final k in ['name', 'startDate', 'endDate', 'totalWeeks'])
        k: TextEditingController(text: s[k] == unclear ? '' : '${s[k]}'),
    };
  }

  @override
  void dispose() {
    for (final c in fields.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '学期信息',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
          ),
          const SizedBox(height: 12),
          for (final entry in {
            'name': '学期名称',
            'startDate': '开始日期 YYYY-MM-DD',
            'endDate': '结束日期 YYYY-MM-DD',
            'totalWeeks': '总周数',
          }.entries)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: TextField(
                controller: fields[entry.key],
                enabled: !widget.draft.committed,
                decoration: InputDecoration(labelText: entry.value),
              ),
            ),
          if (!widget.draft.committed)
            OutlinedButton(
              onPressed: saving
                  ? null
                  : () async {
                      setState(() => saving = true);
                      await action(context, () async {
                        final weeks = int.tryParse(fields['totalWeeks']!.text);
                        if (weeks == null || weeks < 1 || weeks > 366) {
                          throw const FormatException('请填写有效的总周数');
                        }
                        final semester = <String, dynamic>{
                          for (final k in ['name', 'startDate', 'endDate'])
                            k: fields[k]!.text.trim(),
                          'totalWeeks': weeks,
                        };
                        await widget.app.editDraft(semester: semester);
                      });
                      if (mounted) setState(() => saving = false);
                    },
              child: const Text('保存学期信息'),
            ),
        ],
      ),
    ),
  );
}

class RecordEditor extends StatefulWidget {
  final AppController app;
  final ParsedCourseRecord record;
  const RecordEditor({super.key, required this.app, required this.record});
  @override
  State<RecordEditor> createState() => _RecordEditorState();
}

class _RecordEditorState extends State<RecordEditor> {
  static const labels = {
    'name': '课程名称',
    'teacher': '教师',
    'teachingClass': '教学班',
    'classroom': '教室',
    'weekday': '星期（1—7）',
    'startSection': '开始节次',
    'endSection': '结束节次',
    'weekExpression': '周次，如 1-10周,12-17周',
    'remark': '备注',
    'totalHours': '总学时（未知留空）',
    'credits': '学分（未知留空）',
  };
  late final Map<String, TextEditingController> fields;
  bool saving = false;
  @override
  void initState() {
    super.initState();
    fields = {
      for (final k in labels.keys)
        k: TextEditingController(
          text: widget.record.fields[k] == unclear
              ? ''
              : '${widget.record.fields[k]}',
        ),
    };
    fields['weekExpression']!.text = fields['weekExpression']!.text
        .replaceFirst(RegExp(r'^[（(].*?节[）)]'), '');
  }

  @override
  void dispose() {
    for (final c in fields.values) {
      c.dispose();
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
          Text('修正课程', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 20),
          for (final entry in labels.entries)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: TextField(
                controller: fields[entry.key],
                decoration: InputDecoration(labelText: entry.value),
              ),
            ),
          FilledButton(
            onPressed: saving
                ? null
                : () async {
                    setState(() => saving = true);
                    try {
                      final changes = <String, dynamic>{
                        for (final k in labels.keys) k: fields[k]!.text.trim(),
                      };
                      for (final k in [
                        'weekday',
                        'startSection',
                        'endSection',
                        'totalHours',
                        'credits',
                      ]) {
                        changes[k] = int.tryParse(fields[k]!.text) ?? unclear;
                      }
                      for (final k in [
                        'name',
                        'teacher',
                        'teachingClass',
                        'classroom',
                      ]) {
                        if (changes[k] == '') changes[k] = unclear;
                      }
                      await widget.app.editDraft(
                        records: {widget.record.id: changes},
                      );
                      if (context.mounted) Navigator.pop(context);
                    } catch (e) {
                      if (context.mounted) message(context, friendlyError(e));
                    } finally {
                      if (mounted) setState(() => saving = false);
                    }
                  },
            child: const Text('保存修正'),
          ),
        ],
      ),
    ),
  );
}
