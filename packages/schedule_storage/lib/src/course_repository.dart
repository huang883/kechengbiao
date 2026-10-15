import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:schedule_core/schedule_core.dart';
import 'database.dart' show ScheduleDatabase;
import 'codec.dart';

class DriftCourseRepository implements CourseRepository {
  final ScheduleDatabase _db;
  DriftCourseRepository(this._db);

  Semester _semester(QueryRow row) => Semester(
    id: row.read<String>('id'),
    name: row.read<String>('name'),
    startDate: DateTime.parse('${row.read<String>('start_date')}T00:00:00Z'),
    endDate: DateTime.parse('${row.read<String>('end_date')}T00:00:00Z'),
    totalWeeks: row.read<int>('total_weeks'),
    weekStartDay: row.read<int>('week_start_day'),
    manualWeekOffset: row.read<int>('manual_week_offset'),
  );

  @override
  Future<List<Semester>> listSemesters() async => (await rows(
    _db,
    'SELECT * FROM semesters ORDER BY start_date,id',
  )).map(_semester).toList();

  @override
  Future<SemesterSnapshot?> loadSemester(
    String id,
  ) => _db.transaction(() async {
    final semesters = await rows(_db, 'SELECT * FROM semesters WHERE id=?', [
      id,
    ]);
    if (semesters.isEmpty) return null;
    final courseRows = await rows(
      _db,
      '''SELECT DISTINCT c.* FROM courses c
      JOIN course_schedules s ON c.id=s.course_id WHERE s.semester_id=? ORDER BY c.id''',
      [id],
    );
    final scheduleRows = await rows(
      _db,
      '''SELECT s.*, t.start_time AS custom_start, t.end_time AS custom_end FROM course_schedules s
      LEFT JOIN course_schedule_times t ON t.schedule_id=s.id WHERE s.semester_id=?
      ORDER BY s.weekday,s.start_section,s.id''',
      [id],
    );
    final weeks = await rows(
      _db,
      '''SELECT w.* FROM schedule_weeks w JOIN course_schedules s
      ON s.id=w.schedule_id WHERE s.semester_id=? ORDER BY w.active_week''',
      [id],
    );
    final weekMap = <String, List<int>>{};
    for (final w in weeks) {
      weekMap
          .putIfAbsent(w.read<String>('schedule_id'), () => [])
          .add(w.read<int>('active_week'));
    }
    final times = await rows(
      _db,
      'SELECT * FROM class_times WHERE semester_id=? ORDER BY section',
      [id],
    );
    final off = await rows(
      _db,
      'SELECT day,reason FROM class_days_off WHERE semester_id=? ORDER BY day',
      [id],
    );
    final replacements = await rows(
      _db,
      'SELECT source_day,target_day FROM class_day_replacements WHERE semester_id=? ORDER BY target_day',
      [id],
    );
    final transfers = await rows(
      _db,
      'SELECT t.*, e.end_section AS edited_end,e.start_time AS edited_start_time,e.end_time AS edited_end_time,e.classroom AS edited_classroom FROM lesson_transfers t LEFT JOIN lesson_transfer_edits e ON e.transfer_id=t.id WHERE t.semester_id=? ORDER BY t.target_day,t.target_start,t.id',
      [id],
    );
    return SemesterSnapshot(
      lessonTransfers: transfers
          .map(
            (r) => LessonTransfer(
              id: r.read<String>('id'),
              scheduleId: r.read<String>('schedule_id'),
              sourceDate: DateTime.parse(r.read<String>('source_day')),
              targetDate: DateTime.parse(r.read<String>('target_day')),
              sourceStart: r.read<int>('source_start'),
              sourceEnd: r.read<int>('source_end'),
              targetStart: r.read<int>('target_start'),
              keepSource: r.read<int>('keep_source') == 1,
              editedTargetEnd: r.readNullable<int>('edited_end'),
              targetStartTime: r.readNullable<String>('edited_start_time'),
              targetEndTime: r.readNullable<String>('edited_end_time'),
              targetClassroom: r.readNullable<String>('edited_classroom'),
            ),
          )
          .toList(),
      replacements: replacements
          .map(
            (r) => ClassDayReplacement(
              sourceDate: DateTime.parse(
                '${r.read<String>('source_day')}T00:00:00Z',
              ),
              targetDate: DateTime.parse(
                '${r.read<String>('target_day')}T00:00:00Z',
              ),
            ),
          )
          .toList(),
      daysOff: off
          .map(
            (r) => ClassDayOff(
              date: DateTime.parse('${r.read<String>("day")}T00:00:00Z'),
              reason: r.read<String>("reason"),
            ),
          )
          .toList(),
      semester: _semester(semesters.single),
      courses: courseRows
          .map(
            (r) => Course(
              id: r.read<String>('id'),
              name: r.read<String>('name'),
              teacher: r.read<String>('teacher'),
              color: r.read<String>('color'),
              remark: r.read<String>('remark'),
            ),
          )
          .toList(),
      schedules: scheduleRows
          .map(
            (r) => CourseSchedule(
              id: r.read<String>('id'),
              courseId: r.read<String>('course_id'),
              customStartTime: r.readNullable<String>('custom_start'),
              customEndTime: r.readNullable<String>('custom_end'),
              semesterId: id,
              weekday: r.read<int>('weekday'),
              startSection: r.read<int>('start_section'),
              endSection: r.read<int>('end_section'),
              classroom: r.read<String>('classroom'),
              remark: r.read<String>('remark'),
              activeWeeks: weekMap[r.read<String>('id')] ?? [],
            ),
          )
          .toList(),
      classTimes: times
          .map(
            (r) => ClassTimeConfig(
              semesterId: id,
              section: r.read<int>('section'),
              startTime: r.read<String>('start_time'),
              endTime: r.read<String>('end_time'),
            ),
          )
          .toList(),
    );
  });

  @override
  Stream<SemesterSnapshot?> watchSemester(String id) => _db
      .customSelect(
        'SELECT id FROM semesters WHERE id=?',
        variables: [Variable<String>(id)],
        readsFrom: {
          _db.semesters,
          _db.courses,
          _db.courseSchedules,
          _db.courseScheduleTimes,
          _db.scheduleWeeks,
          _db.classTimes,
          _db.classDaysOff,
          _db.classDayReplacements,
          _db.lessonTransfers,
          _db.lessonTransferEdits,
        },
      )
      .watch()
      .asyncMap((_) => loadSemester(id));

  @override
  Future<List<ImportRecordMetadata>> readMetadata(String semesterId) async =>
      (await rows(
            _db,
            '''SELECT m.* FROM import_record_metadata m JOIN course_schedules s
      ON m.schedule_id=s.id WHERE s.semester_id=? ORDER BY m.schedule_id''',
            [semesterId],
          ))
          .map(
            (r) => ImportRecordMetadata(
              scheduleId: r.read<String>('schedule_id'),
              recordId: r.read<String>('record_id'),
              teachingClass: r.read<String>('teaching_class'),
              draftRevision: r.read<int>('draft_revision'),
              totalHours: r.readNullable<int>('total_hours'),
              credits: r.readNullable<int>('credits'),
              source:
                  jsonDecode(r.read<String>('source_json'))
                      as Map<String, dynamic>,
            ),
          )
          .toList();
}
