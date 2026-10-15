import 'package:schedule_core/schedule_core.dart';
import 'package:test/test.dart';

void main() {
  final date = DateTime.utc(2026, 10, 5);
  final semester = Semester(
      id: 's',
      name: 'test',
      startDate: date,
      endDate: DateTime.utc(2027, 1, 1),
      totalWeeks: 13,
      weekStartDay: 1);
  final course = Course(id: 'c', name: '课程', teacher: '老师');
  final schedule = CourseSchedule(
      id: 'r',
      courseId: 'c',
      semesterId: 's',
      weekday: 1,
      startSection: 1,
      endSection: 2,
      classroom: 'A',
      activeWeeks: [1, 3]);
  SemesterSnapshot snapshot(List<ClassTimeConfig> times) => SemesterSnapshot(
      semester: semester,
      courses: [course],
      schedules: [schedule],
      classTimes: times);
  final times = [
    ClassTimeConfig(
        semesterId: 's', section: 1, startTime: '08:00', endTime: '08:45'),
    ClassTimeConfig(
        semesterId: 's', section: 2, startTime: '08:55', endTime: '09:40')
  ];
  TaskEvent task(String id, String start, String end) =>
      TaskEvent(id: id, title: id, date: date, startTime: start, endTime: end);
  test('unified timeline sorts exact minute times and spans class sections',
      () {
    final result = TimelineService().forDate(date, snapshot(times), [
      task('late', '19:20', '21:10'),
      task('early', '07:17', '07:35'),
      task('noon', '12:35', '13:18')
    ]);
    expect(result.items.map((i) => i.title), ['early', '课程', 'noon', 'late']);
    expect(result.items[1].endDateTime, DateTime.utc(2026, 10, 5, 9, 40));
    expect(result.unconfiguredSchedules, isEmpty);
  });
  test('missing class times remain visible as unconfigured, never guessed', () {
    final result =
        TimelineService().forDate(date, snapshot(times.take(1).toList()), []);
    expect(result.items, isEmpty);
    expect(result.unconfiguredSchedules.single.id, 'r');
  });
  test('inactive week and wrong date tasks do not enter timeline', () {
    expect(
        TimelineService().forDate(DateTime.utc(2026, 10, 12), snapshot(times),
            [task('x', '10:17', '11:35')]).items,
        isEmpty);
  });
  test('overlap is half open, excludes self; containment is detected', () {
    final service = TimelineService();
    final items = service
        .forDate(date, snapshot(times), [task('self', '09:00', '09:30')]).items;
    final conflict = ConflictDetectionService();
    expect(
        conflict.findConflicts(
            service.taskItem(task('boundary', '09:40', '10:17')), items),
        isEmpty);
    expect(
        conflict
            .findConflicts(
                service.taskItem(task('self', '09:00', '09:30')), items)
            .single
            .title,
        '课程');
    expect(
        conflict
            .findConflicts(
                service.taskItem(task('covers', '07:00', '10:00')), items)
            .length,
        2);
  });
  test('stable ties and current/next boundaries', () {
    final result = TimelineService().forDate(
        date, null, [task('b', '10:17', '11:35'), task('a', '10:17', '11:35')]);
    expect(result.items.map((i) => i.sourceId), ['a', 'b']);
    expect(result.currentAt(DateTime.utc(2026, 10, 5, 10, 17)).length, 2);
    expect(result.currentAt(DateTime.utc(2026, 10, 5, 11, 35)), isEmpty);
    expect(result.nextAt(DateTime.utc(2026, 10, 5, 10))!.sourceId, 'a');
  });
}
