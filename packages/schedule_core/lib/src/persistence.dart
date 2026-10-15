import 'models.dart';

/// A calendar date, not a UTC instant conversion.
String dateText(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

bool isClockTime(String text) =>
    RegExp(r'^(?:[01]\d|2[0-3]):[0-5]\d$').hasMatch(text);

class ClassTimeConfig {
  final int section;
  final String semesterId, startTime, endTime;
  ClassTimeConfig(
      {required this.semesterId,
      required this.section,
      required this.startTime,
      required this.endTime}) {
    if (semesterId.trim().isEmpty ||
        section < 1 ||
        !isClockTime(startTime) ||
        !isClockTime(endTime) ||
        startTime.compareTo(endTime) >= 0) {
      throw ArgumentError('Invalid class time');
    }
  }
}

class TaskEvent {
  final String id, title, description;
  final String? startTime, endTime;
  bool get hasTime => startTime != null;
  final DateTime date;
  final bool completed;
  final int? reminderMinutes;
  final String? repeatRule;
  TaskEvent(
      {required this.id,
      required this.title,
      required this.date,
      this.startTime,
      this.endTime,
      this.description = '',
      this.completed = false,
      this.reminderMinutes,
      this.repeatRule}) {
    if (id.trim().isEmpty ||
        title.trim().isEmpty ||
        (startTime == null) != (endTime == null) ||
        (startTime != null &&
            (!isClockTime(startTime!) ||
                !isClockTime(endTime!) ||
                startTime!.compareTo(endTime!) >= 0)) ||
        (!hasTime && reminderMinutes != null) ||
        (reminderMinutes != null && reminderMinutes! < 0)) {
      throw ArgumentError('Invalid task');
    }
    if (repeatRule != null) {
      throw UnsupportedError('Repeating events require a future contract');
    }
  }
}

class ImportDraft {
  final String id;
  final int revision;
  final ParsedSchedule original, reviewed;
  final Map<String, String> exclusions;
  final String reason;
  final bool committed;
  ImportDraft(
      {required this.id,
      required this.revision,
      required this.original,
      required this.reviewed,
      required Map<String, String> exclusions,
      required this.reason,
      required this.committed})
      : exclusions = Map.unmodifiable(exclusions);
}

class ImportResult {
  final String semesterId;
  final int revision, courseCount, scheduleCount;
  final bool alreadyCommitted;
  const ImportResult(
      {required this.semesterId,
      required this.revision,
      required this.courseCount,
      required this.scheduleCount,
      required this.alreadyCommitted});
}

class SemesterSnapshot {
  final Semester semester;
  final List<Course> courses;
  final List<CourseSchedule> schedules;
  final List<ClassTimeConfig> classTimes;
  final List<ClassDayOff> daysOff;
  final List<ClassDayReplacement> replacements;
  final List<LessonTransfer> lessonTransfers;
  SemesterSnapshot(
      {required this.semester,
      required List<Course> courses,
      required List<CourseSchedule> schedules,
      required List<ClassTimeConfig> classTimes,
      List<ClassDayOff> daysOff = const [],
      List<ClassDayReplacement> replacements = const [],
      List<LessonTransfer> lessonTransfers = const []})
      : courses = List.unmodifiable(courses),
        schedules = List.unmodifiable(schedules),
        classTimes = List.unmodifiable(classTimes),
        daysOff = List.unmodifiable(daysOff),
        replacements = List.unmodifiable(replacements),
        lessonTransfers = List.unmodifiable(lessonTransfers);
}

class ImportRecordMetadata {
  final String scheduleId, recordId, teachingClass;
  final int draftRevision;
  final int? totalHours, credits;
  final Map<String, dynamic> source;
  ImportRecordMetadata(
      {required this.scheduleId,
      required this.recordId,
      required this.teachingClass,
      required this.draftRevision,
      required this.totalHours,
      required this.credits,
      required Map<String, dynamic> source})
      : source = Map.unmodifiable(source);
}

class RepositoryException implements Exception {
  final String code, message;
  const RepositoryException(this.code, this.message);
  @override
  String toString() => '$code: $message';
}

abstract interface class ImportRepository {
  Future<ImportDraft> createDraft(ParsedSchedule parsed);
  Future<ImportDraft?> readDraft(String id);
  Future<List<ImportDraft>> history(String id);
  Future<ImportDraft> editDraft(String id,
      {required int expectedRevision,
      Map<String, dynamic> semesterChanges = const {},
      Map<String, Map<String, dynamic>> recordChanges = const {},
      Map<String, String>? exclusions,
      required String reason});
  Future<ImportResult> confirmImport(String id,
      {required int expectedRevision, required bool confirmed});
}

abstract interface class CourseRepository {
  Future<List<Semester>> listSemesters();
  Future<SemesterSnapshot?> loadSemester(String id);
  Stream<SemesterSnapshot?> watchSemester(String id);
  Future<List<ImportRecordMetadata>> readMetadata(String semesterId);
}

abstract interface class SettingsRepository {
  Future<void> editTransferredCourse(String semesterId, String transferId,
      Course course, CourseSchedule target, DateTime targetDate);
  Future<void> saveCourseSchedule(Course course, CourseSchedule schedule,
      {required bool creating});
  Future<void> renameSemester(String semesterId, String name);
  Future<void> saveLessonTransfer(String semesterId, LessonTransfer transfer);
  Future<void> deleteLessonTransfer(String semesterId, String id);
  Future<void> saveReplacement(
      String semesterId, ClassDayReplacement replacement);
  Future<void> deleteReplacement(String semesterId, DateTime targetDate);
  Future<void> updateSemesterCalendar(String semesterId,
      {required DateTime firstWeekStart, required int weekStartDay});
  Future<void> saveDayOff(String semesterId, ClassDayOff day);
  Future<void> deleteDayOff(String semesterId, DateTime date);
  Future<void> replaceClassTimes(
      String semesterId, List<ClassTimeConfig> times);
  Future<void> setManualWeekOffset(String semesterId, int offset);
  Future<void> setCourseColor(String courseId, String color);
}

abstract interface class TaskRepository {
  Future<void> create(TaskEvent task);
  Future<void> update(TaskEvent task);
  Future<TaskEvent?> read(String id);
  Future<List<TaskEvent>> list(
      {DateTime? from, DateTime? through, bool? completed});
  Future<void> setCompleted(String id, bool completed);
  Future<void> delete(String id);
}
