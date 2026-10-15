import 'dart:convert';

import 'package:campus_time/application/app_controller.dart';
import 'package:campus_time/application/default_timetable.dart';
import 'package:campus_time/shared/course_color_picker.dart';
import 'package:campus_time/shared/timetable_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:schedule_core/schedule_core.dart';
import 'package:schedule_storage/schedule_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late ScheduleDatabase db;
  late AppController app;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    db = ScheduleDatabase.memory();
    app = AppController(
      imports: DriftImportRepository(db),
      courses: DriftCourseRepository(db),
      taskStore: DriftTaskRepository(db),
      settings: DriftSettingsRepository(db),
      preferences: await SharedPreferences.getInstance(),
      clock: () => DateTime.utc(2026, 9, 7),
    );
  });
  tearDown(() async {
    app.dispose();
    await db.close();
  });
  test(
    'default timetable is accurate, atomic and does not overwrite edits',
    () async {
      await ensureDefaultTimetable(db);
      await app.initialize();
      final s = app.snapshot!;
      expect(s.semester.name, '黄锐的课表');
      expect(s.semester.startDate, DateTime.utc(2026, 8, 31));
      expect(s.semester.weekStartDay, 1);
      expect(s.schedules.length, 22);
      expect(s.courses.length, 14);
      expect(s.classTimes.length, 11);
      expect(s.daysOff.length, 3);
      expect(app.timeline(DateTime.utc(2026, 9, 25)).items, isEmpty);
      expect(s.courses.any((c) => c.name.contains('大学英语')), isTrue);
      await app.renameTimetable(s.semester.id, '我的秋季课表');
      await app.saveColor(s.courses.first.id, '#12ABEF');
      await ensureDefaultTimetable(db);
      await app.refresh();
      expect(app.semesters.length, 1);
      expect(app.snapshot!.semester.name, '我的秋季课表');
      expect(app.snapshot!.courses.first.color, '#12ABEF');
    },
  );
  test(
    'imported complete timetable, name, colors and selection stay independent',
    () async {
      await ensureDefaultTimetable(db);
      await app.initialize();
      final original = app.snapshot!;
      final raw = jsonDecode(
        await rootBundle.loadString('assets/default_timetable.json'),
      ) as Map<String, dynamic>;
      raw['sourceSha256'] = List.filled(64, 'a').join();
      app.draft = await app.imports.createDraft(PdfScheduleParser().parse(raw));
      await app.editDraft(
        semester: {'name': '新课表', 'weekStartDay': 1, 'startDate': '2026-08-31'},
        exclusions: {'other_1': '测试明确排除'},
      );
      await app.confirmDraft();
      final added = app.snapshot!;
      expect(app.semesters.length, 2);
      expect(added.schedules.length, 22);
      expect(added.courses.first.id, isNot(original.courses.first.id));
      await app.renameTimetable(added.semester.id, '第二张课表');
      final course = added.courses.first;
      await app.saveColor(course.id, '#FFFFFF');
      expect(app.snapshot!.courses.first.color, '#FFFFFF');
      final rule = added.schedules.firstWhere((s) => s.courseId == course.id);
      final date = SemesterWeekCalculator(added.semester)
          .getDateRangeForWeek(rule.activeWeeks.first)
          .start;
      await app.saveTimes(
        original.classTimes
            .map(
              (t) => ClassTimeConfig(
                semesterId: added.semester.id,
                section: t.section,
                startTime: t.startTime,
                endTime: t.endTime,
              ),
            )
            .toList(),
      );
      final occurrences = [
        for (var d = 0; d < 7; d++)
          ...app.timeline(date.add(Duration(days: d))).items,
      ].where((i) => i.title == course.name);
      expect(occurrences, isNotEmpty);
      expect(occurrences.every((i) => i.color == '#FFFFFF'), isTrue);
      await app.selectSemester(original.semester.id);
      expect(app.snapshot!.courses.first.color, original.courses.first.color);
      await app.selectSemester(added.semester.id);
      final reopened = AppController(
        imports: app.imports,
        courses: app.courses,
        taskStore: app.taskStore,
        settings: app.settings,
        preferences: app.preferences,
      );
      await reopened.initialize();
      expect(reopened.snapshot!.semester.name, '第二张课表');
      expect(reopened.snapshot!.courses.first.color, '#FFFFFF');
      reopened.dispose();
      await app.confirmDraft();
      expect(app.semesters.length, 2);
      await expectLater(
        app.renameTimetable(added.semester.id, '  '),
        throwsFormatException,
      );
    },
  );
  test(
    'default bootstrap never confirms a pre-existing edited preview',
    () async {
      final raw = jsonDecode(
        await rootBundle.loadString('assets/default_timetable.json'),
      ) as Map<String, dynamic>;
      final draft = await app.imports.createDraft(
        PdfScheduleParser().parse(raw),
      );
      final edited = await app.imports.editDraft(
        draft.id,
        expectedRevision: draft.revision,
        semesterChanges: {'name': '尚未确认'},
        reason: '编辑预览',
      );
      await ensureDefaultTimetable(db);
      expect(await app.courses.listSemesters(), isEmpty);
      final stored = (await app.imports.readDraft(draft.id))!;
      expect(stored.committed, isFalse);
      expect(stored.revision, edited.revision);
      expect(stored.reviewed.semester['name'], '尚未确认');
    },
  );
  testWidgets(
    'picker supports hex validation, HSV, palette and explicit save',
    (tester) async {
      String? saved;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () async {
                  saved = await showDialog<String>(
                    context: context,
                    builder: (_) => const CourseColorPicker(
                      name: '测试课程',
                      initial: Colors.green,
                    ),
                  );
                },
                child: const Text('选色'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('选色'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const ValueKey('course-hex')), '#ggg');
      await tester.tap(find.text('保存'));
      await tester.pumpAndSettle();
      expect(saved, isNull);
      expect(find.text('请输入有效 HEX 色值'), findsOneWidget);
      await tester.enterText(find.byKey(const ValueKey('course-hex')), '#abc');
      await tester.pump();
      await tester.tap(find.text('保存'));
      await tester.pumpAndSettle();
      expect(saved, '#AABBCC');
      expect(parseCourseHex('12345678'), isNull);
      expect(readableCourseText(Colors.white), Colors.black);
      expect(readableCourseText(Colors.black), Colors.white);
      await tester.tap(find.text('选色'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('color-plane')));
      await tester.pump();
      expect(find.byType(Slider), findsNWidgets(3));
      await tester.ensureVisible(find.bySemanticsLabel('快捷颜色 #2979FF'));
      await tester.tap(find.bySemanticsLabel('快捷颜色 #2979FF'));
      await tester.pump();
      await tester.tap(find.text('保存'));
      await tester.pumpAndSettle();
      expect(saved, '#2979FF');
    },
  );
  testWidgets('week header dropdown switches between complete timetables', (
    tester,
  ) async {
    late String originalId;
    await tester.runAsync(() async {
      await ensureDefaultTimetable(db);
      await app.initialize();
      originalId = app.snapshot!.semester.id;
      final raw = jsonDecode(
        await rootBundle.loadString('assets/default_timetable.json'),
      ) as Map<String, dynamic>;
      raw['sourceSha256'] = List.filled(64, 'b').join();
      app.draft = await app.imports.createDraft(PdfScheduleParser().parse(raw));
      await app.editDraft(
        semester: {
          'name': '另一张课表',
          'weekStartDay': 1,
          'startDate': '2026-08-31',
        },
        exclusions: {'other_1': '测试排除'},
      );
      await app.confirmDraft();
    });
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AnimatedBuilder(
            animation: app,
            builder: (_, child) => TimetableSelector(app: app),
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(const ValueKey('timetable-selector')));
    await tester.pumpAndSettle();
    await tester.runAsync(() async {
      await tester.tap(find.text('黄锐的课表').last);
    });
    await tester.pumpAndSettle();
    expect(app.snapshot!.semester.id, originalId);
    expect(app.snapshot!.schedules.length, 22);
    expect(tester.takeException(), isNull);
  });
  testWidgets('week header rename persists and empty names stay in editor', (
    tester,
  ) async {
    await tester.runAsync(() async {
      await ensureDefaultTimetable(db);
      await app.initialize();
    });
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AnimatedBuilder(
            animation: app,
            builder: (_, child) => TimetableSelector(app: app),
          ),
        ),
      ),
    );
    await tester.tap(find.byTooltip('修改课表名称'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), ' ');
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();
    expect(find.text('请输入课表名称'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField), '新的名称');
    await tester.runAsync(() async {
      await tester.tap(find.text('保存'));
    });
    await tester.pumpAndSettle();
    expect(app.snapshot!.semester.name, '新的名称');
    expect(find.text('新的名称'), findsOneWidget);
  });
}
