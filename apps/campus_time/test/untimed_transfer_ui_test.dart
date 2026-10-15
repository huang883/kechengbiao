import 'package:campus_time/app.dart';
import 'package:campus_time/application/app_controller.dart';
import 'package:campus_time/application/default_timetable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:schedule_core/schedule_core.dart';
import 'package:schedule_storage/schedule_storage.dart';

void main() {
  late ScheduleDatabase db;
  late AppController app;
  setUp(() {
    db = ScheduleDatabase.memory();
    app = AppController(
      imports: DriftImportRepository(db),
      courses: DriftCourseRepository(db),
      taskStore: DriftTaskRepository(db),
      settings: DriftSettingsRepository(db),
      clock: () => DateTime.utc(2026, 9, 7),
    );
  });
  tearDown(() async {
    await db.close();
  });
  Future<void> mount(WidgetTester tester) async {
    await tester.runAsync(() async {
      await ensureDefaultTimetable(db);
      await app.initialize();
    });
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [appProvider.overrideWith((ref) => app)],
        child: const CampusApp(liveClock: false),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'untimed task saves without clocks, appears today and week, completes from week',
    (tester) async {
      await mount(tester);
      await tester.tap(find.text('待办').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('新增'));
      await tester.pumpAndSettle();
      await tester.enterText(find.widgetWithText(TextField, '做什么'), '不定时复习');
      await tester.tap(find.text('指定时间'));
      await tester.pumpAndSettle();
      expect(find.text('开始 HH:mm'), findsNothing);
      expect(find.text('提前提醒'), findsNothing);
      await tester.ensureVisible(find.text('保存待办'));
      await tester.runAsync(() async {
        await tester.tap(find.text('保存待办'));
        await Future<void>.delayed(const Duration(milliseconds: 200));
      });
      await tester.pumpAndSettle();
      final task = app.tasks.single;
      expect(task.hasTime, isFalse);
      expect(task.reminderMinutes, isNull);
      expect(
        app.timeline(app.now).items.any((i) => i.sourceType == 'task'),
        isFalse,
      );
      expect(app.conflicts(task), isEmpty);
      await tester.tap(find.text('今天').last);
      await tester.pumpAndSettle();
      // Navigation selection is by NavigationDestination, not the tasks filter.
      await tester.tap(find.byIcon(Icons.wb_sunny_outlined).last);
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('不定时复习'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('不指定时间的待办'), findsOneWidget);
      await tester.tap(find.text('周课表').last);
      await tester.pumpAndSettle();
      expect(find.text('不定时复习'), findsOneWidget);
      await tester.runAsync(() async {
        await tester.tap(find.byType(Checkbox).first);
        await Future<void>.delayed(const Duration(milliseconds: 200));
      });
      await tester.pumpAndSettle();
      expect(app.tasks.single.completed, isTrue);
      expect(find.text('不定时复习'), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
  testWidgets(
    'click moved lesson edits only target clock and classroom, preserving source',
    (tester) async {
      await mount(tester);
      final original = app.snapshot!.schedules.firstWhere(
        (s) =>
            s.weekday == 1 && s.startSection == 1 && s.activeWeeks.contains(2),
      );
      await tester.runAsync(
        () => app.saveLessonTransfer(
          LessonTransfer(
            id: 'move-test',
            scheduleId: original.id,
            sourceDate: DateTime.utc(2026, 9, 7),
            targetDate: DateTime.utc(2026, 9, 8),
            sourceStart: 1,
            sourceEnd: 1,
            targetStart: 3,
          ),
        ),
      );
      await tester.tap(find.text('周课表').last);
      await tester.pumpAndSettle();
      final course = app.snapshot!.courses.singleWhere(
        (c) => c.id == original.courseId,
      );
      final card = find.byWidgetPredicate(
        (w) => w is Text && (w.data ?? '').startsWith('${course.name}\n10:00'),
      );
      await tester.tap(card);
      await tester.pumpAndSettle();
      expect(find.text('编辑原排课'), findsOneWidget);
      await tester.tap(find.text('只改这次调课'));
      await tester.pumpAndSettle();
      expect(find.text('编辑这次调课'), findsOneWidget);
      await tester.enterText(
        find.byKey(const ValueKey('course-room')),
        '调课新教室',
      );
      await tester.tap(find.text('自定义钟点'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('上课 10:00'));
      await tester.pumpAndSettle();
      final inputs = find.descendant(
        of: find.byType(TimePickerDialog),
        matching: find.byType(TextFormField),
      );
      await tester.enterText(inputs.at(1), '12');
      await tester.tap(find.text('确定'));
      await tester.pumpAndSettle();
      await tester.runAsync(() async {
        await tester.tap(find.text('保存课程'));
        await Future<void>.delayed(const Duration(milliseconds: 200));
      });
      await tester.pumpAndSettle();
      final t = app.snapshot!.lessonTransfers.single;
      expect(t.targetStartTime, '10:12');
      expect(t.targetClassroom, '调课新教室');
      final source = app.snapshot!.schedules.singleWhere(
        (s) => s.id == original.id,
      );
      expect(source.customStartTime, isNull);
      expect(source.classroom, original.classroom);
      expect(t.sourceDate, DateTime.utc(2026, 9, 7));
      expect(t.keepSource, isFalse);
      // Reopen: source is always the default, and saving it must retain target timing.
      final movedCard = find.byWidgetPredicate(
        (w) => w is Text && (w.data ?? '').startsWith('${course.name}\n10:12'),
      );
      await tester.tap(movedCard);
      await tester.pumpAndSettle();
      expect(find.text('编辑原排课'), findsOneWidget);
      await tester.enterText(
        find.byKey(const ValueKey('course-room')),
        '原排课新地点',
      );
      await tester.tap(find.text('只改这次调课'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<TextField>(find.byKey(const ValueKey('course-room')))
            .controller!
            .text,
        '调课新教室',
      );
      await tester.tap(find.text('修改原排课'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<TextField>(find.byKey(const ValueKey('course-room')))
            .controller!
            .text,
        '原排课新地点',
      );
      await tester.tap(find.text('自定义钟点'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('上课 08:00'));
      await tester.pumpAndSettle();
      final sourceInputs = find.descendant(
        of: find.byType(TimePickerDialog),
        matching: find.byType(TextFormField),
      );
      await tester.enterText(sourceInputs.at(1), '17');
      await tester.tap(find.text('确定'));
      await tester.pumpAndSettle();
      await tester.runAsync(() async {
        await tester.tap(find.text('保存课程'));
        await Future<void>.delayed(const Duration(milliseconds: 200));
      });
      await tester.pumpAndSettle();
      final changed = app.snapshot!.schedules.singleWhere(
        (s) => s.id == original.id,
      );
      expect(changed.customStartTime, '08:17');
      expect(changed.classroom, '原排课新地点');
      expect(changed.activeWeeks, original.activeWeeks);
      expect(app.snapshot!.lessonTransfers.single.targetStartTime, '10:12');
      expect(app.snapshot!.lessonTransfers.single.targetClassroom, '调课新教室');

      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
