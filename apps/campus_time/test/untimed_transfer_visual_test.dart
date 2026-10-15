import 'package:schedule_core/schedule_core.dart';

import 'dart:io';
import 'dart:ui' as ui;

import 'package:campus_time/app.dart';
import 'package:campus_time/application/default_timetable.dart';
import 'package:campus_time/application/app_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:schedule_storage/schedule_storage.dart';

void main() {
  testWidgets('render untimed task and transferred course editor', (
    tester,
  ) async {
    final db = ScheduleDatabase.memory();
    final app = AppController(
      imports: DriftImportRepository(db),
      courses: DriftCourseRepository(db),
      taskStore: DriftTaskRepository(db),
      settings: DriftSettingsRepository(db),
      clock: () => DateTime.utc(2026, 9, 7, 9, 10),
    );
    await tester.runAsync(() async {
      final font = File('C:/Windows/Fonts/msyh.ttc');
      if (font.existsSync()) {
        final loader = FontLoader('Roboto')
          ..addFont(
            Future.value(ByteData.sublistView(await font.readAsBytes())),
          );
        await loader.load();
      }
      final icons = FontLoader('MaterialIcons')
        ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
      await icons.load();
      await ensureDefaultTimetable(db);
      await app.initialize();
      await app.saveTask(
        TaskEvent(
          id: 'untimed-preview',
          title: '复习本周重点，不指定时间',
          date: DateTime.utc(2026, 9, 7),
        ),
        editing: false,
      );
      final original = app.snapshot!.schedules.firstWhere(
        (s) =>
            s.weekday == 1 && s.startSection == 1 && s.activeWeeks.contains(2),
      );
      await app.saveLessonTransfer(
        LessonTransfer(
          id: 'preview-transfer',
          scheduleId: original.id,
          sourceDate: DateTime.utc(2026, 9, 7),
          targetDate: DateTime.utc(2026, 9, 8),
          sourceStart: 1,
          sourceEnd: 1,
          targetStart: 3,
        ),
      );
    });
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final key = GlobalKey();
    await tester.pumpWidget(
      RepaintBoundary(
        key: key,
        child: ProviderScope(
          overrides: [appProvider.overrideWith((ref) => app)],
          child: const CampusApp(liveClock: false),
        ),
      ),
    );
    await tester.pumpAndSettle();
    Future<void> capture(String name) async {
      expect(tester.takeException(), isNull);
      await tester.runAsync(() async {
        final boundary =
            key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        final image = await boundary.toImage();
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        final file = File('../../output/android/preview-$name.png');
        await file.parent.create(recursive: true);
        await file.writeAsBytes(bytes!.buffer.asUint8List());
        image.dispose();
      });
    }

    await tester.tap(find.text('周课表').last);
    await tester.pumpAndSettle();
    await capture('untimed-week');
    final item = app
        .timeline(DateTime.utc(2026, 9, 8))
        .items
        .singleWhere((i) => i.id.contains('preview-transfer'));
    final card = find
        .byWidgetPredicate(
          (w) => w is Text && (w.data ?? '').startsWith('${item.title}\n10:00'),
        )
        .first;
    await tester.tap(card);
    await tester.pumpAndSettle();
    await capture('transfer-source-default');
    await tester.tap(find.text('只改这次调课'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('自定义钟点'));
    await tester.pumpAndSettle();
    await capture('edited-transfer-clock');
    await tester.tap(find.byTooltip('关闭课程编辑'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('待办').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('复习本周重点，不指定时间'));
    await tester.pumpAndSettle();
    await capture('untimed-task-editor');
    await tester.pumpWidget(const SizedBox.shrink());
    await db.close();
  });
}
