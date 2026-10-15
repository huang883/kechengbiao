import 'package:schedule_core/schedule_core.dart';
import 'package:schedule_storage/schedule_storage.dart';
import 'package:test/test.dart';
import 'support/fixture.dart';

Matcher code(String value) =>
    isA<RepositoryException>().having((e) => e.code, 'code', value);

void main() {
  late ScheduleDatabase db;
  late DriftImportRepository imports;
  late DriftCourseRepository courses;
  setUp(() {
    db = ScheduleDatabase.memory();
    imports = DriftImportRepository(db);
    courses = DriftCourseRepository(db);
  });
  tearDown(() => db.close());

  test(
    'creating and editing a preview never writes official courses',
    () async {
      final draft = await reviewed(imports);
      expect(draft.revision, 2);
      expect(await courses.listSemesters(), isEmpty);
      expect(
        (await db.customSelect('SELECT count(*) AS n FROM courses').getSingle())
            .read<int>('n'),
        0,
      );
      expect((await imports.history(draft.id)).length, 2);
      expect(draft.original.semester['weekStartDay'], unclear);
      expect(draft.original.records.length, 23);
    },
  );
  test(
    'confirmation is required; unresolved and stale drafts cannot commit',
    () async {
      final draft = await imports.createDraft(realPdf());
      await expectLater(
        imports.confirmImport(draft.id, expectedRevision: 1, confirmed: false),
        throwsA(code('confirmationRequired')),
      );
      await expectLater(
        imports.confirmImport(draft.id, expectedRevision: 1, confirmed: true),
        throwsA(code('invalidImport')),
      );
      await imports.editDraft(
        draft.id,
        expectedRevision: 1,
        semesterChanges: {'weekStartDay': 7},
        reason: 'test',
      );
      await expectLater(
        imports.confirmImport(draft.id, expectedRevision: 1, confirmed: true),
        throwsA(code('staleRevision')),
      );
      await expectLater(
        imports.confirmImport(draft.id, expectedRevision: 2, confirmed: true),
        throwsA(code('invalidImport')),
      );
      expect(await courses.listSemesters(), isEmpty);
    },
  );
  test(
    'real fixture commits 14 courses / 22 schedules and exact metadata',
    () async {
      final draft = await reviewed(imports);
      final result = await imports.confirmImport(
        draft.id,
        expectedRevision: 2,
        confirmed: true,
      );
      expect(result.courseCount, 14);
      expect(result.scheduleCount, 22);
      final snapshot = (await courses.loadSemester(result.semesterId))!;
      expect(snapshot.courses.length, 14);
      expect(snapshot.schedules.length, 22);
      // Every original rule must survive SQLite normalization, not only counts.
      for (final original in realPdf().projectResolvedRecords().schedules) {
        final stored = snapshot.schedules.singleWhere(
          (s) => s.id.endsWith('_${original.id}'),
        );
        expect(stored.activeWeeks, original.activeWeeks);
        expect(stored.weekday, original.weekday);
        expect(stored.startSection, original.startSection);
        expect(stored.endSection, original.endSection);
        expect(stored.classroom, original.classroom);
        expect(stored.remark, original.remark);
      }
      final filter = CourseFilterService(snapshot.semester, snapshot.schedules);
      expect(filter.getCoursesForWeek(11), isEmpty);
      expect(filter.getCoursesForWeek(12).length, 14);
      expect(filter.getCoursesForDate(DateTime.utc(2026, 11, 16)).length, 3);
      final id = snapshot.courses.singleWhere((c) => c.name == '数字逻辑与数字电路B').id;
      expect(
        filter
            .getCoursesForWeek(13)
            .singleWhere((s) => s.courseId == id)
            .classroom,
        contains('信息220'),
      );
      expect(
        filter
            .getCoursesForWeek(14)
            .singleWhere((s) => s.courseId == id)
            .classroom,
        contains('信息321'),
      );
      final meta = await courses.readMetadata(result.semesterId);
      expect(meta.length, 22);
      final first = meta.singleWhere(
        (m) => m.recordId == realPdf().records.first.id,
      );
      expect(first.source, realPdf().records.first.source);
      expect(
        first.teachingClass,
        realPdf().records.first.fields['teachingClass'],
      );
      expect(first.totalHours, 64);
      expect(first.credits, isNull);
      expect(first.draftRevision, 2);
      expect(snapshot.classTimes, isEmpty);
    },
  );
  test(
    'duplicate/concurrent confirmation is idempotent; committed draft is frozen',
    () async {
      final draft = await reviewed(imports);
      final results = await Future.wait([
        for (var i = 0; i < 2; i++)
          imports.confirmImport(draft.id, expectedRevision: 2, confirmed: true),
      ]);
      expect(results.map((r) => r.semesterId).toSet().length, 1);
      expect(results.where((r) => r.alreadyCommitted).length, 1);
      expect((await courses.listSemesters()).length, 1);
      await expectLater(
        imports.editDraft(draft.id, expectedRevision: 2, reason: 'change'),
        throwsA(code('alreadyCommitted')),
      );
      expect((await imports.createDraft(realPdf())).committed, isTrue);
      await expectLater(
        imports.confirmImport(draft.id, expectedRevision: 2, confirmed: false),
        throwsA(code('confirmationRequired')),
      );
    },
  );
  test('concurrent edits allow exactly one revision winner', () async {
    final draft = await imports.createDraft(realPdf());
    final results = await Future.wait([
      for (final day in [1, 7])
        imports
            .editDraft(
              draft.id,
              expectedRevision: 1,
              semesterChanges: {'weekStartDay': day},
              reason: 'test',
            )
            .then<Object>((d) => d)
            .catchError((Object e) => e),
    ]);
    expect(results.whereType<ImportDraft>().length, 1);
    expect(
      results.whereType<RepositoryException>().single.code,
      'staleRevision',
    );
  });
  test(
    'failure late in transaction rolls back every official table and retry succeeds',
    () async {
      final draft = await reviewed(imports);
      await db.customStatement(
        "CREATE TRIGGER injected_failure BEFORE INSERT ON import_commits BEGIN SELECT RAISE(ABORT, 'simulated disk write failure'); END",
      );
      await expectLater(
        imports.confirmImport(draft.id, expectedRevision: 2, confirmed: true),
        throwsA(anything),
      );
      for (final table in [
        'semesters',
        'courses',
        'course_schedules',
        'schedule_weeks',
        'import_record_metadata',
        'import_commits',
      ]) {
        expect(
          (await db
                  .customSelect('SELECT count(*) AS n FROM $table')
                  .getSingle())
              .read<int>('n'),
          0,
          reason: table,
        );
      }
      expect((await imports.readDraft(draft.id))!.committed, isFalse);
      await db.customStatement('DROP TRIGGER injected_failure');
      expect(
        (await imports.confirmImport(
          draft.id,
          expectedRevision: 2,
          confirmed: true,
        )).scheduleCount,
        22,
      );
    },
  );
  test(
    'record corrections preserve originals and cannot silently discard records',
    () async {
      final draft = await reviewed(imports);
      final recordId = draft.reviewed.records.first.id;
      final corrected = await imports.editDraft(
        draft.id,
        expectedRevision: 2,
        recordChanges: {
          recordId: {'classroom': '[测试]校正教室', 'weekExpression': '2周,4周'},
        },
        reason: '修正排课',
      );
      expect(corrected.reviewed.records.first.fields['activeWeeks'], [2, 4]);
      expect(
        corrected.original.records.first.fields['classroom'],
        contains('实验312'),
      );
      final result = await imports.confirmImport(
        draft.id,
        expectedRevision: 3,
        confirmed: true,
      );
      expect(
        (await courses.loadSemester(
          result.semesterId,
        ))!.schedules.singleWhere((s) => s.id.endsWith(recordId)).activeWeeks,
        [2, 4],
      );
    },
  );
  test(
    'invalid edits/exclusions are rejected without advancing revision',
    () async {
      final draft = await imports.createDraft(realPdf());
      for (final exclusion in [
        {'not_a_record': 'reason'},
        {'other_1': ''},
      ]) {
        await expectLater(
          imports.editDraft(
            draft.id,
            expectedRevision: 1,
            exclusions: exclusion,
            reason: 'test',
          ),
          throwsA(code('invalidEdit')),
        );
      }
      await expectLater(
        imports.editDraft(
          draft.id,
          expectedRevision: 1,
          recordChanges: {
            'missing': {'name': 'X'},
          },
          reason: 'test',
        ),
        throwsA(code('invalidEdit')),
      );
      await expectLater(
        imports.editDraft(
          draft.id,
          expectedRevision: 1,
          semesterChanges: {'sourceSha256': 'X'},
          reason: 'test',
        ),
        throwsA(code('invalidEdit')),
      );
      expect((await imports.readDraft(draft.id))!.revision, 1);
    },
  );
  test(
    'foreign keys, duplicate weeks and out of semester weeks are rejected by SQLite',
    () async {
      final draft = await reviewed(imports);
      final result = await imports.confirmImport(
        draft.id,
        expectedRevision: 2,
        confirmed: true,
      );
      final s = (await courses.loadSemester(
        result.semesterId,
      ))!.schedules.first;
      for (final args in [
        [s.id, s.activeWeeks.first],
        [s.id, 21],
        ['missing', 1],
      ]) {
        await expectLater(
          db.customStatement('INSERT INTO schedule_weeks VALUES (?,?)', args),
          throwsA(anything),
        );
      }
      await expectLater(
        db.customStatement('UPDATE semesters SET total_weeks=1 WHERE id=?', [
          result.semesterId,
        ]),
        throwsA(anything),
      );
      expect(await db.customSelect('PRAGMA foreign_key_check').get(), isEmpty);
    },
  );
  test('watchSemester emits complete committed snapshot', () async {
    final draft = await reviewed(imports);
    final id = 'semester_${draft.id}';
    final streamExpectation = expectLater(
      courses.watchSemester(id).take(2),
      emitsInOrder([
        isNull,
        isA<SemesterSnapshot>().having((s) => s.schedules.length, 'rules', 22),
      ]),
    );
    // Await the initial query, not an arbitrary delay.
    await courses.watchSemester(id).first;
    await imports.confirmImport(draft.id, expectedRevision: 2, confirmed: true);
    await streamExpectation;
  });

  test(
    'different source PDFs keep namespaced IDs and never overwrite each other',
    () async {
      final first = await reviewed(imports);
      final one = await imports.confirmImport(
        first.id,
        expectedRevision: 2,
        confirmed: true,
      );
      final parsed = realPdf();
      final second = await imports.createDraft(
        ParsedSchedule('a' * 64, parsed.semester, parsed.records),
      );
      await imports.editDraft(
        second.id,
        expectedRevision: 1,
        semesterChanges: {'weekStartDay': 1},
        exclusions: {'other_1': 'explicit exclusion'},
        reason: 'second source test',
      );
      final two = await imports.confirmImport(
        second.id,
        expectedRevision: 2,
        confirmed: true,
      );
      final s1 = (await courses.loadSemester(one.semesterId))!;
      final s2 = (await courses.loadSemester(two.semesterId))!;
      expect(one.semesterId, isNot(two.semesterId));
      expect(
        s1.courses
            .map((c) => c.id)
            .toSet()
            .intersection(s2.courses.map((c) => c.id).toSet()),
        isEmpty,
      );
      expect(s1.schedules.length, 22);
      expect(s2.schedules.length, 22);
      expect(s1.semester.weekStartDay, 7);
      expect(s2.semester.weekStartDay, 1);
    },
  );
  test('source mismatch cannot replace original evidence', () async {
    final parsed = realPdf();
    final draft = await imports.createDraft(parsed);
    await expectLater(
      imports.createDraft(
        ParsedSchedule(parsed.sourceSha256, {
          ...parsed.semester,
          'name': 'different',
        }, parsed.records),
      ),
      throwsA(code('sourceMismatch')),
    );
    expect(
      (await imports.readDraft(draft.id))!.original.semester['name'],
      parsed.semester['name'],
    );
  });
  test(
    'malformed preview and exclusion of every rule cannot enter official tables',
    () async {
      var draft = await reviewed(imports);
      draft = await imports.editDraft(
        draft.id,
        expectedRevision: draft.revision,
        semesterChanges: {'startDate': '2026-02-30'},
        reason: 'invalid date test',
      );
      await expectLater(
        imports.confirmImport(
          draft.id,
          expectedRevision: draft.revision,
          confirmed: true,
        ),
        throwsA(code('invalidImport')),
      );
      draft = await imports.editDraft(
        draft.id,
        expectedRevision: draft.revision,
        semesterChanges: {'startDate': '2026-08-30'},
        exclusions: {for (final r in draft.reviewed.records) r.id: 'test'},
        reason: 'empty import test',
      );
      await expectLater(
        imports.confirmImport(
          draft.id,
          expectedRevision: draft.revision,
          confirmed: true,
        ),
        throwsA(code('invalidImport')),
      );
      expect(await courses.listSemesters(), isEmpty);
    },
  );
}
