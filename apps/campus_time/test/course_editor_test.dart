import 'package:campus_time/app.dart';
import 'package:campus_time/application/app_controller.dart';
import 'package:campus_time/application/default_timetable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:schedule_storage/schedule_storage.dart';

void main() {
  testWidgets(
    'tap blank grid creates course, card edits room/name/minute times with white text',
    (tester) async {
      final db = ScheduleDatabase.memory();
      final app = AppController(
        imports: DriftImportRepository(db),
        courses: DriftCourseRepository(db),
        taskStore: DriftTaskRepository(db),
        settings: DriftSettingsRepository(db),
        clock: () => DateTime.utc(2026, 9, 7),
      );
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
      await tester.tap(find.text('周课表').last);
      await tester.pumpAndSettle();
      final origin = tester.getTopLeft(
        find.byKey(const ValueKey('course-grid-empty')),
      );
      await tester.tapAt(origin + const Offset(120, 120));
      await tester.pumpAndSettle();
      expect(find.text('新建课程'), findsOneWidget);
      await tester.enterText(find.byKey(const ValueKey('course-name')), '手动课程');
      await tester.enterText(
        find.byKey(const ValueKey('course-room')),
        '实验楼 101',
      );
      await tester.ensureVisible(find.text('保存课程'));
      await tester.runAsync(() async {
        await tester.tap(find.text('保存课程'));
        await Future<void>.delayed(const Duration(milliseconds: 200));
      });
      await tester.pumpAndSettle();
      final created = app.snapshot!.courses.singleWhere(
        (c) => c.name == '手动课程',
      );
      final schedule = app.snapshot!.schedules.singleWhere(
        (s) => s.courseId == created.id,
      );
      expect(schedule.weekday, 2);
      expect(schedule.activeWeeks, [2]);
      expect(schedule.classroom, '实验楼 101');
      final card = find.byWidgetPredicate(
        (w) => w is Text && (w.data ?? '').startsWith('手动课程\n'),
      );
      expect(tester.widget<Text>(card).style!.color, Colors.white);
      await tester.tap(card);
      await tester.pumpAndSettle();
      expect(find.text('编辑课程'), findsOneWidget);
      await tester.enterText(
        find.byKey(const ValueKey('course-name')),
        '修改后的课程',
      );
      await tester.enterText(
        find.byKey(const ValueKey('course-room')),
        '教学楼 202',
      );
      await tester.tap(find.text('自定义钟点'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('上课 08:00'));
      await tester.pumpAndSettle();
      final inputs = find.descendant(
        of: find.byType(TimePickerDialog),
        matching: find.byType(TextFormField),
      );
      await tester.enterText(inputs.at(0), '08');
      await tester.enterText(inputs.at(1), '12');
      await tester.tap(find.text('确定'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('保存课程'));
      await tester.runAsync(() async {
        await tester.tap(find.text('保存课程'));
        await Future<void>.delayed(const Duration(milliseconds: 200));
      });
      await tester.pumpAndSettle();
      final updated = app.snapshot!.schedules.singleWhere(
        (s) => s.id == schedule.id,
      );
      expect(updated.customStartTime, '08:12');
      expect(updated.customEndTime, '08:45');
      expect(updated.classroom, '教学楼 202');
      expect(
        app.snapshot!.courses.singleWhere((c) => c.id == created.id).name,
        '修改后的课程',
      );
      expect(app.snapshot!.classTimes.first.startTime, '08:00');
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await db.close();
    },
  );
}
