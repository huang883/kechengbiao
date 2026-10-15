import 'models.dart';

/// The caller supplies the school-local calendar date, never an unconverted instant.
DateTime _day(DateTime value) =>
    DateTime.utc(value.year, value.month, value.day);

class SemesterWeekCalculator {
  final Semester semester;
  SemesterWeekCalculator(this.semester);
  DateTime get _anchor {
    final start = _day(semester.startDate);
    return start.subtract(
        Duration(days: (start.weekday - semester.weekStartDay + 7) % 7));
  }

  int? getCurrentWeek(DateTime todayDate) => getWeekForDate(todayDate);
  int? getWeekForDate(DateTime date) {
    final day = _day(date);
    if (day.isBefore(_day(semester.startDate)) ||
        day.isAfter(_day(semester.endDate))) {
      return null;
    }
    final week = (day.difference(_anchor).inDays / 7).floor() +
        1 +
        semester.manualWeekOffset;
    return week >= 1 && week <= semester.totalWeeks ? week : null;
  }

  ({DateTime start, DateTime end}) getDateRangeForWeek(int week) {
    if (week < 1 || week > semester.totalWeeks) {
      throw RangeError.range(week, 1, semester.totalWeeks);
    }
    final start =
        _anchor.add(Duration(days: (week - 1 - semester.manualWeekOffset) * 7));
    return (start: start, end: start.add(const Duration(days: 6)));
  }
}

String replacementLabel(Semester semester, ClassDayReplacement replacement) {
  final week =
      SemesterWeekCalculator(semester).getWeekForDate(replacement.sourceDate);
  return '由第 $week 周星期${'一二三四五六日'[replacement.sourceDate.weekday - 1]}（${replacement.sourceDate.month}/${replacement.sourceDate.day}）调入';
}

String sectionLabel(int start, int end) =>
    start == end ? '第 $start 节' : '第 $start—$end 节';
String lessonTransferLabel(Semester semester, LessonTransfer t) =>
    '由第 ${SemesterWeekCalculator(semester).getWeekForDate(t.sourceDate)} 周星期${'一二三四五六日'[t.sourceDate.weekday - 1]}${sectionLabel(t.sourceStart, t.sourceEnd)}（${t.sourceDate.month}/${t.sourceDate.day}）调入';

class CourseFilterService {
  final Semester semester;
  final List<CourseSchedule> schedules;
  final Set<DateTime> _daysOff;
  final List<LessonTransfer> lessonTransfers;
  final Map<DateTime, DateTime> _replacements;
  CourseFilterService(this.semester, List<CourseSchedule> schedules,
      {List<ClassDayOff> daysOff = const [],
      List<ClassDayReplacement> replacements = const [],
      this.lessonTransfers = const []})
      : schedules = List.unmodifiable(schedules),
        _daysOff = daysOff.map((d) => _day(d.date)).toSet(),
        _replacements = {
          for (final r in replacements) _day(r.targetDate): _day(r.sourceDate)
        } {
    if (schedules
        .where((s) => s.semesterId == semester.id)
        .any((s) => s.activeWeeks.any((w) => w > semester.totalWeeks))) {
      throw ArgumentError('Active week exceeds semester totalWeeks');
    }
  }
  List<CourseSchedule> getCoursesForWeek(int week) {
    if (week < 1 || week > semester.totalWeeks) return [];
    final range = SemesterWeekCalculator(semester).getDateRangeForWeek(week);
    return [
      for (var i = 0; i < 7; i++)
        ...getCoursesForDate(range.start.add(Duration(days: i)))
    ];
  }

  CourseSchedule _copy(CourseSchedule s, DateTime date, int start, int end,
          {String? id,
          String? label,
          bool transferred = false,
          String? startTime,
          String? endTime,
          String? classroom}) =>
      CourseSchedule(
          id: id ?? '${s.id}:$start-$end',
          courseId: s.courseId,
          semesterId: s.semesterId,
          weekday: date.weekday,
          startSection: start,
          endSection: end,
          classroom: classroom ?? s.classroom,
          customStartTime: transferred ? startTime : s.customStartTime,
          customEndTime: transferred ? endTime : s.customEndTime,
          activeWeeks: s.activeWeeks,
          remark: s.remark,
          originalScheduleId: s.originalScheduleId ?? s.id,
          adjustmentLabel: label ?? s.adjustmentLabel);

  List<CourseSchedule> _cut(
      List<CourseSchedule> rules, DateTime date, int start, int end,
      {String? scheduleId}) {
    final result = <CourseSchedule>[];
    for (final s in rules) {
      if (s.customStartTime != null) {
        // A single minute-based interval has no internal bell boundaries.
        // Keep it intact unless this move consumes its entire nominal range.
        final consumesWhole = scheduleId != null &&
            (s.originalScheduleId ?? s.id) == scheduleId &&
            start <= s.startSection &&
            end >= s.endSection;
        if (!consumesWhole) result.add(s);
        continue;
      }
      if ((scheduleId != null &&
              (s.originalScheduleId ?? s.id) != scheduleId) ||
          s.endSection < start ||
          s.startSection > end) {
        result.add(s);
        continue;
      }
      if (s.startSection < start) {
        result.add(_copy(s, date, s.startSection, start - 1));
      }
      if (s.endSection > end) result.add(_copy(s, date, end + 1, s.endSection));
    }
    return result;
  }

  List<CourseSchedule> getCoursesForDate(DateTime date) {
    final target = _day(date), calculator = SemesterWeekCalculator(semester);
    if (calculator.getWeekForDate(target) == null) return [];
    final source = _replacements[target];
    List<CourseSchedule> original(DateTime day) {
      final week = calculator.getWeekForDate(day);
      if (week == null) return [];
      return schedules
          .where((s) =>
              s.semesterId == semester.id &&
              s.weekday == day.weekday &&
              s.activeWeeks.contains(week))
          .toList();
    }

    // Normal lessons remain intact even when a day or single lesson is moved here.
    var result =
        _daysOff.contains(target) ? <CourseSchedule>[] : original(target);
    for (final t in lessonTransfers
        .where((t) => t.sourceDate == target && !t.keepSource)) {
      result = _cut(result, target, t.sourceStart, t.sourceEnd,
          scheduleId: t.scheduleId);
    }
    if (source != null) {
      for (final s in original(source)) {
        result.add(_copy(s, target, s.startSection, s.endSection,
            id: 'day-transfer:${target.toIso8601String()}:${s.id}',
            label: replacementLabel(semester,
                ClassDayReplacement(sourceDate: source, targetDate: target))));
      }
    }
    for (final t in lessonTransfers.where((t) => t.targetDate == target)) {
      final rule = schedules
          .where((s) => s.id == t.scheduleId && s.semesterId == semester.id)
          .firstOrNull;
      if (rule == null) continue;
      // Moving into an occupied slot is a visible conflict, never a deletion.
      result.add(_copy(rule, target, t.targetStart, t.targetEnd,
          id: 'transfer:${t.id}',
          label: lessonTransferLabel(semester, t),
          transferred: true,
          startTime: t.targetStartTime,
          endTime: t.targetEndTime,
          classroom: t.targetClassroom));
    }
    return result
      ..sort((a, b) {
        final n = a.startSection.compareTo(b.startSection);
        return n == 0 ? a.id.compareTo(b.id) : n;
      });
  }
}
