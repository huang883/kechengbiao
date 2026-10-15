import 'package:flutter/material.dart';

import '../application/app_controller.dart';
import 'ui.dart';

class TimetableSelector extends StatelessWidget {
  final AppController app;
  const TimetableSelector({super.key, required this.app});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20),
    child: Row(
      children: [
        const Icon(Icons.calendar_month_outlined, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: DropdownButton<String>(
            key: const ValueKey('timetable-selector'),
            value: app.snapshot!.semester.id,
            isExpanded: true,
            underline: const SizedBox.shrink(),
            items: [
              for (final s in app.semesters)
                DropdownMenuItem(
                  value: s.id,
                  child: Text(s.name, overflow: TextOverflow.ellipsis),
                ),
            ],
            onChanged: (id) {
              if (id != null) action(context, () => app.selectSemester(id));
            },
          ),
        ),
        IconButton(
          tooltip: '修改课表名称',
          icon: const Icon(Icons.edit_outlined, size: 20),
          onPressed: () async {
            final semester = app.snapshot!.semester;
            final name = await showDialog<String>(
              context: context,
              builder: (_) => _RenameDialog(name: semester.name),
            );
            if (name != null && context.mounted) {
              await action(
                context,
                () => app.renameTimetable(semester.id, name),
              );
            }
          },
        ),
      ],
    ),
  );
}

class _RenameDialog extends StatefulWidget {
  final String name;
  const _RenameDialog({required this.name});
  @override
  State<_RenameDialog> createState() => _RenameDialogState();
}

class _RenameDialogState extends State<_RenameDialog> {
  late final controller = TextEditingController(text: widget.name);
  final form = GlobalKey<FormState>();
  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('修改课表名称'),
    content: Form(
      key: form,
      child: TextFormField(
        controller: controller,
        autofocus: true,
        maxLength: 60,
        decoration: const InputDecoration(labelText: '课表名称'),
        validator: (s) => s == null || s.trim().isEmpty ? '请输入课表名称' : null,
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('取消'),
      ),
      FilledButton(
        onPressed: () {
          if (form.currentState!.validate()) {
            Navigator.pop(context, controller.text.trim());
          }
        },
        child: const Text('保存'),
      ),
    ],
  );
}
