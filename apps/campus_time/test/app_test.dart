import 'dart:convert';
import 'dart:io';

import 'package:campus_time/app.dart';
import 'package:campus_time/application/app_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:schedule_core/schedule_core.dart';
import 'package:schedule_storage/schedule_storage.dart';

void main() {
  late ScheduleDatabase db;
  late AppController app;
  setUp(() async {
    db = ScheduleDatabase.memory();
    app = AppController(
      imports: DriftImportRepository(db),
      courses: DriftCourseRepository(db),
      taskStore: DriftTaskRepository(db),
      settings: DriftSettingsRepository(db),
      clock: () => DateTime.utc(2026, 11, 16, 9),
    );
    await app.initialize();
  });
  tearDown(() async {
    await db.close();
  });
  Future<void> seed() async {
    final parsed = PdfScheduleParser().parse(
      jsonDecode(
        File('assets/default_timetable.json')
            .readAsStringSync(),
      ) as Map<String, dynamic>,
    );
    app.draft = await app.imports.createDraft(parsed);
    await app.editDraft(
      semester: {'weekStartDay': 7},
      exclusions: {'other_1': '测试输入：明确排除未排课记录'},
    );
    await app.confirmDraft();
  }

  Future<void> mount(WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
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

  testWidgets('empty installation permits tasks and never imports silently', (
    tester,
  ) async {
    await mount(tester);
    expect(find.text('从一份课表开始'), findsOneWidget);
    await tester.tap(find.text('导入'));
    await tester.pumpAndSettle();
    expect(find.text('先预览，再保存'), findsOneWidget);
    expect(app.snapshot, isNull);
    await tester.tap(find.text('设置').last);
    await tester.pumpAndSettle();
    expect(find.text('课程与待办提醒'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'real PDF has a visible explicit week-start confirmation and accurate remaining issues',
    (tester) async {
      await tester.runAsync(() async {
        final parsed = PdfScheduleParser().parse(
          jsonDecode(
            File(
              'assets/default_timetable.json',
            ).readAsStringSync(),
          ) as Map<String, dynamic>,
        );
        app.draft = await app.imports.createDraft(parsed);
      });
      await mount(tester);
      await tester.tap(find.text('导入').last);
      await tester.pumpAndSettle();
      expect(find.text('确认周起始日').hitTestable(), findsOneWidget);
      await tester.tap(find.text('确认周起始日'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<FilledButton>(find.widgetWithText(FilledButton, '确认并保存'))
            .onPressed,
        isNull,
      );
      await tester.tap(find.text('取消'));
      await tester.pumpAndSettle();
      expect(app.draft!.reviewed.semester['weekStartDay'], unclear);
      await tester.tap(find.text('确认周起始日'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ChoiceChip, '星期日'));
      await tester.pumpAndSettle();
      await tester.runAsync(() async {
        await tester.tap(find.text('确认并保存'));
        await Future<void>.delayed(const Duration(milliseconds: 100));
      });
      await tester.pumpAndSettle();
      expect(app.draft!.reviewed.semester['weekStartDay'], 7);
      expect(app.snapshot, isNull);
      expect(find.text('已确认：每周从星期日开始'), findsOneWidget);
      expect(
        app.draftIssues.where((i) => i.code == 'weekStartDayUnclear'),
        isEmpty,
      );
      await tester.scrollUntilVisible(
        find.textContaining('仍有 1 条课程信息不完整'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.textContaining('仍有 1 条课程信息不完整'), findsOneWidget);
      await tester.runAsync(
        () => app.editDraft(exclusions: {'other_1': '测试明确排除没有排课信息的记录'}),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('我已检查课程与学期信息'),
        600,
        scrollable: find.byType(Scrollable).first,
        maxScrolls: 60,
      );
      await tester.tap(find.text('我已检查课程与学期信息'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('确认导入 22 条排课'));
      await tester.pumpAndSettle();
      await tester.runAsync(() async {
        await tester.tap(find.text('确认导入 22 条排课'));
        await Future<void>.delayed(const Duration(milliseconds: 100));
      });
      await tester.pumpAndSettle();
      expect(app.snapshot!.schedules.length, 22);
      expect(app.snapshot!.semester.weekStartDay, 7);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'changing week recomputes actual courses; class times are explicit',
    (tester) async {
      await tester.runAsync(seed);
      app.changeWeek(11);
      await mount(tester);
      await tester.tap(find.text('周课表'));
      await tester.pumpAndSettle();
      expect(find.text('0 条课程安排 · 0 项未完成待办'), findsOneWidget);
      await tester.tap(find.byTooltip('下一周'));
      await tester.pumpAndSettle();
      expect(find.text('第 12 周'), findsOneWidget);
      expect(find.text('14 条课程安排 · 0 项未完成待办'), findsOneWidget);
      expect(app.snapshot!.classTimes, isEmpty);
      await tester.tap(find.text('设置').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('学校上课时间'));
      await tester.pumpAndSettle();
      expect(find.text('开始'), findsWidgets);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('arbitrary minutes and conflicting tasks remain savable', (
    tester,
  ) async {
    await tester.runAsync(() async {
      await app.saveTask(
        TaskEvent(
          id: 'existing',
          title: '已有约定',
          date: app.now,
          startTime: '10:00',
          endTime: '11:00',
        ),
        editing: false,
      );
    });
    await mount(tester);
    await tester.tap(find.text('待办').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('新增'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, '做什么'), '复习');
    await tester.enterText(find.widgetWithText(TextField, '开始 HH:mm'), '10:17');
    await tester.enterText(find.widgetWithText(TextField, '结束 HH:mm'), '11:35');
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.textContaining('时间冲突'));
    await tester.pumpAndSettle();
    expect(find.textContaining('你仍然可以保存'), findsOneWidget);
    await tester.ensureVisible(find.text('保存待办'));
    await tester.pumpAndSettle();
    await tester.runAsync(() async {
      await tester.tap(find.text('保存待办'));
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });
    await tester.pumpAndSettle();
    expect(app.tasks.length, 2);
    expect(app.tasks.singleWhere((t) => t.title == '复习').startTime, '10:17');
    expect(find.text('复习'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('editing the preview invalidates its confirmation checkbox', (
    tester,
  ) async {
    await tester.runAsync(() async {
      final parsed = PdfScheduleParser().parse(
        jsonDecode(
          File(
            'assets/default_timetable.json',
          ).readAsStringSync(),
        ) as Map<String, dynamic>,
      );
      app.draft = await app.imports.createDraft(
        ParsedSchedule(parsed.sourceSha256, parsed.semester, [
          parsed.records.first,
        ]),
      );
      await app.editDraft(semester: {'weekStartDay': 7});
    });
    await mount(tester);
    await tester.tap(find.text('导入').last);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('我已检查课程与学期信息'),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('我已检查课程与学期信息'));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, '确认导入 1 条排课'))
          .onPressed,
      isNotNull,
    );
    expect(app.snapshot, isNull);
    await tester.runAsync(() => app.editDraft(semester: {'name': '更正后的学期'}));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('我已检查课程与学期信息'),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, '确认导入 1 条排课'))
          .onPressed,
      isNull,
    );
    await tester.tap(find.text('我已检查课程与学期信息'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('确认导入 1 条排课'));
    await tester.pumpAndSettle();
    await tester.runAsync(() async {
      await tester.tap(find.text('确认导入 1 条排课'));
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });
    await tester.pumpAndSettle();
    expect(app.snapshot!.schedules.length, 1);
    expect(app.snapshot!.semester.name, '更正后的学期');
    expect(tester.takeException(), isNull);
  });
  test(
    'controller persists confirmation, minute times, completion and settings',
    () async {
      await seed();
      final id = app.snapshot!.semester.id;
      await app.saveTimes([
        ClassTimeConfig(
          semesterId: id,
          section: 1,
          startTime: '08:07',
          endTime: '08:52',
        ),
      ]);
      await app.saveTask(
        TaskEvent(
          id: 't',
          title: '精确分钟',
          date: app.now,
          startTime: '10:17',
          endTime: '11:35',
        ),
        editing: false,
      );
      await app.completeTask('t', true);
      final reopened = AppController(
        imports: DriftImportRepository(db),
        courses: DriftCourseRepository(db),
        taskStore: DriftTaskRepository(db),
        settings: DriftSettingsRepository(db),
        clock: app.clock,
      );
      await reopened.initialize();
      expect(reopened.snapshot!.schedules.length, 22);
      expect(reopened.snapshot!.classTimes.single.startTime, '08:07');
      expect(reopened.tasks.single.completed, isTrue);
      expect(reopened.tasks.single.endTime, '11:35');
      reopened.dispose();
      app.dispose();
    },
  );
  testWidgets(
    'Monday school dates and holiday banner use filtered course counts',
    (tester) async {
      await tester.runAsync(() async {
        await seed();
        await app.saveCalendar(DateTime.utc(2026, 8, 31), 1);
        await app.saveDayOff(
          ClassDayOff(date: DateTime.utc(2026, 10, 1), reason: '国庆节'),
        );
      });
      app.changeWeek(5);
      await mount(tester);
      await tester.tap(find.text('周课表').last);
      await tester.pumpAndSettle();
      expect(find.text('2026-09-28 — 2026-10-04'), findsOneWidget);
      expect(find.text('11 条课程安排 · 0 项未完成待办'), findsOneWidget);
      expect(find.textContaining('停课：10/1 国庆节'), findsOneWidget);
      expect(
        app.timeline(DateTime.utc(2026, 10, 1)).unconfiguredSchedules,
        isEmpty,
      );
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'saved replacement provenance and unfinished short tasks appear in week grid',
    (tester) async {
      await tester.runAsync(() async {
        await seed();
        await app.saveCalendar(DateTime.utc(2026, 8, 31), 1);
        await app.saveTimes([
          ClassTimeConfig(
            semesterId: app.snapshot!.semester.id,
            section: 1,
            startTime: '08:00',
            endTime: '08:45',
          ),
          ClassTimeConfig(
            semesterId: app.snapshot!.semester.id,
            section: 2,
            startTime: '08:55',
            endTime: '09:40',
          ),
        ]);
        await app.saveReplacement(
          ClassDayReplacement(
            sourceDate: DateTime.utc(2026, 10, 7),
            targetDate: DateTime.utc(2026, 11, 16),
          ),
        );
        for (final done in [false, true]) {
          await app.saveTask(
            TaskEvent(
              id: '$done',
              title: done ? 'completed-hidden' : 'pending-short',
              date: DateTime.utc(2026, 11, 16),
              startTime: '08:15',
              endTime: '08:17',
              completed: done,
            ),
            editing: false,
          );
        }
      });
      await mount(tester);
      await tester.tap(find.text('周课表').last);
      await tester.pumpAndSettle();
      expect(find.textContaining('由第 6 周星期三（10/7）调入'), findsWidgets);
      expect(find.textContaining('1 项未完成待办'), findsOneWidget);
      expect(find.textContaining('completed-hidden'), findsNothing);
      final task = find.textContaining('待办 · pending-short');
      expect(task, findsOneWidget);
      expect(find.textContaining('08:15\n待办 · pending-short'), findsOneWidget);
      final position = tester.widget<Positioned>(
        find.ancestor(of: task, matching: find.byType(Positioned)).first,
      );
      expect(position.top, 75 * 1.25); // 08:15 on axis beginning at 07:00.
      expect(position.height, greaterThanOrEqualTo(48));
      expect(tester.takeException(), isNull);
      await tester.runAsync(() => app.completeTask('false', true));
      await tester.pumpAndSettle();
      expect(find.textContaining('待办 · pending-short'), findsNothing);
    },
  );
  testWidgets('replacement list closes by button and downward list drag', (
    tester,
  ) async {
    await tester.runAsync(seed);
    await mount(tester);
    await tester.tap(find.text('周课表').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('调课'));
    await tester.pumpAndSettle();
    expect(find.text('添加整天调课'), findsOneWidget);
    await tester.tap(find.widgetWithText(TextButton, '关闭'));
    await tester.pumpAndSettle();
    expect(find.text('添加整天调课'), findsNothing);
    await tester.tap(find.text('调课'));
    await tester.pumpAndSettle();
    final list = find.descendant(
      of: find.byType(DraggableScrollableSheet),
      matching: find.byType(ListView),
    );
    await tester.dragFrom(
      tester.getTopLeft(list) + const Offset(120, 100),
      const Offset(0, 620),
    );
    await tester.pumpAndSettle();
    expect(find.text('添加整天调课'), findsNothing);
    expect(app.snapshot!.replacements, isEmpty);
  });
  testWidgets(
    'single lesson form previews source week and persists default move',
    (tester) async {
      await tester.runAsync(() async {
        await seed();
        await app.saveCalendar(DateTime.utc(2026, 8, 31), 1);
        await app.saveTimes([
          for (var i = 1; i <= 11; i++)
            ClassTimeConfig(
              semesterId: app.snapshot!.semester.id,
              section: i,
              startTime: '${(i + 6).toString().padLeft(2, '0')}:00',
              endTime: '${(i + 6).toString().padLeft(2, '0')}:45',
            ),
        ]);
      });
      await mount(tester);
      await tester.tap(find.text('周课表').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('调课'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('添加单节调课'));
      await tester.pumpAndSettle();
      expect(find.text('单节调课'), findsOneWidget);
      expect(find.text('来源课程'), findsOneWidget);
      expect(
        tester.widget<SwitchListTile>(find.byType(SwitchListTile)).value,
        isFalse,
      );
      await tester.enterText(find.byType(TextField).at(1), '2026-11-17');
      await tester.pumpAndSettle();
      await tester.tap(find.text('预览单节调课'));
      await tester.pumpAndSettle();
      expect(find.text('确认单节调课'), findsOneWidget);
      expect(find.textContaining('第 12 周星期一第 1—2 节'), findsOneWidget);
      await tester.runAsync(() async {
        await tester.tap(find.text('确认保存'));
        await Future<void>.delayed(const Duration(milliseconds: 150));
      });
      await tester.pumpAndSettle();
      expect(app.snapshot!.lessonTransfers.single.keepSource, isFalse);
      expect(find.textContaining('原课所选节次已移走'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'empty times prefill school defaults and saved bell ticks follow custom times',
    (tester) async {
      await tester.runAsync(seed);
      await mount(tester);
      await tester.tap(find.text('设置').last);
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('学校上课时间'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('学校上课时间'));
      await tester.pumpAndSettle();
      expect(find.text('08:00'), findsOneWidget);
      expect(find.text('08:45'), findsOneWidget);
      expect(
        app.snapshot!.classTimes,
        isEmpty,
      ); // Prefill is a draft until saved.
      await tester.scrollUntilVisible(
        find.text('保存作息'),
        500,
        scrollable: find
            .byWidgetPredicate(
              (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
            )
            .last,
        maxScrolls: 30,
      );
      await tester.runAsync(() async {
        await tester.tap(find.text('保存作息'));
        await Future<void>.delayed(const Duration(milliseconds: 100));
      });
      await tester.pumpAndSettle();
      expect(app.snapshot!.classTimes.length, 11);
      expect(app.snapshot!.classTimes.last.endTime, '21:55');
      await tester.tap(find.text('周课表').last);
      await tester.pumpAndSettle();
      expect(find.text('08:00 上'), findsOneWidget);
      expect(find.text('08:45 下'), findsOneWidget);
      expect(find.text('21:55 下'), findsOneWidget);
      await tester.runAsync(
        () => app.saveTimes([
          ClassTimeConfig(
            semesterId: app.snapshot!.semester.id,
            section: 1,
            startTime: '08:10',
            endTime: '08:50',
          ),
        ]),
      );
      await tester.pumpAndSettle();
      expect(find.text('08:50 下'), findsOneWidget);
      expect(find.text('08:45 下'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'Pomodoro is available without import and retains state across tabs',
    (tester) async {
      await mount(tester);
      expect(find.byType(NavigationDestination), findsNWidgets(6));
      await tester.tap(find.text('番茄钟').last);
      await tester.pumpAndSettle();
      expect(find.text('25:00'), findsOneWidget);
      await tester.runAsync(() => app.pomodoro.start());
      await tester.pumpAndSettle();
      expect(find.text('暂停'), findsOneWidget);
      await tester.tap(find.text('待办').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('番茄钟').last);
      await tester.pumpAndSettle();
      expect(app.pomodoro.running, isTrue);
      await tester.runAsync(() => app.pomodoro.pause());
      await tester.pumpAndSettle();
      expect(find.text('继续'), findsOneWidget);
      await tester.runAsync(() => app.pomodoro.reset());
      await tester.pumpAndSettle();
      expect(find.text('25:00'), findsOneWidget);
      await tester.runAsync(() async {
        await tester.tap(find.text('短休息'));
        await Future<void>.delayed(const Duration(milliseconds: 100));
      });
      await tester.pumpAndSettle();
      expect(find.text('05:00'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
