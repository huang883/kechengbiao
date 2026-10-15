import 'package:schedule_core/schedule_core.dart';
import 'package:test/test.dart';

void main() {
  final semester = Semester(
      id: 's',
      name: 'school',
      startDate: DateTime.utc(2026, 8, 31),
      endDate: DateTime.utc(2027, 1, 16),
      totalWeeks: 20,
      weekStartDay: 1);
  final a = DateTime.utc(2026, 10, 7), b = DateTime.utc(2026, 10, 8);
  final source = CourseSchedule(
      id: 'a',
      courseId: 'a',
      semesterId: 's',
      weekday: 3,
      startSection: 1,
      endSection: 2,
      classroom: 'A',
      activeWeeks: [6]);
  final target = CourseSchedule(
      id: 'b',
      courseId: 'b',
      semesterId: 's',
      weekday: 4,
      startSection: 1,
      endSection: 4,
      classroom: 'B',
      activeWeeks: [6]);
  LessonTransfer transfer({bool keep = false}) => LessonTransfer(
      id: 't',
      scheduleId: 'a',
      sourceDate: a,
      targetDate: b,
      sourceStart: 1,
      sourceEnd: 1,
      targetStart: 2,
      keepSource: keep);
  CourseFilterService filter(List<LessonTransfer> t, {bool off = false}) =>
      CourseFilterService(semester, [source, target],
          lessonTransfers: t,
          daysOff: off ? [ClassDayOff(date: b, reason: 'off')] : []);
  test(
      'single section moves and splits target while preserving both remainders; undo restores',
      () {
    final t = transfer(), f = filter([transfer()]);
    expect(f.getCoursesForDate(a).map((s) => (s.startSection, s.endSection)),
        [(2, 2)]);
    final result = f.getCoursesForDate(b);
    expect(result.map((s) => (s.courseId, s.startSection, s.endSection)),
        [('b', 1, 1), ('a', 2, 2), ('b', 3, 4)]);
    expect(result[1].adjustmentLabel, contains('第 6 周星期三第 1 节'));
    expect(filter([]).getCoursesForDate(a).single.endSection, 2);
    expect(filter([]).getCoursesForDate(b).single.endSection, 4);
    expect(
        filter([transfer(keep: true)]).getCoursesForDate(a).single.startSection,
        1);
    expect(filter([t], off: true).getCoursesForDate(b).single.courseId, 'a');
  });
  test(
      'target clock, unique timeline IDs and conflict detection reflect split lessons',
      () {
    final snap = SemesterSnapshot(semester: semester, courses: [
      const Course(id: 'a', name: 'English', teacher: 'T'),
      const Course(id: 'b', name: 'Math', teacher: 'T')
    ], schedules: [
      source,
      target
    ], classTimes: [
      for (var n = 1; n <= 4; n++)
        ClassTimeConfig(
            semesterId: 's',
            section: n,
            startTime: '${(7 + n).toString().padLeft(2, '0')}:00',
            endTime: '${(7 + n).toString().padLeft(2, '0')}:45')
    ], lessonTransfers: [
      transfer()
    ]);
    final items = TimelineService().forDate(b, snap, []).items;
    expect(items.map((i) => i.id).toSet().length, 3);
    expect(items[1].startDateTime, DateTime.utc(2026, 10, 8, 9));
    expect(items[1].schedule!.startSection, 2);
    expect(items[1].subtitle, contains('第 1 节'));
    final candidate = TimelineService().taskItem(TaskEvent(
        id: 'task', title: 'x', date: b, startTime: '09:15', endTime: '09:20'));
    expect(
        ConflictDetectionService().findConflicts(candidate, items).single.title,
        'English');
  });
  test(
      'same-day disjoint move works, overlapping source and destination rejected',
      () {
    final t = LessonTransfer(
        id: 't',
        scheduleId: 'a',
        sourceDate: a,
        targetDate: a,
        sourceStart: 1,
        sourceEnd: 1,
        targetStart: 3);
    expect(filter([t]).getCoursesForDate(a).map((s) => s.startSection), [2, 3]);
    expect(
        () => LessonTransfer(
            id: 't',
            scheduleId: 'a',
            sourceDate: a,
            targetDate: a,
            sourceStart: 1,
            sourceEnd: 2,
            targetStart: 2),
        throwsFormatException);
  });
}
