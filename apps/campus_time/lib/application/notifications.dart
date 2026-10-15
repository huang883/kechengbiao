import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:schedule_core/schedule_core.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static const pomodoroId = 2000000000;
  DateTime? _pomodoroEnd;
  String _pomodoroTitle = '', _pomodoroBody = '';
  Future<bool> setPomodoroAlarm(DateTime? end, String title, String body) {
    final result = _pending.catchError((Object _) {}).then((_) async {
      _pomodoroEnd = end;
      _pomodoroTitle = title;
      _pomodoroBody = body;
      await plugin.cancel(id: pomodoroId);
      return _schedulePomodoro();
    });
    _pending = result.then<void>((_) {});
    return result;
  }

  Future<void> requestPomodoroExactPermission() async {
    await plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestExactAlarmsPermission();
  }

  Future<bool> _schedulePomodoro() async {
    final end = _pomodoroEnd;
    if (end == null || !end.isAfter(DateTime.now())) return true;
    final exact =
        await plugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >()
            ?.canScheduleExactNotifications() ??
        false;
    await plugin.zonedSchedule(
      id: pomodoroId,
      title: _pomodoroTitle,
      body: _pomodoroBody,
      scheduledDate: tz.TZDateTime.from(end, tz.UTC),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'pomodoro_timer',
          '番茄钟结束提醒',
          channelDescription: '专注和休息阶段结束提醒',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: exact
          ? AndroidScheduleMode.exactAllowWhileIdle
          : AndroidScheduleMode.inexactAllowWhileIdle,
    );
    return exact;
  }

  final plugin = FlutterLocalNotificationsPlugin();
  Future<void> _pending = Future<void>.value();
  Future<void> initialize() async {
    tzdata.initializeTimeZones();
    await plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('ic_notification'),
      ),
    );
  }

  Future<bool> requestPermission() async =>
      await plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.requestNotificationsPermission() ??
      false;

  Future<void> synchronize(
    SemesterSnapshot? snapshot,
    List<TaskEvent> tasks, {
    required bool enabled,
    required DateTime now,
  }) {
    // Serialize cancel + schedule batches when permission/lifecycle/save overlap.
    return _pending = _pending
        .catchError((Object _) {})
        .then((_) => _synchronize(snapshot, tasks, enabled: enabled, now: now));
  }

  Future<void> _synchronize(
    SemesterSnapshot? snapshot,
    List<TaskEvent> tasks, {
    required bool enabled,
    required DateTime now,
  }) async {
    await plugin.cancelAll();
    await _schedulePomodoro();
    if (!enabled) return;
    final location = tz.getLocation('Asia/Shanghai');
    var id = 1;
    final byId = {for (final t in tasks) t.id: t};
    for (var day = 0; day < 7; day++) {
      final date = DateTime.utc(now.year, now.month, now.day + day);
      for (final item
          in TimelineService().forDate(date, snapshot, tasks).items) {
        if (item.completed) continue;
        final minutes = item.sourceType == 'course'
            ? 10
            : byId[item.sourceId]?.reminderMinutes;
        if (minutes == null) continue;
        final at = item.startDateTime.subtract(Duration(minutes: minutes));
        if (!at.isAfter(now)) continue;
        await plugin.zonedSchedule(
          id: id++,
          title: item.title,
          body:
              '${item.startDateTime.hour.toString().padLeft(2, '0')}:${item.startDateTime.minute.toString().padLeft(2, '0')} · ${item.subtitle}',
          scheduledDate: tz.TZDateTime(
            location,
            at.year,
            at.month,
            at.day,
            at.hour,
            at.minute,
          ),
          notificationDetails: const NotificationDetails(
            android: AndroidNotificationDetails(
              'schedule_reminders',
              '课程与待办提醒',
              channelDescription: '课间的本地提醒',
              importance: Importance.high,
              priority: Priority.high,
            ),
          ),
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        );
      }
    }
  }
}
