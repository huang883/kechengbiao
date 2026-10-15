import 'package:flutter/material.dart';

import '../../application/app_controller.dart';
import '../../shared/ui.dart';

Future<void> confirmWeekStart(BuildContext context, AppController app) =>
    showDialog<void>(
      context: context,
      builder: (_) => WeekStartDialog(app: app),
    );

class WeekStartDialog extends StatefulWidget {
  final AppController app;
  const WeekStartDialog({super.key, required this.app});
  @override
  State<WeekStartDialog> createState() => _WeekStartDialogState();
}

class _WeekStartDialogState extends State<WeekStartDialog> {
  int? selected;
  bool saving = false;
  @override
  void initState() {
    super.initState();
    final saved = widget.app.draft!.reviewed.semester['weekStartDay'];
    if (saved is int && saved >= 1 && saved <= 7) selected = saved;
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !saving,
    child: AlertDialog(
      title: const Text('确认周起始日'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '请选择学校每周的第一天。PDF 未注明这一约定，请按学校校历选择；学期开始日期不等于周起始日。',
              style: TextStyle(height: 1.6),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (var day = 1; day <= 7; day++)
                  ChoiceChip(
                    label: Text('星期${'一二三四五六日'[day - 1]}'),
                    selected: selected == day,
                    onSelected: saving
                        ? null
                        : (_) => setState(() => selected = day),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              '这里只保存学期约定，课程仍需在预览末尾确认导入。',
              style: TextStyle(fontSize: 12, color: Colors.black54),
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
          onPressed: selected == null || saving
              ? null
              : () async {
                  setState(() => saving = true);
                  try {
                    await widget.app.editDraft(
                      semester: {'weekStartDay': selected},
                    );
                    if (context.mounted) Navigator.pop(context);
                  } catch (e) {
                    if (context.mounted) message(context, friendlyError(e));
                  } finally {
                    if (mounted) setState(() => saving = false);
                  }
                },
          child: Text(saving ? '保存中…' : '确认并保存'),
        ),
      ],
    ),
  );
}
