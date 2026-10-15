import 'dart:convert';
import 'dart:io';
import 'package:schedule_core/schedule_core.dart';
import 'package:test/test.dart';

void main() {
  final parsed = PdfScheduleParser().parse(
      jsonDecode(File('../../apps/campus_time/assets/default_timetable.json').readAsStringSync())
          as Map<String, dynamic>);
  final projection = parsed.projectResolvedRecords();
  final semester = Semester(
      id: 'semester_1',
      name: 'School',
      startDate: DateTime.utc(2026, 8, 31),
      endDate: DateTime.utc(2027, 1, 16),
      totalWeeks: 20,
      weekStartDay: 1);
  final off = [
    ClassDayOff(date: DateTime.utc(2026, 9, 25), reason: '中秋节'),
    ClassDayOff(date: DateTime.utc(2026, 10, 1), reason: '国庆节')
  ];
  test(
      'Monday first week stays aligned and holidays reduce only the affected week',
      () {
    final calc = SemesterWeekCalculator(semester);
    expect(calc.getWeekForDate(DateTime.utc(2026, 8, 31)), 1);
    expect(calc.getWeekForDate(DateTime.utc(2026, 10, 8)), 6);
    expect(calc.getDateRangeForWeek(11).start, DateTime.utc(2026, 11, 9));
    final filter =
        CourseFilterService(semester, projection.schedules, daysOff: off);
    expect(filter.getCoursesForDate(DateTime.utc(2026, 9, 25)), isEmpty);
    expect(filter.getCoursesForDate(DateTime.utc(2026, 10, 1)), isEmpty);
    expect(filter.getCoursesForWeek(4).length, 10);
    expect(filter.getCoursesForWeek(5).length, 11);
    expect(filter.getCoursesForDate(DateTime.utc(2026, 10, 8)).length, 3);
    expect(filter.getCoursesForWeek(11), isEmpty);
    expect(filter.getCoursesForWeek(12).length, 14);
    expect(
        CourseFilterService(semester, projection.schedules)
            .getCoursesForDate(DateTime.utc(2026, 10, 1))
            .length,
        3);
  });
  test(
      'holiday removes courses and unconfigured entries but preserves tasks and conflicts between tasks',
      () {
    final date = DateTime.utc(2026, 10, 1);
    final snapshot = SemesterSnapshot(
        semester: semester,
        courses: projection.courses,
        schedules: projection.schedules,
        classTimes: [],
        daysOff: off);
    final task = TaskEvent(
        id: 'keep',
        title: '个人安排',
        date: date,
        startTime: '10:00',
        endTime: '11:00',
        reminderMinutes: 10);
    final timeline = TimelineService().forDate(date, snapshot, [task]);
    expect(timeline.items.map((i) => i.sourceType), ['task']);
    expect(timeline.unconfiguredSchedules, isEmpty);
    final candidate = TimelineService().taskItem(TaskEvent(
        id: 'new',
        title: 'new',
        date: date,
        startTime: '10:30',
        endTime: '11:30'));
    expect(
        ConflictDetectionService()
            .findConflicts(candidate, timeline.items)
            .single
            .sourceId,
        'keep');
    expect(
        TimelineService()
            .forDate(DateTime.utc(2026, 10, 8), snapshot, [])
            .unconfiguredSchedules
            .length,
        3);
  });
  test('day off matches a school calendar date irrespective of clock fields',
      () {
    final filter = CourseFilterService(semester, projection.schedules,
        daysOff: [ClassDayOff(date: DateTime(2026, 10, 1, 20), reason: '停课')]);
    expect(filter.getCoursesForDate(DateTime(2026, 10, 1, 9)), isEmpty);
    expect(filter.getCoursesForDate(DateTime.utc(2026, 9, 24)).length, 3);
  });
}
