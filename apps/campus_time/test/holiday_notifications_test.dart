import 'package:campus_time/application/notifications.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:schedule_core/schedule_core.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  AndroidFlutterLocalNotificationsPlugin.registerWith();
  const channel = MethodChannel('dexterous.com/flutter/local_notifications');
  final calls = <MethodCall>[];
  setUp(() {
    calls.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          if (call.method == 'initialize') return true;
          return null;
        });
  });
  tearDown(
    () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null),
  );
  test('holiday suppresses course alarms while task alarms remain; normal week resumes', () async {
    // The native plugin rejects past dates using the real system clock.
    final today = DateTime.now().toUtc();
    final base = DateTime.utc(
      today.year,
      today.month,
      today.day,
    ).add(Duration(days: 15 - today.weekday));
    final holiday = base.add(const Duration(days: 3));
    final semester = Semester(
      id: 's',
      name: 'school',
      startDate: base,
      endDate: base.add(const Duration(days: 139)),
      totalWeeks: 20,
      weekStartDay: 1,
    );
    final snapshot = SemesterSnapshot(
      semester: semester,
      courses: [const Course(id: 'c', name: 'course', teacher: 't')],
      schedules: [
        CourseSchedule(
          id: 'r',
          courseId: 'c',
          semesterId: 's',
          weekday: 4,
          startSection: 1,
          endSection: 1,
          classroom: 'room',
          activeWeeks: [1, 2],
        ),
      ],
      classTimes: [
        ClassTimeConfig(
          semesterId: 's',
          section: 1,
          startTime: '08:00',
          endTime: '08:45',
        ),
      ],
      daysOff: [ClassDayOff(date: holiday, reason: '国庆节')],
    );
    final service = NotificationService();
    await service.initialize();
    final task = TaskEvent(
      id: 'task',
      title: 'personal',
      date: holiday,
      startTime: '08:00',
      endTime: '09:00',
      reminderMinutes: 10,
    );
    await service.synchronize(snapshot, [task], enabled: true, now: base);
    final scheduled = calls.where((c) => c.method == 'zonedSchedule').toList();
    expect(scheduled.length, 1);
    expect((scheduled.single.arguments as Map)['title'], 'personal');
    expect(
      (scheduled.single.arguments as Map)['scheduledDateTime'].toString(),
      startsWith('${dateText(holiday)}T07:50'),
    );
    calls.clear();
    await service.synchronize(
      snapshot,
      [],
      enabled: true,
      now: base.add(const Duration(days: 7)),
    );
    final normal = calls.where((c) => c.method == 'zonedSchedule').toList();
    expect(normal.length, 1);
    expect((normal.single.arguments as Map)['title'], 'course');
    expect(calls.first.method, 'cancelAll');
    calls.clear();
    final moved = SemesterSnapshot(
      semester: semester,
      courses: snapshot.courses,
      schedules: snapshot.schedules,
      classTimes: snapshot.classTimes,
      daysOff: snapshot.daysOff,
      replacements: [
        ClassDayReplacement(
          sourceDate: holiday,
          targetDate: base.add(const Duration(days: 5)),
        ),
      ],
    );
    await service.synchronize(moved, [task], enabled: true, now: base);
    final replaced = calls.where((c) => c.method == 'zonedSchedule').toList();
    expect(replaced.length, 2);
    final course = replaced.singleWhere(
      (c) => (c.arguments as Map)['title'] == 'course',
    );
    expect(
      (course.arguments as Map)['scheduledDateTime'].toString(),
      startsWith('${dateText(base.add(const Duration(days: 5)))}T07:50'),
    );
    expect((course.arguments as Map)['body'].toString(), contains('第 1 周星期四'));
    calls.clear();
    await service.synchronize(snapshot, [task], enabled: false, now: base);
    expect(calls.map((c) => c.method), ['cancelAll']);
  });
  test(
    'course synchronization preserves Pomodoro alarm; pausing cancels it',
    () async {
      final service = NotificationService();
      await service.initialize();
      final end = DateTime.now().add(const Duration(minutes: 25));
      await service.setPomodoroAlarm(end, '专注结束', '休息');
      calls.clear();
      await service.synchronize(
        null,
        [],
        enabled: false,
        now: DateTime.now().toUtc(),
      );
      expect(calls.first.method, 'cancelAll');
      final scheduled = calls.where((c) => c.method == 'zonedSchedule').single;
      expect(
        (scheduled.arguments as Map)['id'],
        NotificationService.pomodoroId,
      );
      calls.clear();
      await service.setPomodoroAlarm(null, '', '');
      expect(calls.where((c) => c.method == 'zonedSchedule'), isEmpty);
      expect(calls.where((c) => c.method == 'cancel').length, 1);
    },
  );
}
