import 'dart:convert';
import 'dart:io';
import 'package:schedule_core/schedule_core.dart';
import 'package:schedule_storage/schedule_storage.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;
import 'package:test/test.dart';
import 'support/fixture.dart';

Future<void> removeTestDirectory(Directory directory) async {
  final root = Directory.systemTemp.resolveSymbolicLinksSync();
  final target = directory.resolveSymbolicLinksSync();
  if (!target.startsWith('$root${Platform.pathSeparator}schedule_')) {
    throw StateError(
      'Refusing to delete a directory outside the test temporary root',
    );
  }
  await Directory(target).delete(recursive: true);
}

void main() {
  test(
    'closed file reopens in a separate Dart process with courses, tasks, settings and audit intact',
    () async {
      final directory = Directory.systemTemp.createTempSync(
        'schedule_persistence_',
      );
      addTearDown(() => removeTestDirectory(directory));
      final file = File('${directory.path}/schedule.sqlite');
      final db = ScheduleDatabase.file(file);
      late ImportDraft draft;
      late ImportResult result;
      try {
        final imports = DriftImportRepository(db);
        draft = await reviewed(imports);
        result = await imports.confirmImport(
          draft.id,
          expectedRevision: 2,
          confirmed: true,
        );
        final snapshot = (await DriftCourseRepository(
          db,
        ).loadSemester(result.semesterId))!;
        final settings = DriftSettingsRepository(db);
        await settings.replaceClassTimes(result.semesterId, [
          ClassTimeConfig(
            semesterId: result.semesterId,
            section: 1,
            startTime: '08:00',
            endTime: '08:45',
          ),
        ]);
        await settings.setManualWeekOffset(result.semesterId, 1);
        await settings.setCourseColor(snapshot.courses.first.id, '#4386F5');
        await DriftTaskRepository(db).create(
          TaskEvent(
            id: 'persisted_task',
            title: '复习',
            date: DateTime.utc(2026, 10, 6),
            startTime: '10:17',
            endTime: '11:35',
            completed: true,
            reminderMinutes: 10,
          ),
        );
      } finally {
        await db.close();
      }
      final executable = File(
        'build/reopen_probe/bundle/bin/reopen_probe${Platform.isWindows ? '.exe' : ''}',
      );
      if (!executable.existsSync()) {
        fail(
          'Build the independent probe first: dart build cli --target test/support/reopen_probe.dart --output build/reopen_probe',
        );
      }
      final process = await Process.run(executable.absolute.path, [
        file.path,
        result.semesterId,
        draft.id,
      ]);
      expect(process.exitCode, 0, reason: process.stderr.toString());
      final jsonLine = (process.stdout as String)
          .split('\n')
          .lastWhere((line) => line.startsWith('{'));
      expect(jsonDecode(jsonLine), {
        'courses': 14,
        'rules': 22,
        'week11': 0,
        'metadata': 22,
        'classStart': '08:00',
        'offset': 1,
        'color': '#4386F5',
        'taskStart': '10:17',
        'taskEnd': '11:35',
        'completed': true,
        'reminder': 10,
        'history': 2,
        'originalWeekStart': 'unclear',
        'excluded': ['other_1'],
      });
      final reopened = ScheduleDatabase.file(file);
      try {
        final retry = await DriftImportRepository(
          reopened,
        ).confirmImport(draft.id, expectedRevision: 2, confirmed: true);
        expect(retry.alreadyCommitted, isTrue);
        expect(
          await reopened
              .customSelect('PRAGMA integrity_check')
              .map((r) => r.data.values.single)
              .get(),
          ['ok'],
        );
      } finally {
        await reopened.close();
      }
    },
  );
  test('future schema version fails without dropping existing data', () async {
    final directory = Directory.systemTemp.createTempSync('schedule_version_');
    addTearDown(() => removeTestDirectory(directory));
    final file = File('${directory.path}/future.sqlite');
    final raw = sqlite.sqlite3.open(file.path);
    raw.execute('CREATE TABLE sentinel (value TEXT)');
    raw.execute("INSERT INTO sentinel VALUES ('keep me')");
    raw.execute('PRAGMA user_version=99');
    raw.close();
    final db = ScheduleDatabase.file(file);
    try {
      await expectLater(
        DriftCourseRepository(db).listSemesters(),
        throwsA(anything),
      );
    } finally {
      await db.close();
    }
    final check = sqlite.sqlite3.open(file.path);
    try {
      expect(
        check.select('SELECT value FROM sentinel').single['value'],
        'keep me',
      );
    } finally {
      check.close();
    }
  });
}
