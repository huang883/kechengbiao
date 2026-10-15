import 'dart:convert';
import 'dart:io';
import 'package:schedule_core/schedule_core.dart';
import 'package:schedule_storage/schedule_storage.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;
import 'package:test/test.dart';

void main() {
  test(
    'v2 upgrades, replacements upsert persist and delete without losing holidays',
    () async {
      final dir = Directory.systemTemp.createTempSync('replacement_test_');
      final file = File('${dir.path}/db.sqlite');
      final raw = sqlite.sqlite3.open(file.path);
      final schema = jsonDecode(
        File('schemas/drift_schema_v2.json').readAsStringSync(),
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
        "INSERT INTO class_days_off VALUES ('s','2026-10-01','holiday')",
      );
      raw.execute('PRAGMA user_version=2');
      raw.close();
      var db = ScheduleDatabase.file(file);
      try {
        var settings = DriftSettingsRepository(db);
        final target = DateTime.utc(2026, 10, 1);
        await settings.saveReplacement(
          's',
          ClassDayReplacement(
            sourceDate: DateTime.utc(2026, 10, 7),
            targetDate: target,
          ),
        );
        await settings.saveReplacement(
          's',
          ClassDayReplacement(
            sourceDate: DateTime.utc(2026, 10, 8),
            targetDate: target,
          ),
        );
        await expectLater(
          settings.saveReplacement(
            's',
            ClassDayReplacement(
              sourceDate: DateTime.utc(2027, 2, 1),
              targetDate: target,
            ),
          ),
          throwsFormatException,
        );
        await db.close();
        db = ScheduleDatabase.file(file);
        final snapshot = (await DriftCourseRepository(db).loadSemester('s'))!;
        expect(
          snapshot.replacements.single.sourceDate,
          DateTime.utc(2026, 10, 8),
        );
        expect(snapshot.daysOff.single.reason, 'holiday');
        settings = DriftSettingsRepository(db);
        await settings.deleteReplacement('s', target);
        expect(
          (await DriftCourseRepository(db).loadSemester('s'))!.replacements,
          isEmpty,
        );
        expect(
          (await db.customSelect('PRAGMA integrity_check').getSingle())
              .data
              .values
              .single,
          'ok',
        );
      } finally {
        await db.close();
        await file.delete();
        await dir.delete();
      }
    },
  );
}
