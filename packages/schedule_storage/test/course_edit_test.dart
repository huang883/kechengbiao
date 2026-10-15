import 'dart:convert';
import 'dart:io';
import 'package:schedule_core/schedule_core.dart';
import 'package:schedule_storage/schedule_storage.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;
import 'package:test/test.dart';

void main() {
  test(
    'v4 upgrade: edit, minute times, create, section reset and reopen preserve data',
    () async {
      final dir = Directory.systemTemp.createTempSync('course_edit_');
      final path = '${dir.path}/db.sqlite';
      final raw = sqlite.sqlite3.open(path);
      final schema = jsonDecode(
        File('schemas/drift_schema_v4.json').readAsStringSync(),
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
        "INSERT INTO courses VALUES ('c','course','teacher','#123456','keep')",
      );
      raw.execute(
        "INSERT INTO course_schedules VALUES ('a','c','s',1,1,2,'old room','remark')",
      );
      raw.execute("INSERT INTO schedule_weeks VALUES ('a',2)");
      raw.execute(
        "INSERT INTO class_times VALUES ('s',1,'08:00','08:45'),('s',2,'08:55','09:40')",
      );
      raw.execute(
        "INSERT INTO task_events VALUES ('task','keep','2026-09-07','12:00','12:30','',0,NULL,NULL)",
      );
      raw.execute('PRAGMA user_version=4');
      raw.close();
      var db = ScheduleDatabase.file(File(path));
      CourseSchedule rule({
        String id = 'a',
        String courseId = 'c',
        String semester = 's',
        String? start = '09:12',
        String? end = '10:18',
      }) => CourseSchedule(
        id: id,
        courseId: courseId,
        semesterId: semester,
        weekday: 2,
        startSection: 1,
        endSection: 2,
        classroom: 'new room',
        activeWeeks: [2, 3],
        customStartTime: start,
        customEndTime: end,
      );
      try {
        final settings = DriftSettingsRepository(db);
        const course = Course(
          id: 'c',
          name: 'new name',
          teacher: 'teacher',
          color: '#123456',
          remark: 'keep',
        );
        await settings.saveCourseSchedule(course, rule(), creating: false);
        var snapshot = (await DriftCourseRepository(db).loadSemester('s'))!;
        expect(snapshot.classTimes.first.startTime, '08:00');
        expect(snapshot.courses.single.color, '#123456');
        expect(snapshot.schedules.single.classroom, 'new room');
        final items = TimelineService()
            .forDate(DateTime.utc(2026, 9, 8), snapshot, [])
            .items;
        expect(items.single.startDateTime, DateTime.utc(2026, 9, 8, 9, 12));
        expect(items.single.endDateTime, DateTime.utc(2026, 9, 8, 10, 18));
        expect(
          TimelineService()
              .forDate(DateTime.utc(2026, 9, 7), snapshot, [])
              .items,
          isEmpty,
        );
        await expectLater(
          settings.saveCourseSchedule(
            course,
            rule(start: '12:00', end: '11:00'),
            creating: false,
          ),
          throwsFormatException,
        );
        await expectLater(
          settings.saveCourseSchedule(
            const Course(id: 'wrong', name: 'wrong', teacher: ''),
            rule(),
            creating: false,
          ),
          throwsFormatException,
        );
        await settings.saveCourseSchedule(
          const Course(id: 'new', name: 'manual', teacher: ''),
          rule(id: 'new_schedule', courseId: 'new', start: null, end: null),
          creating: true,
        );
        await db.close();
        db = ScheduleDatabase.file(File(path));
        snapshot = (await DriftCourseRepository(db).loadSemester('s'))!;
        expect(snapshot.schedules.length, 2);
        expect(
          snapshot.schedules.firstWhere((s) => s.id == 'a').customStartTime,
          '09:12',
        );
        expect((await DriftTaskRepository(db).list()).single.title, 'keep');
        await DriftSettingsRepository(db).saveCourseSchedule(
          course,
          rule(start: null, end: null),
          creating: false,
        );
        snapshot = (await DriftCourseRepository(db).loadSemester('s'))!;
        expect(
          ClassTimeService()
              .getClassTime(
                snapshot.schedules.firstWhere((s) => s.id == 'a'),
                snapshot.classTimes,
              )!
              .start,
          '08:00',
        );
        expect(
          (await db.customSelect('PRAGMA foreign_key_check').get()),
          isEmpty,
        );
      } finally {
        await db.close();
        dir.deleteSync(recursive: true);
      }
    },
  );
}
