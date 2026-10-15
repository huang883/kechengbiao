import 'dart:convert';
import 'package:schedule_core/schedule_core.dart';
import 'database.dart' show ScheduleDatabase;
import 'codec.dart';

class DriftImportRepository implements ImportRepository {
  final ScheduleDatabase _db;
  DriftImportRepository(this._db);

  @override
  Future<ImportDraft> createDraft(ParsedSchedule parsed) =>
      _db.transaction(() async {
        final hash = parsed.sourceSha256;
        if (!RegExp(r'^[a-f0-9]{64}$').hasMatch(hash) ||
            parsed.records.any((r) => r.id.trim().isEmpty) ||
            parsed.records.map((r) => r.id).toSet().length !=
                parsed.records.length) {
          fail(
            'invalidDraft',
            'Source hash and record IDs must be valid and unique',
          );
        }
        final original = canonicalJson(parsed.toJson());
        final existing = await readDraft(hash);
        if (existing != null) {
          if (canonicalJson(existing.original.toJson()) != original) {
            fail(
              'sourceMismatch',
              'This source already has a different original snapshot',
            );
          }
          return existing;
        }
        await _db.customStatement('INSERT INTO import_drafts VALUES (?,1,?)', [
          hash,
          original,
        ]);
        await _db.customStatement(
          'INSERT INTO import_revisions VALUES (?,1,?,?,?)',
          [hash, original, '{}', 'Initial parsed preview'],
        );
        return (await readDraft(hash))!;
      });

  @override
  Future<ImportDraft?> readDraft(String id) async {
    final result = await rows(
      _db,
      '''SELECT d.source_hash, d.original_json, r.*,
      EXISTS(SELECT 1 FROM import_commits c WHERE c.source_hash=d.source_hash) AS committed
      FROM import_drafts d JOIN import_revisions r
      ON r.source_hash=d.source_hash AND r.revision=d.current_revision WHERE d.source_hash=?''',
      [id],
    );
    return result.isEmpty ? null : _decode(result.single.data);
  }

  ImportDraft _decode(Map<String, dynamic> row) => ImportDraft(
    id: row['source_hash'] as String,
    revision: row['revision'] as int,
    original: decodeParsed(row['original_json'] as String),
    reviewed: decodeParsed(row['reviewed_json'] as String),
    exclusions:
        (jsonDecode(row['exclusions_json'] as String) as Map<String, dynamic>)
            .cast<String, String>(),
    reason: row['reason'] as String,
    committed: row['committed'] == 1,
  );

  @override
  Future<List<ImportDraft>> history(String id) async => (await rows(
    _db,
    '''
    SELECT d.original_json, r.*, EXISTS(SELECT 1 FROM import_commits c
      WHERE c.source_hash=r.source_hash AND c.revision=r.revision) AS committed
    FROM import_drafts d JOIN import_revisions r ON r.source_hash=d.source_hash
    WHERE d.source_hash=? ORDER BY r.revision''',
    [id],
  )).map((r) => _decode(r.data)).toList();

  @override
  Future<ImportDraft> editDraft(
    String id, {
    required int expectedRevision,
    Map<String, dynamic> semesterChanges = const {},
    Map<String, Map<String, dynamic>> recordChanges = const {},
    Map<String, String>? exclusions,
    required String reason,
  }) => _db.transaction(() async {
    final draft = await _latest(id, expectedRevision);
    if (draft.committed) {
      fail(
        'alreadyCommitted',
        'Committed previews are immutable; reconciliation is not yet supported',
      );
    }
    const semesterKeys = {
      'name',
      'startDate',
      'endDate',
      'totalWeeks',
      'weekStartDay',
      'manualWeekOffset',
    };
    const recordKeys = {
      'name',
      'teacher',
      'teachingClass',
      'classroom',
      'weekday',
      'startSection',
      'endSection',
      'weekExpression',
      'remark',
      'totalHours',
      'credits',
    };
    final recordIds = draft.reviewed.records.map((r) => r.id).toSet();
    final excluded = exclusions ?? draft.exclusions;
    if (reason.trim().isEmpty ||
        semesterChanges.keys.any((k) => !semesterKeys.contains(k)) ||
        recordChanges.keys.any((k) => !recordIds.contains(k)) ||
        recordChanges.values.any(
          (v) => v.keys.any((k) => !recordKeys.contains(k)),
        ) ||
        excluded.entries.any(
          (e) => !recordIds.contains(e.key) || e.value.trim().isEmpty,
        )) {
      fail(
        'invalidEdit',
        'Invalid field, unknown record or missing audit reason',
      );
    }
    final records = draft.reviewed.records.map((r) {
      final change = recordChanges[r.id] ?? const <String, dynamic>{};
      final fields = {...r.fields, ...change};
      if (change.containsKey('weekExpression')) {
        final expression = change['weekExpression'];
        if (expression is! String || expression.contains('节')) {
          fail('invalidEdit', 'Edit sections separately from weekExpression');
        }
        try {
          fields['activeWeeks'] = WeekExpressionParser().parse(expression);
        } on FormatException {
          fields['activeWeeks'] = unclear;
        }
      }
      return ParsedCourseRecord(r.id, fields, r.source);
    }).toList();
    final edited = ParsedSchedule(id, {
      ...draft.reviewed.semester,
      ...semesterChanges,
    }, records);
    final revision = draft.revision + 1;
    await _db
        .customStatement('INSERT INTO import_revisions VALUES (?,?,?,?,?)', [
          id,
          revision,
          canonicalJson(edited.toJson()),
          canonicalJson(excluded),
          reason,
        ]);
    await _db.customStatement(
      'UPDATE import_drafts SET current_revision=? WHERE source_hash=? AND current_revision=?',
      [revision, id, expectedRevision],
    );
    return (await readDraft(id))!;
  });

  Future<ImportDraft> _latest(String id, int expectedRevision) async {
    final draft = await readDraft(id);
    if (draft == null) fail('notFound', 'Import draft does not exist');
    if (draft.revision != expectedRevision) {
      fail('staleRevision', 'Preview changed; reload it before continuing');
    }
    return draft;
  }

  ParsedSchedule _validate(ImportDraft draft) {
    final effective = ParsedSchedule(
      draft.id,
      draft.reviewed.semester,
      draft.reviewed.records
          .where((r) => !draft.exclusions.containsKey(r.id))
          .toList(),
    );
    try {
      final errors = ImportValidation()
          .validate(effective)
          .where((i) => i.severity == 'error');
      if (errors.isNotEmpty) {
        fail('invalidImport', errors.map((e) => e.code).join(', '));
      }
      if (effective.records.isEmpty) {
        fail(
          'invalidImport',
          'An import must contain at least one course schedule',
        );
      }
      if (effective.semester['manualWeekOffset'] is! int ||
          effective.semester['name'] is! String ||
          (effective.semester['name'] as String).trim().isEmpty) {
        fail('invalidImport', 'Invalid semester fields');
      }
      for (final r in effective.records) {
        for (final key in [
          'name',
          'teacher',
          'classroom',
          'teachingClass',
          'remark',
        ]) {
          final value = r.fields[key];
          if (value is! String ||
              value == unclear ||
              (key != 'remark' && value.trim().isEmpty)) {
            fail('invalidImport', 'Invalid $key on ${r.id}');
          }
        }
        for (final key in ['credits', 'totalHours']) {
          final value = r.fields[key];
          if (value != unclear && (value is! int || value < 0)) {
            fail('invalidImport', 'Invalid $key on ${r.id}');
          }
        }
      }
      return effective;
    } on RepositoryException {
      rethrow;
    } on Object catch (e) {
      fail('invalidImport', 'Malformed preview fields: $e');
    }
  }

  @override
  Future<ImportResult> confirmImport(
    String id, {
    required int expectedRevision,
    required bool confirmed,
  }) async {
    if (!confirmed) {
      fail('confirmationRequired', 'An explicit user confirmation is required');
    }
    return _db.transaction(() async {
      final draft = await _latest(id, expectedRevision);
      final existing = await rows(
        _db,
        'SELECT * FROM import_commits WHERE source_hash=?',
        [id],
      );
      if (existing.isNotEmpty) {
        final row = existing.single;
        return ImportResult(
          semesterId: row.read<String>('semester_id'),
          revision: row.read<int>('revision'),
          courseCount: row.read<int>('course_count'),
          scheduleCount: row.read<int>('schedule_count'),
          alreadyCommitted: true,
        );
      }
      final effective = _validate(draft);
      final projected = effective.projectResolvedRecords();
      final semesterId = 'semester_$id';
      final s = effective.semester;
      await _db
          .customStatement('INSERT INTO semesters VALUES (?,?,?,?,?,?,?)', [
            semesterId,
            s['name'],
            s['startDate'],
            s['endDate'],
            s['totalWeeks'],
            s['weekStartDay'],
            s['manualWeekOffset'],
          ]);
      for (final course in projected.courses) {
        await _db.customStatement('INSERT INTO courses VALUES (?,?,?,?,?)', [
          '${id}_${course.id}',
          course.name,
          course.teacher,
          course.color,
          course.remark,
        ]);
      }
      final byId = {for (final record in effective.records) record.id: record};
      for (final schedule in projected.schedules) {
        final scheduleId = '${id}_${schedule.id}';
        await _db.customStatement(
          'INSERT INTO course_schedules VALUES (?,?,?,?,?,?,?,?)',
          [
            scheduleId,
            '${id}_${schedule.courseId}',
            semesterId,
            schedule.weekday,
            schedule.startSection,
            schedule.endSection,
            schedule.classroom,
            schedule.remark,
          ],
        );
        for (final week in schedule.activeWeeks) {
          await _db.customStatement('INSERT INTO schedule_weeks VALUES (?,?)', [
            scheduleId,
            week,
          ]);
        }
        final record = byId[schedule.id]!;
        final f = record.fields;
        await _db.customStatement(
          'INSERT INTO import_record_metadata VALUES (?,?,?,?,?,?,?,?)',
          [
            scheduleId,
            id,
            expectedRevision,
            record.id,
            f['teachingClass'],
            f['totalHours'] == unclear ? null : f['totalHours'],
            f['credits'] == unclear ? null : f['credits'],
            canonicalJson(record.source),
          ],
        );
      }
      await _db
          .customStatement('INSERT INTO import_commits VALUES (?,?,?,?,?)', [
            id,
            expectedRevision,
            semesterId,
            projected.courses.length,
            projected.schedules.length,
          ]);
      _db.markTablesUpdated({
        _db.semesters,
        _db.courses,
        _db.courseSchedules,
        _db.scheduleWeeks,
        _db.importRecordMetadata,
      });
      return ImportResult(
        semesterId: semesterId,
        revision: expectedRevision,
        courseCount: projected.courses.length,
        scheduleCount: projected.schedules.length,
        alreadyCommitted: false,
      );
    });
  }
}
