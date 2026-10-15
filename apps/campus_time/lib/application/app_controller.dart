import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:schedule_core/schedule_core.dart';
import 'package:schedule_pdf/schedule_pdf.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'notifications.dart';
import '../features/pomodoro/pomodoro_controller.dart';
import '../features/pomodoro/focus_bridge.dart';

final appProvider = ChangeNotifierProvider<AppController>(
  (ref) => throw StateError('AppController must be provided'),
);

class AppController extends ChangeNotifier {
  final ImportRepository imports;
  final CourseRepository courses;
  final TaskRepository taskStore;
  final SettingsRepository settings;
  final SharedPreferences? preferences;
  final NotificationService? notifications;
  final FocusBridge? focusBridge;
  final DateTime Function() clock;
  AppController({
    required this.imports,
    required this.courses,
    required this.taskStore,
    required this.settings,
    this.preferences,
    this.notifications,
    this.focusBridge,
    DateTime Function()? clock,
  }) : clock =
           clock ??
           (() => DateTime.now().toUtc().add(const Duration(hours: 8)));
  late final PomodoroController pomodoro = PomodoroController(
    focusBridge: focusBridge,
    preferences: preferences,
    notifications: notifications,
  );
  List<Semester> semesters = [];
  SemesterSnapshot? snapshot;
  List<TaskEvent> tasks = [];
  ImportDraft? draft;
  bool loaded = false;
  bool reminderEnabled = false;
  String? notificationWarning;
  int selectedWeek = 1;
  String? _selected;
  DateTime get now => clock();
  void tick() => notifyListeners();
  int? get currentWeek => snapshot == null
      ? null
      : SemesterWeekCalculator(snapshot!.semester).getCurrentWeek(now);
  TimelineResult timeline(DateTime date) =>
      TimelineService().forDate(date, snapshot, tasks);

  Future<void> initialize() async {
    await pomodoro.initialize();
    _selected = preferences?.getString('semester');
    reminderEnabled = preferences?.getBool('reminders') ?? false;
    await refresh();
    final draftId = preferences?.getString('draft');
    if (draftId != null) draft = await imports.readDraft(draftId);
    selectedWeek = currentWeek ?? 1;
    loaded = true;
    notifyListeners();
    await syncReminders();
  }

  Future<void> refresh() async {
    semesters = await courses.listSemesters();
    if (!semesters.any((s) => s.id == _selected)) {
      _selected = semesters.isEmpty ? null : semesters.last.id;
    }
    snapshot = _selected == null
        ? null
        : await courses.loadSemester(_selected!);
    tasks = await taskStore.list();
    notifyListeners();
  }

  Future<void> selectSemester(String id) async {
    selectedWeek = 1;
    _selected = id;
    await preferences?.setString('semester', id);
    await refresh();
    selectedWeek = currentWeek ?? 1;
    notifyListeners();
    await syncReminders();
  }

  void changeWeek(int week) {
    if (snapshot == null || week < 1 || week > snapshot!.semester.totalWeeks) {
      return;
    }
    selectedWeek = week;
    notifyListeners();
  }

  Future<void> importBytes(Uint8List bytes) async {
    final parsed = PdfScheduleParser().parse(
      await SchoolPdfAdapter().extract(bytes),
    );
    draft = await imports.createDraft(parsed);
    await preferences?.setString('draft', draft!.id);
    notifyListeners();
  }

  Future<void> editDraft({
    Map<String, dynamic> semester = const {},
    Map<String, Map<String, dynamic>> records = const {},
    Map<String, String>? exclusions,
  }) async {
    final d = draft!;
    draft = await imports.editDraft(
      d.id,
      expectedRevision: d.revision,
      semesterChanges: semester,
      recordChanges: records,
      exclusions: exclusions,
      reason: '用户在导入预览中修正或排除记录',
    );
    notifyListeners();
  }

  List<ValidationIssue> get draftIssues {
    final d = draft;
    if (d == null) return [];
    return ImportValidation().validate(
      ParsedSchedule(
        d.id,
        d.reviewed.semester,
        d.reviewed.records
            .where((r) => !d.exclusions.containsKey(r.id))
            .toList(),
      ),
    );
  }

  Future<void> confirmDraft() async {
    final d = draft!;
    final result = await imports.confirmImport(
      d.id,
      expectedRevision: d.revision,
      confirmed: true,
    );
    draft = await imports.readDraft(d.id);
    await selectSemester(result.semesterId);
  }

  List<TimelineItem> conflicts(TaskEvent task) => !task.hasTime
      ? []
      : ConflictDetectionService().findConflicts(
          TimelineService().taskItem(task),
          timeline(task.date).items,
        );
  Future<void> saveTask(TaskEvent task, {required bool editing}) async {
    if (editing) {
      await taskStore.update(task);
    } else {
      await taskStore.create(task);
    }
    await refresh();
    await syncReminders();
  }

  Future<void> completeTask(String id, bool completed) async {
    await taskStore.setCompleted(id, completed);
    await refresh();
    await syncReminders();
  }

  Future<void> deleteTask(String id) async {
    await taskStore.delete(id);
    await refresh();
    await syncReminders();
  }

  Future<void> saveTimes(List<ClassTimeConfig> config) async {
    await settings.replaceClassTimes(snapshot!.semester.id, config);
    await refresh();
    await syncReminders();
  }

  Future<void> saveCalendar(DateTime firstWeekStart, int weekStartDay) async {
    await settings.updateSemesterCalendar(
      snapshot!.semester.id,
      firstWeekStart: firstWeekStart,
      weekStartDay: weekStartDay,
    );
    await refresh();
    selectedWeek = currentWeek ?? 1;
    notifyListeners();
    await syncReminders();
  }

  Future<void> saveLessonTransfer(LessonTransfer t) async {
    await settings.saveLessonTransfer(snapshot!.semester.id, t);
    await refresh();
    await syncReminders();
  }

  Future<void> removeLessonTransfer(String id) async {
    await settings.deleteLessonTransfer(snapshot!.semester.id, id);
    await refresh();
    await syncReminders();
  }

  Future<void> saveReplacement(ClassDayReplacement replacement) async {
    await settings.saveReplacement(snapshot!.semester.id, replacement);
    await refresh();
    await syncReminders();
  }

  Future<void> removeReplacement(DateTime date) async {
    await settings.deleteReplacement(snapshot!.semester.id, date);
    await refresh();
    await syncReminders();
  }

  Future<void> saveDayOff(ClassDayOff day) async {
    await settings.saveDayOff(snapshot!.semester.id, day);
    await refresh();
    await syncReminders();
  }

  Future<void> removeDayOff(DateTime date) async {
    await settings.deleteDayOff(snapshot!.semester.id, date);
    await refresh();
    await syncReminders();
  }

  Future<void> calibrateWeek(int desired) async {
    final current = currentWeek, s = snapshot?.semester;
    if (current == null || s == null || desired < 1 || desired > s.totalWeeks) {
      throw const FormatException('今天不在所选学期内，或输入周次超出范围');
    }
    await settings.setManualWeekOffset(
      s.id,
      s.manualWeekOffset + desired - current,
    );
    await refresh();
    selectedWeek = desired;
    notifyListeners();
    await syncReminders();
  }

  Future<void> editTransferredCourse(
    String semesterId,
    String transferId,
    Course course,
    CourseSchedule target,
    DateTime date,
  ) async {
    await settings.editTransferredCourse(
      semesterId,
      transferId,
      course,
      target,
      date,
    );
    await refresh();
    await syncReminders();
  }

  Future<void> saveCourse(
    Course course,
    CourseSchedule schedule, {
    required bool creating,
  }) async {
    await settings.saveCourseSchedule(course, schedule, creating: creating);
    await refresh();
    await syncReminders();
  }

  Future<void> renameTimetable(String id, String name) async {
    await settings.renameSemester(id, name);
    await refresh();
  }

  Future<void> saveColor(String courseId, String color) async {
    await settings.setCourseColor(courseId, color);
    await refresh();
  }

  Future<void> enableReminders(bool enabled) async {
    if (enabled && !(await notifications?.requestPermission() ?? false)) {
      throw const FormatException('未获得通知权限，请在系统设置中允许课间发送通知');
    }
    reminderEnabled = enabled;
    await preferences?.setBool('reminders', enabled);
    notifyListeners();
    await syncReminders();
  }

  Future<void> syncReminders() async {
    try {
      await notifications?.synchronize(
        snapshot,
        tasks,
        enabled: reminderEnabled,
        now: now,
      );
      notificationWarning = null;
    } catch (e) {
      debugPrint('Notification scheduling failed: $e');
      notificationWarning = '数据已保存，但提醒未能更新，请重新开启提醒。';
    }
    notifyListeners();
  }
}
