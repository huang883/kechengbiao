import 'dart:convert';
import 'dart:io';
import 'package:schedule_core/schedule_core.dart';
import 'package:schedule_storage/schedule_storage.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;
import 'package:test/test.dart';

void main() {
  test(
    'v3 upgrade preserves data; single transfer saves updates rejects overlaps and undoes',
    () async {
      final dir = Directory.systemTemp.createTempSync('lesson_transfer_');
      final path = '${dir.path}/db.sqlite';
      final raw = sqlite.sqlite3.open(path),
          schema = jsonDecode(
            File('schemas/drift_schema_v3.json').readAsStringSync(),
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
        "INSERT INTO courses VALUES ('c','course','teacher','default','')",
      );
      raw.execute(
        "INSERT INTO course_schedules VALUES ('a','c','s',3,1,2,'room','')",
      );
      raw.execute("INSERT INTO schedule_weeks VALUES ('a',6)");
      raw.execute(
        "INSERT INTO class_times VALUES ('s',1,'08:00','08:45'),('s',2,'08:55','09:40')",
      );
      raw.execute(
        "INSERT INTO class_days_off VALUES ('s','2026-10-01','holiday')",
      );
      raw.execute(
        "INSERT INTO class_day_replacements VALUES ('s','2026-10-02','2026-10-07')",
      );
      raw.execute('PRAGMA user_version=3');
      raw.close();
      var db = ScheduleDatabase.file(File(path));
      LessonTransfer t({String id = 't', bool keep = false, int start = 1}) =>
          LessonTransfer(
            id: id,
            scheduleId: 'a',
            sourceDate: DateTime.utc(2026, 10, 7),
            targetDate: DateTime.utc(2026, 10, 8),
            sourceStart: start,
            sourceEnd: start,
            targetStart: 2,
            keepSource: keep,
          );
      try {
        var settings = DriftSettingsRepository(db);
        await settings.saveLessonTransfer('s', t());
        await expectLater(
          settings.saveLessonTransfer('s', t(id: 'overlap')),
          throwsFormatException,
        );
        await expectLater(
          settings.saveLessonTransfer('s', t(id: 'bad', start: 3)),
          throwsFormatException,
        );
        await settings.saveLessonTransfer('s', t(keep: true));
        await db.close();
        db = ScheduleDatabase.file(File(path));
        final snap = (await DriftCourseRepository(db).loadSemester('s'))!;
        expect(snap.lessonTransfers.single.keepSource, isTrue);
        expect(snap.daysOff.length, 1);
        expect(snap.replacements.length, 1);
        expect(snap.classTimes.length, 2);
        settings = DriftSettingsRepository(db);
        await settings.deleteLessonTransfer('s', 't');
        expect(
          (await DriftCourseRepository(db).loadSemester('s'))!.lessonTransfers,
          isEmpty,
        );
      } finally {
        await db.close();
        await File(path).delete();
        await dir.delete();
      }
    },
  );
}
