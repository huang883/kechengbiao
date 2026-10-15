import 'package:flutter/material.dart';
import 'package:schedule_core/schedule_core.dart';

import '../application/app_controller.dart';
import '../features/tasks/tasks_page.dart';
import 'ui.dart';

class UntimedTaskTile extends StatelessWidget {
  final AppController app;
  final TaskEvent task;
  final bool showDate;
  const UntimedTaskTile({
    super.key,
    required this.app,
    required this.task,
    this.showDate = false,
  });
  @override
  Widget build(BuildContext context) => ListTile(
    leading: Checkbox(
      value: task.completed,
      onChanged: (v) => action(context, () => app.completeTask(task.id, v!)),
    ),
    title: Text(
      task.title,
      style: TextStyle(
        decoration: task.completed ? TextDecoration.lineThrough : null,
      ),
    ),
    subtitle: Text(showDate ? '${dateText(task.date)} · 不指定时间' : '不指定时间'),
    onTap: () => openTaskEditor(context, app, task),
  );
}
