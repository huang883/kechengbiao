import 'models.dart';
import 'persistence.dart';
import 'calendar.dart';

class TimelineItem {
  final String id, sourceType, sourceId, title, subtitle, color;
  final DateTime startDateTime, endDateTime;
  final bool completed;
  final CourseSchedule? schedule;
  const TimelineItem(
      {required this.id,
      required this.sourceType,
      required this.sourceId,
      required this.title,
      required this.subtitle,
      required this.startDateTime,
      required this.endDateTime,
      this.schedule,
      this.color = 'default',
      this.completed = false});
}

class TimelineResult {
  final List<TimelineItem> items;
  final List<CourseSchedule> unconfiguredSchedules;
  TimelineResult(List<TimelineItem> items, List<CourseSchedule> missing)
      : items = List.unmodifiable(items),
        unconfiguredSchedules = List.unmodifiable(missing);
  List<TimelineItem> currentAt(DateTime now) => items
      .where((i) =>
          !i.completed &&
          !now.isBefore(i.startDateTime) &&
          now.isBefore(i.endDateTime))
      .toList();
  TimelineItem? nextAt(DateTime now) {
    for (final item in items) {
      if (!item.completed && item.startDateTime.isAfter(now)) return item;
    }
    return null;
  }
}

DateTime wallTime(DateTime date, String clock) {
  final parts = clock.split(':').map(int.parse).toList();
  return DateTime.utc(date.year, date.month, date.day, parts[0], parts[1]);
}

class ClassTimeService {
  ({String start, String end})? getClassTime(
      CourseSchedule schedule, List<ClassTimeConfig> config) {
    if (schedule.customStartTime != null && schedule.customEndTime != null) {
      return (start: schedule.customStartTime!, end: schedule.customEndTime!);
    }
    final map = {
      for (final time
          in config.where((t) => t.semesterId == schedule.semesterId))
        time.section: time
    };
    for (var n = schedule.startSection; n <= schedule.endSection; n++) {
      if (!map.containsKey(n)) return null;
    }
    return (
      start: map[schedule.startSection]!.startTime,
      end: map[schedule.endSection]!.endTime
    );
  }
}

class TimelineService {
  TimelineItem taskItem(TaskEvent task) => TimelineItem(
      id: 'task:${task.id}',
      sourceType: 'task',
      sourceId: task.id,
      title: task.title,
      subtitle: task.description,
      startDateTime: wallTime(task.date, task.startTime!),
      endDateTime: wallTime(task.date, task.endTime!),
      completed: task.completed,
      color: '#B7764B');

  TimelineResult forDate(
      DateTime date, SemesterSnapshot? snapshot, List<TaskEvent> tasks) {
    final items = <TimelineItem>[];
    final missing = <CourseSchedule>[];
    if (snapshot != null) {
      final courses = {for (final c in snapshot.courses) c.id: c};
      for (final rule in CourseFilterService(
              snapshot.semester, snapshot.schedules,
              daysOff: snapshot.daysOff,
              replacements: snapshot.replacements,
              lessonTransfers: snapshot.lessonTransfers)
          .getCoursesForDate(date)) {
        final time = ClassTimeService().getClassTime(rule, snapshot.classTimes);
        if (time == null) {
          missing.add(rule);
          continue;
        }
        final c = courses[rule.courseId]!;
        items.add(TimelineItem(
            id: 'course:${rule.id}:${dateText(date)}',
            sourceType: 'course',
            sourceId: rule.originalScheduleId ?? rule.id,
            schedule: rule,
            title: c.name,
            subtitle: [
              rule.classroom,
              if (rule.adjustmentLabel.isNotEmpty) rule.adjustmentLabel
            ].join('\n'),
            color: c.color,
            startDateTime: wallTime(date, time.start),
            endDateTime: wallTime(date, time.end)));
      }
    }
    items.addAll(tasks
        .where((t) => t.hasTime && dateText(t.date) == dateText(date))
        .map(taskItem));
    items.sort((a, b) {
      final start = a.startDateTime.compareTo(b.startDateTime);
      if (start != 0) return start;
      final end = a.endDateTime.compareTo(b.endDateTime);
      if (end != 0) return end;
      final type = a.sourceType.compareTo(b.sourceType);
      return type != 0 ? type : a.id.compareTo(b.id);
    });
    return TimelineResult(items, missing);
  }
}

class ConflictDetectionService {
  List<TimelineItem> findConflicts(
          TimelineItem candidate, List<TimelineItem> items) =>
      items
          .where((item) =>
              item.id != candidate.id &&
              !item.completed &&
              candidate.startDateTime.isBefore(item.endDateTime) &&
              item.startDateTime.isBefore(candidate.endDateTime))
          .toList();
}
