const unclear = 'unclear';

class Semester {
  final String id, name;
  final DateTime startDate, endDate;
  final int totalWeeks, weekStartDay, manualWeekOffset;
  Semester(
      {required this.id,
      required this.name,
      required this.startDate,
      required this.endDate,
      required this.totalWeeks,
      required this.weekStartDay,
      this.manualWeekOffset = 0}) {
    if (totalWeeks < 1 ||
        weekStartDay < 1 ||
        weekStartDay > 7 ||
        endDate.isBefore(startDate)) {
      throw ArgumentError('Invalid semester');
    }
  }
}

/// An explicit school-local date on which regular courses do not take place.
class ClassDayOff {
  final DateTime date;
  final String reason;
  ClassDayOff({required DateTime date, required String reason})
      : date = DateTime.utc(date.year, date.month, date.day),
        reason = reason.trim() {
    if (this.reason.isEmpty) throw ArgumentError('A day off needs a reason');
  }
}

class Course {
  final String id, name, teacher, color, remark;
  const Course(
      {required this.id,
      required this.name,
      required this.teacher,
      this.color = 'default',
      this.remark = ''});
}

class CourseSchedule {
  final String id, courseId, semesterId, classroom, remark;
  final int weekday, startSection, endSection;
  final List<int> activeWeeks;
  final String? customStartTime, customEndTime;
  final String? originalScheduleId;
  final String adjustmentLabel;
  CourseSchedule(
      {required this.id,
      required this.courseId,
      required this.semesterId,
      required this.weekday,
      required this.startSection,
      required this.endSection,
      required this.classroom,
      required List<int> activeWeeks,
      this.customStartTime,
      this.customEndTime,
      this.originalScheduleId,
      this.adjustmentLabel = '',
      this.remark = ''})
      : activeWeeks = List.unmodifiable(activeWeeks) {
    if (weekday < 1 ||
        weekday > 7 ||
        startSection < 1 ||
        endSection < startSection ||
        activeWeeks.isEmpty ||
        activeWeeks.any((w) => w < 1) ||
        activeWeeks.toSet().length != activeWeeks.length) {
      throw ArgumentError('Invalid course schedule');
    }
    for (var i = 1; i < activeWeeks.length; i++) {
      if (activeWeeks[i] <= activeWeeks[i - 1]) {
        throw ArgumentError('Weeks must be sorted');
      }
    }
  }
  Map<String, Object> toJson() => {
        'id': id,
        'courseId': courseId,
        'semesterId': semesterId,
        'weekday': weekday,
        'startSection': startSection,
        'endSection': endSection,
        'classroom': classroom,
        'activeWeeks': activeWeeks,
        'remark': remark
      };
}

class ParsedCourseRecord {
  final String id;
  final Map<String, dynamic> fields, source;
  ParsedCourseRecord(
      this.id, Map<String, dynamic> fields, Map<String, dynamic> source)
      : fields = Map.unmodifiable({
          ...fields,
          if (fields['activeWeeks'] is List<int>)
            'activeWeeks':
                List<int>.unmodifiable(fields['activeWeeks'] as List<int>)
        }),
        source = Map.unmodifiable(source);
  Map<String, dynamic> toJson() => {'id': id, ...fields, 'source': source};
}

class CourseProjection {
  final List<Course> courses;
  final List<CourseSchedule> schedules;
  final List<String> skippedRecordIds;
  CourseProjection(List<Course> courses, List<CourseSchedule> schedules,
      List<String> skipped)
      : courses = List.unmodifiable(courses),
        schedules = List.unmodifiable(schedules),
        skippedRecordIds = List.unmodifiable(skipped);
}

class ParsedSchedule {
  final String sourceSha256;
  final Map<String, dynamic> semester;
  final List<ParsedCourseRecord> records;
  ParsedSchedule(this.sourceSha256, Map<String, dynamic> semester,
      List<ParsedCourseRecord> records)
      : semester = Map.unmodifiable(semester),
        records = List.unmodifiable(records);

  /// Analysis only: does not confirm an import or access any database.
  CourseProjection projectResolvedRecords() {
    final courses = <String, Course>{};
    final schedules = <CourseSchedule>[];
    final skipped = <String>[];
    for (final r in records) {
      final f = r.fields;
      final weeks = f['activeWeeks'];
      final day = f['weekday'],
          start = f['startSection'],
          end = f['endSection'];
      if (weeks is! List<int> ||
          weeks.isEmpty ||
          day is! int ||
          day < 1 ||
          day > 7 ||
          start is! int ||
          end is! int ||
          start < 1 ||
          end < start ||
          semester['totalWeeks'] is! int ||
          weeks.any((w) => w < 1 || w > (semester['totalWeeks'] as int)) ||
          ['name', 'teacher', 'teachingClass', 'classroom']
              .any((k) => f[k] == unclear || f[k] == null)) {
        skipped.add(r.id);
        continue;
      }
      final key = '${f['name']}|${f['teacher']}|${f['teachingClass']}';
      final c = courses.putIfAbsent(
          key,
          () => Course(
              id: 'course_${courses.length + 1}',
              name: f['name'] as String,
              teacher: f['teacher'] as String));
      schedules.add(CourseSchedule(
          id: r.id,
          courseId: c.id,
          semesterId: 'semester_1',
          weekday: day,
          startSection: start,
          endSection: end,
          classroom: f['classroom'] as String,
          activeWeeks: weeks,
          remark: f['remark'] as String));
    }
    return CourseProjection(courses.values.toList(), schedules, skipped);
  }

  Map<String, dynamic> toJson() => {
        'sourceSha256': sourceSha256,
        'semester': semester,
        'records': records.map((r) => r.toJson()).toList()
      };
}

class ValidationIssue {
  final String code, severity, message;
  final String? recordId;
  const ValidationIssue(this.code, this.severity, this.message,
      [this.recordId]);
  Map<String, dynamic> toJson() => {
        'code': code,
        'severity': severity,
        'message': message,
        'recordId': recordId
      };
}

/// Uses the source day's original rules; never follows another replacement.
class ClassDayReplacement {
  final DateTime sourceDate, targetDate;
  ClassDayReplacement(
      {required DateTime sourceDate, required DateTime targetDate})
      : sourceDate =
            DateTime.utc(sourceDate.year, sourceDate.month, sourceDate.day),
        targetDate =
            DateTime.utc(targetDate.year, targetDate.month, targetDate.day) {
    if (this.sourceDate == this.targetDate) {
      throw const FormatException('来源日期和目标日期不能相同');
    }
  }
}

class LessonTransfer {
  final String id, scheduleId;
  final DateTime sourceDate, targetDate;
  final int sourceStart, sourceEnd, targetStart;
  final bool keepSource;
  final int? editedTargetEnd;
  final String? targetStartTime, targetEndTime, targetClassroom;
  int get targetEnd => editedTargetEnd ?? targetStart + sourceEnd - sourceStart;
  LessonTransfer(
      {required this.id,
      required this.scheduleId,
      required DateTime sourceDate,
      required DateTime targetDate,
      required this.sourceStart,
      required this.sourceEnd,
      required this.targetStart,
      this.editedTargetEnd,
      this.targetStartTime,
      this.targetEndTime,
      this.targetClassroom,
      this.keepSource = false})
      : sourceDate =
            DateTime.utc(sourceDate.year, sourceDate.month, sourceDate.day),
        targetDate =
            DateTime.utc(targetDate.year, targetDate.month, targetDate.day) {
    if (id.isEmpty ||
        scheduleId.isEmpty ||
        sourceStart < 1 ||
        sourceEnd < sourceStart ||
        targetStart < 1 ||
        targetEnd < targetStart) {
      throw const FormatException('调课节次无效');
    }
    if (targetStartTime == null &&
        this.sourceDate == this.targetDate &&
        targetStart <= sourceEnd &&
        targetEnd >= sourceStart) {
      throw const FormatException('同一天的来源与目标节次不能重叠');
    }
  }
}
