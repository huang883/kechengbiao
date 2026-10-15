import 'package:schedule_core/schedule_core.dart';
import 'database.dart' show ScheduleDatabase;
import 'codec.dart';
import 'course_repository.dart';

class DriftSettingsRepository implements SettingsRepository {
  final ScheduleDatabase _db;
  DriftSettingsRepository(this._db);

  @override
  Future<void> editTransferredCourse(
    String semesterId,
    String transferId,
    Course course,
    CourseSchedule target,
    DateTime targetDate,
  ) async {
    await _db.transaction(() async {
      final snapshot = await DriftCourseRepository(
        _db,
      ).loadSemester(semesterId);
      if (snapshot == null) fail('notFound', 'Semester does not exist');
      final t = snapshot.lessonTransfers
          .where((t) => t.id == transferId)
          .firstOrNull;
      final rule = snapshot.schedules
          .where((s) => s.id == t?.scheduleId)
          .firstOrNull;
      if (t == null ||
          rule == null ||
          rule.courseId != course.id ||
          target.courseId != course.id ||
          target.semesterId != semesterId) {
        fail('notFound', 'Transfer does not exist');
      }
      if (course.name.trim().isEmpty ||
          course.name.trim() == unclear ||
          course.name.trim().length > 100) {
        throw const FormatException('课程名称需为 1—100 个字符');
      }
      if (SemesterWeekCalculator(
            snapshot.semester,
          ).getWeekForDate(targetDate) ==
          null) {
        throw const FormatException('目标日期必须在本学期内');
      }
      final start = target.customStartTime, end = target.customEndTime;
      if ((start == null) != (end == null) ||
          (start != null &&
              (!isClockTime(start) ||
                  !isClockTime(end!) ||
                  start.compareTo(end) >= 0))) {
        throw const FormatException('请检查上课和下课时间');
      }
      if (start == null) {
        final sections = snapshot.classTimes.map((t) => t.section).toSet();
        for (var n = target.startSection; n <= target.endSection; n++) {
          if (!sections.contains(n)) throw const FormatException('请先配置目标节次作息');
        }
        if (dateText(t.sourceDate) == dateText(targetDate) &&
            target.startSection <= t.sourceEnd &&
            target.endSection >= t.sourceStart) {
          throw const FormatException('同一天的来源与目标节次不能重叠');
        }
        for (final other in snapshot.lessonTransfers.where(
          (x) => x.id != t.id,
        )) {
          if (other.targetStartTime == null &&
              dateText(other.targetDate) == dateText(targetDate) &&
              other.targetStart <= target.endSection &&
              other.targetEnd >= target.startSection) {
            throw const FormatException('目标节次已有另一条调课，请选其他节次或自定义钟点');
          }
        }
      }
      await _db.customStatement('UPDATE courses SET name=? WHERE id=?', [
        course.name.trim(),
        course.id,
      ]);
      await _db.customStatement(
        'UPDATE lesson_transfers SET target_day=?,target_start=? WHERE id=?',
        [dateText(targetDate), target.startSection, t.id],
      );
      await _db.customStatement(
        'INSERT INTO lesson_transfer_edits VALUES (?,?,?,?,?) ON CONFLICT(transfer_id) DO UPDATE SET end_section=excluded.end_section,start_time=excluded.start_time,end_time=excluded.end_time,classroom=excluded.classroom',
        [t.id, target.endSection, start, end, target.classroom.trim()],
      );
      _db.markTablesUpdated({
        _db.courses,
        _db.lessonTransfers,
        _db.lessonTransferEdits,
      });
    });
  }

  @override
  Future<void> saveCourseSchedule(
    Course course,
    CourseSchedule schedule, {
    required bool creating,
  }) async {
    final name = course.name.trim();
    if (name.isEmpty || name == unclear || name.length > 100) {
      throw const FormatException('课程名称需为 1—100 个字符');
    }
    final start = schedule.customStartTime, end = schedule.customEndTime;
    if ((start == null) != (end == null) ||
        (start != null &&
            (!isClockTime(start) ||
                !isClockTime(end!) ||
                start.compareTo(end) >= 0))) {
      throw const FormatException('请填写有效的起止钟点，下课时间须晚于上课时间');
    }
    await _db.transaction(() async {
      final snapshot = await DriftCourseRepository(
        _db,
      ).loadSemester(schedule.semesterId);
      if (snapshot == null) fail('notFound', 'Semester does not exist');
      if (schedule.courseId != course.id ||
          schedule.activeWeeks.any((w) => w > snapshot.semester.totalWeeks)) {
        throw const FormatException('课程或周次不属于当前课表');
      }
      final previous = snapshot.schedules
          .where((s) => s.id == schedule.id)
          .firstOrNull;
      if (!creating && (previous == null || previous.courseId != course.id)) {
        fail('notFound', 'Schedule does not exist');
      }
      if (start == null) {
        final sections = snapshot.classTimes.map((t) => t.section).toSet();
        for (var n = schedule.startSection; n <= schedule.endSection; n++) {
          if (!sections.contains(n)) {
            throw const FormatException('请先配置所选节次的作息，或使用自定义钟点');
          }
        }
      }
      if (creating) {
        await _db.customStatement('INSERT INTO courses VALUES (?,?,?,?,?)', [
          course.id,
          name,
          course.teacher,
          course.color,
          course.remark,
        ]);
        await _db.customStatement(
          'INSERT INTO course_schedules VALUES (?,?,?,?,?,?,?,?)',
          [
            schedule.id,
            course.id,
            schedule.semesterId,
            schedule.weekday,
            schedule.startSection,
            schedule.endSection,
            schedule.classroom.trim(),
            schedule.remark,
          ],
        );
      } else {
        await _db.customStatement('UPDATE courses SET name=? WHERE id=?', [
          name,
          course.id,
        ]);
        await _db.customStatement(
          'UPDATE course_schedules SET weekday=?,start_section=?,end_section=?,classroom=? WHERE id=?',
          [
            schedule.weekday,
            schedule.startSection,
            schedule.endSection,
            schedule.classroom.trim(),
            schedule.id,
          ],
        );
        await _db.customStatement(
          'DELETE FROM schedule_weeks WHERE schedule_id=?',
          [schedule.id],
        );
      }
      for (final week in schedule.activeWeeks) {
        await _db.customStatement('INSERT INTO schedule_weeks VALUES (?,?)', [
          schedule.id,
          week,
        ]);
      }
      await _db.customStatement(
        'DELETE FROM course_schedule_times WHERE schedule_id=?',
        [schedule.id],
      );
      if (start != null) {
        await _db.customStatement(
          'INSERT INTO course_schedule_times VALUES (?,?,?)',
          [schedule.id, start, end],
        );
      }
      _db.markTablesUpdated({
        _db.courses,
        _db.courseSchedules,
        _db.scheduleWeeks,
        _db.courseScheduleTimes,
      });
    });
  }

  @override
  Future<void> renameSemester(String semesterId, String name) async {
    final value = name.trim();
    if (value.isEmpty || value.length > 60) {
      throw const FormatException('课表名称需为 1—60 个字符');
    }
    final count = await _db.customUpdate(
      'UPDATE semesters SET name=? WHERE id=?',
      variables: bind([value, semesterId]),
      updates: {_db.semesters},
    );
    if (count == 0) fail('notFound', 'Semester does not exist');
  }

  @override
  Future<void> saveLessonTransfer(String semesterId, LessonTransfer t) async {
    await _db.transaction(() async {
      final snapshot = await DriftCourseRepository(
        _db,
      ).loadSemester(semesterId);
      if (snapshot == null) fail('notFound', 'Semester does not exist');
      final calc = SemesterWeekCalculator(snapshot.semester);
      final week = calc.getWeekForDate(t.sourceDate);
      if (week == null || calc.getWeekForDate(t.targetDate) == null) {
        throw const FormatException('调课日期必须在当前学期有效教学周内');
      }
      final rule = snapshot.schedules
          .where((s) => s.id == t.scheduleId)
          .firstOrNull;
      if (rule == null ||
          rule.weekday != t.sourceDate.weekday ||
          !rule.activeWeeks.contains(week) ||
          t.sourceStart < rule.startSection ||
          t.sourceEnd > rule.endSection) {
        throw const FormatException('所选来源日期和节次没有这门课');
      }
      if (rule.customStartTime != null) {
        throw const FormatException('该课程使用自定义钟点，请直接编辑课程时间；按节调课前需先恢复节次模式');
      }
      final sections = snapshot.classTimes.map((c) => c.section).toSet();
      for (var n = t.targetStart; n <= t.targetEnd; n++) {
        if (!sections.contains(n)) {
          throw const FormatException('请先在学校上课时间中配置目标节次');
        }
      }
      for (final other in snapshot.lessonTransfers.where((x) => x.id != t.id)) {
        if (other.targetDate == t.targetDate &&
            other.targetStart <= t.targetEnd &&
            other.targetEnd >= t.targetStart) {
          throw const FormatException('目标节次已有单节调课，请先撤销或修改那条调课');
        }
        if (other.sourceDate == t.sourceDate &&
            other.scheduleId == t.scheduleId &&
            other.sourceStart <= t.sourceEnd &&
            other.sourceEnd >= t.sourceStart) {
          throw const FormatException('来源节次已有单节调课，请先撤销或修改那条调课');
        }
      }
      await _db.customStatement(
        'INSERT INTO lesson_transfers (id,semester_id,schedule_id,source_day,target_day,source_start,source_end,target_start,keep_source) VALUES (?,?,?,?,?,?,?,?,?) ON CONFLICT(id) DO UPDATE SET schedule_id=excluded.schedule_id,source_day=excluded.source_day,target_day=excluded.target_day,source_start=excluded.source_start,source_end=excluded.source_end,target_start=excluded.target_start,keep_source=excluded.keep_source',
        [
          t.id,
          semesterId,
          t.scheduleId,
          dateText(t.sourceDate),
          dateText(t.targetDate),
          t.sourceStart,
          t.sourceEnd,
          t.targetStart,
          t.keepSource ? 1 : 0,
        ],
      );
      await _db.customStatement(
        'DELETE FROM lesson_transfer_edits WHERE transfer_id=?',
        [t.id],
      );
      _db.markTablesUpdated({_db.lessonTransfers, _db.lessonTransferEdits});
    });
  }

  @override
  Future<void> deleteLessonTransfer(String semesterId, String id) async {
    await _db.customUpdate(
      'DELETE FROM lesson_transfers WHERE semester_id=? AND id=?',
      variables: bind([semesterId, id]),
      updates: {_db.lessonTransfers},
    );
  }

  @override
  Future<void> saveReplacement(
    String semesterId,
    ClassDayReplacement replacement,
  ) async {
    await _db.transaction(() async {
      final data = await rows(_db, 'SELECT * FROM semesters WHERE id=?', [
        semesterId,
      ]);
      if (data.isEmpty) fail('notFound', 'Semester does not exist');
      final row = data.single;
      final semester = Semester(
        id: semesterId,
        name: row.read<String>('name'),
        startDate: DateTime.parse(row.read<String>('start_date')),
        endDate: DateTime.parse(row.read<String>('end_date')),
        totalWeeks: row.read<int>('total_weeks'),
        weekStartDay: row.read<int>('week_start_day'),
        manualWeekOffset: row.read<int>('manual_week_offset'),
      );
      final calc = SemesterWeekCalculator(semester);
      if (calc.getWeekForDate(replacement.sourceDate) == null ||
          calc.getWeekForDate(replacement.targetDate) == null) {
        throw const FormatException('来源和目标日期必须在当前学期的有效教学周内');
      }
      await _db.customStatement(
        'INSERT INTO class_day_replacements (semester_id,target_day,source_day) VALUES (?,?,?) ON CONFLICT(semester_id,target_day) DO UPDATE SET source_day=excluded.source_day',
        [
          semesterId,
          dateText(replacement.targetDate),
          dateText(replacement.sourceDate),
        ],
      );
      _db.markTablesUpdated({_db.classDayReplacements});
    });
  }

  @override
  Future<void> deleteReplacement(String semesterId, DateTime targetDate) async {
    await _db.customUpdate(
      'DELETE FROM class_day_replacements WHERE semester_id=? AND target_day=?',
      variables: bind([semesterId, dateText(targetDate)]),
      updates: {_db.classDayReplacements},
    );
  }

  @override
  Future<void> updateSemesterCalendar(
    String semesterId, {
    required DateTime firstWeekStart,
    required int weekStartDay,
  }) async {
    if (weekStartDay < 1 ||
        weekStartDay > 7 ||
        firstWeekStart.weekday != weekStartDay) {
      throw const FormatException('第一周起始日期必须与周起始日一致');
    }
    await _db.transaction(() async {
      final existing = await rows(
        _db,
        'SELECT end_date FROM semesters WHERE id=?',
        [semesterId],
      );
      if (existing.isEmpty) fail('notFound', 'Semester does not exist');
      final start = dateText(firstWeekStart);
      if (start.compareTo(existing.single.read<String>('end_date')) > 0) {
        throw const FormatException('第一周起始日期不能晚于学期结束日期');
      }
      final outside = await rows(
        _db,
        'SELECT day FROM class_days_off WHERE semester_id=? AND day<?',
        [semesterId, start],
      );
      final replacementOutside = await rows(
        _db,
        'SELECT target_day FROM class_day_replacements WHERE semester_id=? AND (source_day<? OR target_day<?)',
        [semesterId, start, start],
      );
      final lessonOutside = await rows(
        _db,
        'SELECT id FROM lesson_transfers WHERE semester_id=? AND (source_day<? OR target_day<?)',
        [semesterId, start, start],
      );
      if (replacementOutside.isNotEmpty || lessonOutside.isNotEmpty) {
        throw const FormatException('已有调课早于新的学期起点，请先撤销调课');
      }
      if (outside.isNotEmpty) {
        throw const FormatException('已有停课日期早于新的学期起点，请先调整停课日期');
      }
      await _db.customUpdate(
        'UPDATE semesters SET start_date=?,week_start_day=?,manual_week_offset=0 WHERE id=?',
        variables: bind([start, weekStartDay, semesterId]),
        updates: {_db.semesters},
      );
    });
  }

  @override
  Future<void> saveDayOff(String semesterId, ClassDayOff day) async {
    await _db.transaction(() async {
      final semester = await rows(
        _db,
        'SELECT start_date,end_date FROM semesters WHERE id=?',
        [semesterId],
      );
      if (semester.isEmpty) fail('notFound', 'Semester does not exist');
      final date = dateText(day.date), row = semester.single;
      if (date.compareTo(row.read<String>('start_date')) < 0 ||
          date.compareTo(row.read<String>('end_date')) > 0) {
        throw const FormatException('停课日期必须在当前学期内');
      }
      await _db.customStatement(
        'INSERT INTO class_days_off (semester_id,day,reason) VALUES (?,?,?) ON CONFLICT(semester_id,day) DO UPDATE SET reason=excluded.reason',
        [semesterId, date, day.reason],
      );
      _db.markTablesUpdated({_db.classDaysOff});
    });
  }

  @override
  Future<void> deleteDayOff(String semesterId, DateTime date) async {
    await _db.customUpdate(
      'DELETE FROM class_days_off WHERE semester_id=? AND day=?',
      variables: bind([semesterId, dateText(date)]),
      updates: {_db.classDaysOff},
    );
  }

  @override
  Future<void> replaceClassTimes(
    String semesterId,
    List<ClassTimeConfig> times,
  ) async {
    final sorted = [...times]..sort((a, b) => a.section.compareTo(b.section));
    if (sorted.any((time) => time.semesterId != semesterId)) {
      fail('invalidClassTimes', 'Class time belongs to a different semester');
    }
    for (var i = 1; i < sorted.length; i++) {
      if (sorted[i - 1].section == sorted[i].section ||
          sorted[i - 1].endTime.compareTo(sorted[i].startTime) > 0) {
        fail(
          'invalidClassTimes',
          'Section times must be unique and chronological without overlap',
        );
      }
    }
    await _db.transaction(() async {
      if ((await rows(_db, 'SELECT id FROM semesters WHERE id=?', [
        semesterId,
      ])).isEmpty) {
        fail('notFound', 'Semester does not exist');
      }
      await _db.customStatement('DELETE FROM class_times WHERE semester_id=?', [
        semesterId,
      ]);
      for (final time in sorted) {
        await _db.customStatement('INSERT INTO class_times VALUES (?,?,?,?)', [
          semesterId,
          time.section,
          time.startTime,
          time.endTime,
        ]);
      }
      _db.markTablesUpdated({_db.classTimes});
    });
  }

  @override
  Future<void> setManualWeekOffset(String semesterId, int offset) async {
    final count = await _db.customUpdate(
      'UPDATE semesters SET manual_week_offset=? WHERE id=?',
      variables: bind([offset, semesterId]),
      updates: {_db.semesters},
    );
    if (count == 0) fail('notFound', 'Semester does not exist');
  }

  @override
  Future<void> setCourseColor(String courseId, String color) async {
    if (color.trim().isEmpty) fail('invalidColor', 'Color must not be empty');
    final count = await _db.customUpdate(
      'UPDATE courses SET color=? WHERE id=?',
      variables: bind([color, courseId]),
      updates: {_db.courses},
    );
    if (count == 0) fail('notFound', 'Course does not exist');
  }
}
