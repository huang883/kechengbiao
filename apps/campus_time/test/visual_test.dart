import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:campus_time/app.dart';
import 'package:campus_time/application/app_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:schedule_core/schedule_core.dart';
import 'package:schedule_storage/schedule_storage.dart';

void main() {
  testWidgets('render Today, week, tasks and import on a phone-sized screen', (
    tester,
  ) async {
    final db = ScheduleDatabase.memory();
    final app = AppController(
      imports: DriftImportRepository(db),
      courses: DriftCourseRepository(db),
      taskStore: DriftTaskRepository(db),
      settings: DriftSettingsRepository(db),
      clock: () => DateTime.utc(2026, 11, 16, 9, 10),
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
      await app.initialize();
      app.draft = await app.imports.createDraft(
        PdfScheduleParser().parse(
          jsonDecode(
            File(
              'assets/default_timetable.json',
            ).readAsStringSync(),
          ) as Map<String, dynamic>,
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

    await tester.tap(find.text('导入').last);
    await tester.pumpAndSettle();
    await capture('import-pending');
    await tester.tap(find.text('确认周起始日'));
    await tester.pumpAndSettle();
    await capture('week-start-dialog');
    await tester.tap(find.text('取消'));
    await tester.pumpAndSettle();
    await tester.runAsync(() async {
      await app.editDraft(
        semester: {'weekStartDay': 7},
        exclusions: {'other_1': '视觉测试明确排除'},
      );
      await app.confirmDraft();
      // Synthetic clock times for visual QA only. Never shipped as school defaults.
      final starts = [
        '08:00',
        '08:55',
        '10:00',
        '10:55',
        '14:00',
        '14:55',
        '16:00',
        '16:55',
        '19:00',
        '19:55',
        '20:50',
      ];
      await app.saveTimes([
        for (var i = 0; i < starts.length; i++)
          ClassTimeConfig(
            semesterId: app.snapshot!.semester.id,
            section: i + 1,
            startTime: starts[i],
            endTime: _end(starts[i]),
          ),
      ]);
      await app.saveTask(
        TaskEvent(
          id: 'visual-task',
          title: '整理概率论笔记',
          description: '完成例题，标记还不理解的地方',
          date: app.now,
          startTime: '12:17',
          endTime: '13:05',
        ),
        editing: false,
      );
    });
    await tester.tap(find.text('今天').last);
    await tester.pumpAndSettle();
    await capture('today');
    await tester.tap(find.text('周课表'));
    await tester.pumpAndSettle();
    await capture('schedule');
    await tester.tap(find.text('待办').last);
    await tester.pumpAndSettle();
    await capture('tasks');
    await tester.tap(find.text('导入').last);
    await tester.pumpAndSettle();
    await capture('import');
    await tester.pumpWidget(const SizedBox());
    await tester.runAsync(db.close);
  });
}

String _end(String start) {
  final time = wallTime(
    DateTime.utc(2026),
    start,
  ).add(const Duration(minutes: 45));
  return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
}
