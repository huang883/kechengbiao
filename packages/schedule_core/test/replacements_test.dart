import 'package:schedule_core/schedule_core.dart';
import 'package:test/test.dart';

void main() {
  final s = Semester(
      id: 's',
      name: 'school',
      startDate: DateTime.utc(2026, 8, 31),
      endDate: DateTime.utc(2027, 1, 16),
      totalWeeks: 20,
      weekStartDay: 1);
  CourseSchedule rule(String id, int weekday, List<int> weeks) =>
      CourseSchedule(
          id: id,
          courseId: id,
          semesterId: 's',
          weekday: weekday,
          startSection: 1,
          endSection: 1,
          classroom: 'room',
          activeWeeks: weeks);
  final rules = [
    rule('source', 3, [6]),
    rule('target', 4, [5, 6]),
    rule('later', 3, [7])
  ];
  final a = DateTime.utc(2026, 10, 7),
      b = DateTime.utc(2026, 10, 1),
      c = DateTime.utc(2026, 10, 8);
  test(
      'cross-week replacement overrides holiday and uses source original rules without recursion',
      () {
    final replacements = [
      ClassDayReplacement(sourceDate: a, targetDate: b),
      ClassDayReplacement(sourceDate: b, targetDate: c)
    ];
    final filter = CourseFilterService(s, rules,
        daysOff: [ClassDayOff(date: b, reason: 'holiday')],
        replacements: replacements);
    expect(filter.getCoursesForDate(b).single.id, 'source');
    expect(filter.getCoursesForDate(b).single.weekday, 4);
    expect(filter.getCoursesForDate(a).single.id, 'source');
    expect(filter.getCoursesForDate(c).single.id, 'target');
    expect(filter.getCoursesForWeek(5).single.id, 'source');
    expect(replacementLabel(s, replacements.first), '由第 6 周星期三（10/7）调入');
    expect(
        CourseFilterService(s, rules, replacements: [
          ClassDayReplacement(
              sourceDate: DateTime.utc(2026, 10, 10), targetDate: c)
        ]).getCoursesForDate(c),
        isEmpty);
    expect(() => ClassDayReplacement(sourceDate: a, targetDate: a),
        throwsFormatException);
  });
  test(
      'timeline schedules on target date with provenance and correct conflicts, retaining task',
      () {
    final snap = SemesterSnapshot(
        semester: s,
        courses: [
          for (final r in rules)
            Course(id: r.id, name: r.id, teacher: 'teacher')
        ],
        schedules: rules,
        classTimes: [
          ClassTimeConfig(
              semesterId: 's', section: 1, startTime: '08:00', endTime: '08:45')
        ],
        replacements: [ClassDayReplacement(sourceDate: a, targetDate: b)]);
    final task = TaskEvent(
        id: 'task',
        title: 'keep',
        date: b,
        startTime: '08:15',
        endTime: '08:17');
    final items = TimelineService().forDate(b, snap, [task]).items;
    expect(items.first.sourceId, 'source');
    expect(items.first.startDateTime, DateTime.utc(2026, 10, 1, 8));
    expect(items.first.subtitle, contains('第 6 周星期三'));
    expect(items.last.sourceType, 'task');
    expect(
        ConflictDetectionService()
            .findConflicts(items.last, items)
            .single
            .sourceId,
        'source');
  });
}
