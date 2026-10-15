import 'package:schedule_core/schedule_core.dart';
import 'package:schedule_storage/schedule_storage.dart';
import 'package:test/test.dart';
import 'support/fixture.dart';

TaskEvent task(
  String id, {
  String title = '复习',
  String start = '10:17',
  String end = '11:35',
  int day = 6,
}) => TaskEvent(
  id: id,
  title: title,
  date: DateTime.utc(2026, 10, day),
  startTime: start,
  endTime: end,
  description: '记录任意分钟；不是学校节次',
  reminderMinutes: 10,
);

void main() {
  late ScheduleDatabase db;
  late DriftTaskRepository tasks;
  late DriftSettingsRepository settings;
  setUp(() {
    db = ScheduleDatabase.memory();
    tasks = DriftTaskRepository(db);
    settings = DriftSettingsRepository(db);
  });
  tearDown(() => db.close());

  test(
    'arbitrary-minute task CRUD, completion and inclusive date filters',
    () async {
      await tasks.create(task('a'));
      await tasks.create(task('b', start: '12:35', end: '13:18', day: 7));
      expect((await tasks.read('a'))!.startTime, '10:17');
      expect((await tasks.read('a'))!.endTime, '11:35');
      await tasks.update(
        task('a', title: '概率论复习', start: '19:20', end: '21:10'),
      );
      await tasks.setCompleted('a', true);
      expect((await tasks.list(completed: true)).single.title, '概率论复习');
      expect(
        (await tasks.list(
          from: DateTime.utc(2026, 10, 7),
          through: DateTime.utc(2026, 10, 7),
        )).single.id,
        'b',
      );
      await tasks.delete('a');
      await tasks.delete('a');
      expect(await tasks.read('a'), isNull);
      expect((await tasks.list()).single.id, 'b');
      await expectLater(
        tasks.update(task('missing')),
        throwsA(isA<RepositoryException>()),
      );
      await expectLater(
        tasks.setCompleted('missing', true),
        throwsA(isA<RepositoryException>()),
      );
    },
  );
  test(
    'overlapping tasks are saved; persistence does not prohibit conflicts',
    () async {
      await tasks.create(task('a'));
      await tasks.create(task('b', start: '10:30', end: '11:00'));
      expect((await tasks.list()).length, 2);
      await expectLater(
        tasks.create(task('a', title: 'overwrite')),
        throwsA(anything),
      );
      expect((await tasks.read('a'))!.title, '复习');
    },
  );
  test(
    'SQL-like titles are plain text and invalid task times are rejected',
    () async {
      const title = "复习'); DROP TABLE semesters; --";
      await tasks.create(task('quoted', title: title));
      expect((await tasks.read('quoted'))!.title, title);
      expect(await DriftCourseRepository(db).listSemesters(), isEmpty);
      for (final times in [
        ('24:00', '25:00'),
        ('11:35', '10:17'),
        ('10:00', '10:00'),
        ('8:00', '09:00'),
      ]) {
        expect(
          () => task('bad', start: times.$1, end: times.$2),
          throwsArgumentError,
        );
      }
      expect(
        () => TaskEvent(
          id: 'x',
          title: ' ',
          date: DateTime.utc(2026, 10, 6),
          startTime: '10:00',
          endTime: '11:00',
        ),
        throwsArgumentError,
      );
      expect(
        () => TaskEvent(
          id: 'x',
          title: 'x',
          date: DateTime.utc(2026, 10, 6),
          startTime: '10:00',
          endTime: '11:00',
          repeatRule: 'weekly',
        ),
        throwsUnsupportedError,
      );
    },
  );
  test(
    'SQLite also rejects malformed times/dates and false completion values',
    () async {
      for (final args in [
        ['a', 'x', '2026-02-30', '10:00', '11:00', 0],
        ['b', 'x', '2026-10-06', '24:00', '25:00', 0],
        ['c', 'x', '2026-10-06', '10:00', '11:00', 2],
        ['d', 'x', '2026-10-06', '10:00', '09:00', 0],
      ]) {
        await expectLater(
          db.customStatement(
            'INSERT INTO task_events (id,title,event_date,start_time,end_time,completed) VALUES (?,?,?,?,?,?)',
            args,
          ),
          throwsA(anything),
        );
      }
      expect(await tasks.list(), isEmpty);
    },
  );
  test(
    'settings preserve calibration and color, reject invalid replacement atomically',
    () async {
      final imports = DriftImportRepository(db),
          courses = DriftCourseRepository(db);
      final draft = await reviewed(imports);
      final result = await imports.confirmImport(
        draft.id,
        expectedRevision: 2,
        confirmed: true,
      );
      final id = result.semesterId;
      ClassTimeConfig time(int section, String start, String end) =>
          ClassTimeConfig(
            semesterId: id,
            section: section,
            startTime: start,
            endTime: end,
          );
      await settings.replaceClassTimes(id, [
        time(1, '08:00', '08:45'),
        time(2, '08:55', '09:40'),
      ]);
      await settings.setManualWeekOffset(id, 1);
      final course = (await courses.loadSemester(id))!.courses.first;
      await settings.setCourseColor(course.id, '#4386F5');
      final snapshot = (await courses.loadSemester(id))!;
      expect(snapshot.semester.manualWeekOffset, 1);
      expect(
        SemesterWeekCalculator(
          snapshot.semester,
        ).getCurrentWeek(DateTime.utc(2026, 10, 5)),
        7,
      );
      expect(snapshot.courses.first.color, '#4386F5');
      expect(snapshot.classTimes.map((c) => c.startTime), ['08:00', '08:55']);
      for (final times in [
        [time(1, '08:00', '09:00'), time(2, '08:55', '09:40')],
        [time(1, '08:00', '08:45'), time(1, '08:55', '09:40')],
        [
          ClassTimeConfig(
            semesterId: 'other',
            section: 1,
            startTime: '08:00',
            endTime: '08:45',
          ),
        ],
      ]) {
        await expectLater(
          settings.replaceClassTimes(id, times),
          throwsA(isA<RepositoryException>()),
        );
      }
      expect((await courses.loadSemester(id))!.classTimes.length, 2);
      await db.customStatement(
        "CREATE TRIGGER fail_config BEFORE INSERT ON class_times WHEN NEW.section=2 BEGIN SELECT RAISE(ABORT,'test'); END",
      );
      await expectLater(
        settings.replaceClassTimes(id, [
          time(1, '09:00', '09:45'),
          time(2, '09:55', '10:40'),
        ]),
        throwsA(anything),
      );
      expect(
        (await courses.loadSemester(id))!.classTimes.first.startTime,
        '08:00',
      );
    },
  );
}
