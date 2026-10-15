import 'dart:convert';
import 'dart:io';
import 'package:schedule_core/schedule_core.dart';
import 'package:schedule_storage/schedule_storage.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;
import 'package:test/test.dart';

void main() {
  test(
    'v5 upgrade preserves timed tasks; untimed tasks and edited transfer survive reopen',
    () async {
      final dir = Directory.systemTemp.createTempSync('untimed_transfer_');
      final path = '${dir.path}/db.sqlite';
      final raw = sqlite.sqlite3.open(path);
      final schema = jsonDecode(
        File('schemas/drift_schema_v5.json').readAsStringSync(),
      );
      for (final entity in schema['fixed_sql'] as List) {
        for (final sql in entity['sql'] as List) {
          if (sql['dialect'] == 'sqlite') raw.execute(sql['sql'] as String);
        }
      }
      raw.execute(
        "INSERT INTO semesters VALUES ('s','school','2026-08-31','2027-01-16',20,1,0)",
      );
      raw.execute(
        "INSERT INTO courses VALUES ('c','course','teacher','#123456','')",
      );
      raw.execute(
        "INSERT INTO course_schedules VALUES ('a','c','s',1,1,2,'original room','')",
      );
      raw.execute("INSERT INTO schedule_weeks VALUES ('a',2)");
      raw.execute(
        "INSERT INTO class_times VALUES ('s',1,'08:00','08:45'),('s',2,'08:55','09:40'),('s',3,'10:00','10:45')",
      );
      raw.execute(
        "INSERT INTO task_events VALUES ('timed','existing','2026-09-08','12:00','12:30','',0,5,NULL)",
      );
      raw.execute(
        "INSERT INTO lesson_transfers VALUES ('t','s','a','2026-09-07','2026-09-08',1,1,3,0)",
      );
      raw.execute('PRAGMA user_version=5');
      raw.close();
      var db = ScheduleDatabase.file(File(path));
      try {
        final tasks = DriftTaskRepository(db);
        final settings = DriftSettingsRepository(db);
        expect((await tasks.read('timed'))!.startTime, '12:00');
        final untimed = TaskEvent(
          id: 'untimed',
          title: 'anytime',
          date: DateTime.utc(2026, 9, 8),
        );
        await tasks.create(untimed);
        expect((await tasks.read('untimed'))!.hasTime, isFalse);
        final target = CourseSchedule(
          id: 'a',
          courseId: 'c',
          semesterId: 's',
          weekday: 2,
          startSection: 3,
          endSection: 3,
          classroom: 'new room',
          activeWeeks: [2],
          customStartTime: '15:12',
          customEndTime: '16:18',
        );
        await settings.editTransferredCourse(
          's',
          't',
          const Course(id: 'c', name: 'renamed', teacher: 'teacher'),
          target,
          DateTime.utc(2026, 9, 8),
        );
        var snapshot = (await DriftCourseRepository(db).loadSemester('s'))!;
        expect(snapshot.schedules.single.classroom, 'original room');
        expect(snapshot.schedules.single.customStartTime, isNull);
        var timeline = TimelineService().forDate(
          DateTime.utc(2026, 9, 8),
          snapshot,
          await tasks.list(),
        );
        expect(timeline.items.any((t) => t.title == 'anytime'), isFalse);
        var course = timeline.items.singleWhere(
          (i) => i.sourceType == 'course',
        );
        expect(course.startDateTime, DateTime.utc(2026, 9, 8, 15, 12));
        expect(course.subtitle, contains('new room'));
        expect(course.subtitle, contains('第 2 周'));
        expect(
          snapshot.lessonTransfers.single.sourceDate,
          DateTime.utc(2026, 9, 7),
        );
        // Editing the source no longer requires deleting its transfer; target clock stays independent.
        await settings.saveCourseSchedule(
          const Course(id: 'c', name: 'renamed', teacher: 'teacher'),
          CourseSchedule(
            id: 'a',
            courseId: 'c',
            semesterId: 's',
            weekday: 1,
            startSection: 1,
            endSection: 2,
            classroom: 'source edited',
            activeWeeks: [2],
            customStartTime: '07:12',
            customEndTime: '08:15',
          ),
          creating: false,
        );
        await db.close();
        db = ScheduleDatabase.file(File(path));
        snapshot = (await DriftCourseRepository(db).loadSemester('s'))!;
        expect(snapshot.lessonTransfers.length, 1);
        expect(snapshot.lessonTransfers.single.targetStartTime, '15:12');
        expect(
          (await DriftTaskRepository(db).read('untimed'))!.endTime,
          isNull,
        );
        await DriftTaskRepository(db).update(
          TaskEvent(
            id: 'untimed',
            title: 'anytime',
            date: DateTime.utc(2026, 9, 8),
            startTime: '18:00',
            endTime: '18:30',
            reminderMinutes: 5,
          ),
        );
        expect(
          (await DriftTaskRepository(db).read('untimed'))!.hasTime,
          isTrue,
        );
        await DriftTaskRepository(db).update(untimed);
        await DriftTaskRepository(db).setCompleted('untimed', true);
        expect(
          (await DriftTaskRepository(db).read('untimed'))!.completed,
          isTrue,
        );
        await DriftSettingsRepository(db).deleteLessonTransfer('s', 't');
        expect(
          await db.customSelect('SELECT * FROM lesson_transfer_edits').get(),
          isEmpty,
        );
        expect(
          await db.customSelect('PRAGMA foreign_key_check').get(),
          isEmpty,
        );
      } finally {
        await db.close();
        dir.deleteSync(recursive: true);
      }
    },
  );
}
