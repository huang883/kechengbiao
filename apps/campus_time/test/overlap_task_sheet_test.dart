import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:campus_time/app.dart';
import 'package:campus_time/application/app_controller.dart';
import 'package:campus_time/application/default_timetable.dart';
import 'package:campus_time/features/tasks/tasks_page.dart';
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
  testWidgets(
    'overlapping tasks preserve course width and clock position; weekdays stay fixed',
    (tester) async {
      tester.view.physicalSize = const Size(430, 932);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.runAsync(() async {
        final font = File('C:/Windows/Fonts/msyh.ttc');
        if (font.existsSync()) {
          await (FontLoader('Roboto')..addFont(
                Future.value(ByteData.sublistView(await font.readAsBytes())),
              ))
              .load();
        }
        await (FontLoader(
          'MaterialIcons',
        )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
        await ensureDefaultTimetable(db);
        await app.initialize();
      });
      final captureKey = GlobalKey();
      await tester.pumpWidget(
        RepaintBoundary(
          key: captureKey,
          child: ProviderScope(
            overrides: [appProvider.overrideWith((ref) => app)],
            child: const CampusApp(liveClock: false),
          ),
        ),
      );
      await tester.tap(find.text('周课表').last);
      await tester.pumpAndSettle();
      final course = app
          .timeline(app.now)
          .items
          .firstWhere((i) => i.sourceType == 'course');
      final finder = find.byKey(ValueKey('week-card-${course.id}'));
      final before = tester.getSize(finder);
      await tester.runAsync(() async {
        await app.saveTask(
          editing: false,
          TaskEvent(
            id: 'overlap',
            title: '重叠待办',
            date: app.now,
            startTime: '08:10',
            endTime: '08:40',
          ),
        );
      });
      await tester.pumpAndSettle();
      expect(tester.getSize(finder).width, closeTo(before.width, .01));
      expect(tester.getSize(finder).height, closeTo(before.height, .01));
      final task = app
          .timeline(app.now)
          .items
          .firstWhere((i) => i.sourceType == 'task');
      final taskFinder = find.byKey(ValueKey('week-card-${task.id}'));
      expect(
        tester.getTopLeft(taskFinder).dy - tester.getTopLeft(finder).dy,
        closeTo(12.5, .1),
      );
      expect(
        tester.getTopLeft(taskFinder).dx,
        greaterThan(tester.getTopLeft(finder).dx + before.width),
      );
      await tester.runAsync(() async {
        final image =
            await (captureKey.currentContext!.findRenderObject()!
                    as RenderRepaintBoundary)
                .toImage();
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        await File('../../output/android/preview-overlap-fixed.png')
            .writeAsBytes(bytes!.buffer.asUint8List());
        image.dispose();
      });
      final headerY = tester.getTopLeft(find.text('周一')).dy;
      final vertical = find
          .byWidgetPredicate(
            (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
          )
          .last;
      await tester.drag(vertical, const Offset(0, -200));
      await tester.pumpAndSettle();
      expect(tester.getTopLeft(find.text('周一')).dy, headerY);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets('task form can be dragged down to dismiss without saving', (
    tester,
  ) async {
    await tester.runAsync(app.initialize);
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => openTaskEditor(context, app),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('新建待办'), findsOneWidget);
    await tester.enterText(find.widgetWithText(TextField, '做什么'), '未保存内容');
    tester.view.viewInsets = const FakeViewPadding(bottom: 250);
    addTearDown(tester.view.resetViewInsets);
    await tester.pumpAndSettle();
    await tester.fling(find.text('新建待办'), const Offset(0, 700), 1800);
    await tester.pumpAndSettle();
    expect(find.text('新建待办'), findsNothing);
    expect(app.tasks, isEmpty);
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('关闭待办窗口'));
    await tester.pumpAndSettle();
    expect(find.text('新建待办'), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
}
