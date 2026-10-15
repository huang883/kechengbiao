import 'dart:convert';
import 'dart:io';
import 'package:schedule_core/schedule_core.dart';
import 'package:schedule_storage/schedule_storage.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;
import 'package:test/test.dart';
import 'support/fixture.dart';

void main() {
  test(
    'v1 file migrates with all old tables and audit intact, then persists calendar settings',
    () async {
      final dir = Directory.systemTemp.createTempSync('schedule_migration_');
      final file = File('${dir.path}/old.sqlite');
      addTearDown(() async {
        final root = Directory.systemTemp.resolveSymbolicLinksSync();
        final target = dir.resolveSymbolicLinksSync();
        if (!target.startsWith(
          '$root${Platform.pathSeparator}schedule_migration_',
        )) {
          throw StateError('Unsafe cleanup');
        }
        await dir.delete(recursive: true);
      });
      final raw = sqlite.sqlite3.open(file.path);
      final schema =
          jsonDecode(File('schemas/drift_schema_v1.json').readAsStringSync())
              as Map<String, dynamic>;
      for (final entity in schema['fixed_sql'] as List) {
        for (final sql in entity['sql'] as List) {
          if (sql['dialect'] == 'sqlite') raw.execute(sql['sql'] as String);
        }
      }
      raw.execute(
        "INSERT INTO semesters VALUES ('s','school','2026-08-30','2027-01-16',20,7,0)",
      );
      raw.execute(
        "INSERT INTO courses VALUES ('c','course','teacher','#4386F5','keep')",
      );
      raw.execute(
        "INSERT INTO course_schedules VALUES ('r','c','s',4,1,1,'room','remark')",
      );
      raw.execute("INSERT INTO schedule_weeks VALUES ('r',5)");
      raw.execute("INSERT INTO class_times VALUES ('s',1,'08:00','08:45')");
      raw.execute(
        "INSERT INTO task_events (id,title,event_date,start_time,end_time) VALUES ('t','task','2026-10-01','08:00','08:20')",
      );
      final json = jsonEncode(realPdf().toJson());
      raw.execute('INSERT INTO import_drafts VALUES (?,?,?)', [
        'source',
        1,
        json,
      ]);
      raw.execute('INSERT INTO import_revisions VALUES (?,?,?,?,?)', [
        'source',
        1,
        json,
        '{}',
        'keep reason',
      ]);
      raw.execute("INSERT INTO import_commits VALUES ('source',1,'s',1,1)");
      raw.execute(
        "INSERT INTO import_record_metadata VALUES ('r','source',1,'record','class',36,NULL,'{}')",
      );
      raw.execute('PRAGMA user_version=1');
      raw.close();
      final db = ScheduleDatabase.file(file);
      try {
        final courses = DriftCourseRepository(db),
            settings = DriftSettingsRepository(db);
        final before = (await courses.loadSemester('s'))!;
        expect(before.daysOff, isEmpty);
        expect(before.classTimes.single.startTime, '08:00');
        expect(before.courses.single.color, '#4386F5');
        expect((await DriftTaskRepository(db).read('t'))!.title, 'task');
        expect((await courses.readMetadata('s')).single.totalHours, 36);
        expect(
          (await DriftImportRepository(db).history('source')).single.reason,
          'keep reason',
        );
        expect(
          (await db.customSelect('PRAGMA user_version').getSingle())
              .data
              .values
              .single,
          6,
        );
        await settings.updateSemesterCalendar(
          's',
          firstWeekStart: DateTime.utc(2026, 8, 31),
          weekStartDay: 1,
        );
        await settings.saveDayOff(
          's',
          ClassDayOff(date: DateTime.utc(2026, 10, 1), reason: '国庆节'),
        );
        await settings.saveDayOff(
          's',
          ClassDayOff(date: DateTime.utc(2026, 10, 1), reason: '国庆停课'),
        );
        expect((await courses.loadSemester('s'))!.daysOff.length, 1);
        await expectLater(
          settings.saveDayOff(
            's',
            ClassDayOff(date: DateTime.utc(2027, 2, 1), reason: 'out'),
          ),
          throwsFormatException,
        );
        await expectLater(
          settings.updateSemesterCalendar(
            's',
            firstWeekStart: DateTime.utc(2026, 8, 30),
            weekStartDay: 1,
          ),
          throwsFormatException,
        );
      } finally {
        await db.close();
      }
      final reopened = ScheduleDatabase.file(file);
      try {
        final snapshot = (await DriftCourseRepository(
          reopened,
        ).loadSemester('s'))!;
        expect(snapshot.semester.weekStartDay, 1);
        expect(snapshot.daysOff.single.reason, '国庆停课');
        expect(
          TimelineService()
              .forDate(DateTime.utc(2026, 10, 1), snapshot, [])
              .items,
          isEmpty,
        );
        await DriftSettingsRepository(
          reopened,
        ).deleteDayOff('s', DateTime.utc(2026, 10, 1));
        final restored = (await DriftCourseRepository(
          reopened,
        ).loadSemester('s'))!;
        expect(
          TimelineService()
              .forDate(DateTime.utc(2026, 10, 1), restored, [])
              .items
              .length,
          1,
        );
        expect(
          (await reopened.customSelect('PRAGMA integrity_check').getSingle())
              .data
              .values
              .single,
          'ok',
        );
        for (final table in [
          'courses',
          'course_schedules',
          'schedule_weeks',
          'class_times',
          'task_events',
          'import_drafts',
          'import_revisions',
          'import_commits',
          'import_record_metadata',
        ]) {
          expect(
            (await reopened
                    .customSelect('SELECT COUNT(*) AS n FROM $table')
                    .getSingle())
                .read<int>('n'),
            1,
            reason: table,
          );
        }
      } finally {
        await reopened.close();
      }
    },
  );
}
