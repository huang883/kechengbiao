import 'dart:convert';
import 'dart:io';
import 'package:schedule_core/schedule_core.dart';
import 'package:test/test.dart';

Semester semester({int day = 7, int offset = 0}) => Semester(
    id: 'semester_1',
    name: 'Test',
    startDate: DateTime.utc(2026, 8, 30),
    endDate: DateTime.utc(2027, 1, 16),
    totalWeeks: 20,
    weekStartDay: day,
    manualWeekOffset: offset);

void main() {
  // Sunday is a test input, not an inferred school policy.
  test('Sunday anchor, year boundary and outside-semester dates', () {
    final c = SemesterWeekCalculator(semester());
    expect(c.getWeekForDate(DateTime.utc(2026, 8, 29)), isNull);
    expect(c.getWeekForDate(DateTime.utc(2026, 8, 30)), 1);
    expect(c.getWeekForDate(DateTime.utc(2026, 9, 5)), 1);
    expect(c.getWeekForDate(DateTime.utc(2026, 9, 6)), 2);
    expect(c.getCurrentWeek(DateTime.utc(2026, 10, 5)), 6);
    expect(c.getWeekForDate(DateTime.utc(2027, 1, 16)), 20);
    expect(c.getWeekForDate(DateTime.utc(2027, 1, 17)), isNull);
  });
  test('Monday anchor and manual calibration participate in inverse mapping',
      () {
    final uncorrected = SemesterWeekCalculator(semester(day: 1));
    final corrected = SemesterWeekCalculator(semester(day: 1, offset: -1));
    expect(uncorrected.getCurrentWeek(DateTime.utc(2026, 10, 5)), 7);
    expect(corrected.getCurrentWeek(DateTime.utc(2026, 10, 5)), 6);
    expect(corrected.getDateRangeForWeek(1).start, DateTime.utc(2026, 8, 31));
    expect(corrected.getWeekForDate(DateTime.utc(2026, 8, 30)), isNull);
    for (var w = 1; w <= 20; w++) {
      final range = corrected.getDateRangeForWeek(w);
      expect(corrected.getWeekForDate(range.start), w);
      expect(range.end.difference(range.start).inDays, 6);
    }
    expect(() => corrected.getDateRangeForWeek(0), throwsRangeError);
    expect(() => corrected.getDateRangeForWeek(21), throwsRangeError);
  });
  final parsed = PdfScheduleParser().parse(
      jsonDecode(File('../../apps/campus_time/assets/default_timetable.json').readAsStringSync())
          as Map<String, dynamic>);
  final projection = parsed.projectResolvedRecords();
  final filter = CourseFilterService(semester(), projection.schedules);
  test('real fixture weekly totals, including fully absent week 11', () {
    expect([
      for (var w = 1; w <= 20; w++) filter.getCoursesForWeek(w).length
    ], [
      12,
      12,
      11,
      13,
      14,
      14,
      14,
      14,
      16,
      16,
      0,
      14,
      14,
      11,
      10,
      10,
      10,
      3,
      2,
      0
    ]);
    expect(filter.getCoursesForWeek(0), isEmpty);
    expect(filter.getCoursesForWeek(21), isEmpty);
  });
  test('same course changes rooms in week 14 without overwriting', () {
    final id = projection.courses.singleWhere((c) => c.name == '数字逻辑与数字电路B').id;
    expect(projection.schedules.where((s) => s.courseId == id).length, 2);
    expect(
        filter
            .getCoursesForWeek(13)
            .singleWhere((s) => s.courseId == id)
            .classroom,
        contains('信息220'));
    expect(
        filter
            .getCoursesForWeek(14)
            .singleWhere((s) => s.courseId == id)
            .classroom,
        contains('信息321'));
  });
  test('both weekday AND active week are applied for real dates', () {
    expect(filter.getCoursesForDate(DateTime.utc(2026, 11, 9)),
        isEmpty); // week 11 Monday
    final monday =
        filter.getCoursesForDate(DateTime.utc(2026, 11, 16)); // week 12
    expect(monday.length, 3);
    expect(monday.every((s) => s.weekday == 1 && s.activeWeeks.contains(12)),
        isTrue);
    expect(filter.getCoursesForDate(DateTime.utc(2026, 11, 21)),
        isEmpty); // Saturday
    expect(filter.getCoursesForDate(DateTime.utc(2027, 2, 1)), isEmpty);
  });
  test('rule with omitted week 11 never reappears at week 18', () {
    final id = projection.courses.singleWhere((c) => c.name == '面向对象程序设计').id;
    for (final w in [10, 11, 12, 18]) {
      expect(filter.getCoursesForWeek(w).any((s) => s.courseId == id),
          [10, 12].contains(w));
    }
  });
}
