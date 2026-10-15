import 'dart:convert';
import 'dart:io';
import 'package:schedule_core/schedule_core.dart';
import 'package:schedule_storage/schedule_storage.dart';

Future<void> main(List<String> args) async {
  final db = ScheduleDatabase.file(File(args[0]));
  try {
    final repo = DriftCourseRepository(db);
    final snapshot = (await repo.loadSemester(args[1]))!;
    final task = (await DriftTaskRepository(db).read('persisted_task'))!;
    final history = await DriftImportRepository(db).history(args[2]);
    stdout.writeln(
      jsonEncode({
        'courses': snapshot.courses.length,
        'rules': snapshot.schedules.length,
        'week11': CourseFilterService(
          snapshot.semester,
          snapshot.schedules,
        ).getCoursesForWeek(11).length,
        'metadata': (await repo.readMetadata(args[1])).length,
        'classStart': snapshot.classTimes.single.startTime,
        'offset': snapshot.semester.manualWeekOffset,
        'color': snapshot.courses.first.color,
        'taskStart': task.startTime,
        'taskEnd': task.endTime,
        'completed': task.completed,
        'reminder': task.reminderMinutes,
        'history': history.length,
        'originalWeekStart': history.first.original.semester['weekStartDay'],
        'excluded': history.last.exclusions.keys.toList(),
      }),
    );
  } finally {
    await db.close();
  }
}
