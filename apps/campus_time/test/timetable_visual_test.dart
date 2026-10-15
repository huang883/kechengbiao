import 'dart:io';
import 'dart:ui' as ui;

import 'package:campus_time/app.dart';
import 'package:campus_time/application/default_timetable.dart';
import 'package:campus_time/shared/course_color_picker.dart';
import 'package:campus_time/application/app_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:schedule_storage/schedule_storage.dart';

void main() {
  testWidgets('render default timetable and custom picker at phone size', (
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
    await capture('timetable-selector');
    final item = app.timeline(app.now).items.first;
    final course = app.snapshot!.courses.firstWhere(
      (c) => c.name == item.title,
    );
    final context = tester.element(find.byType(Scaffold).first);
    String? picked;
    final dialog = showDialog<String>(
      context: context,
      builder: (_) =>
          CourseColorPicker(name: course.name, initial: Colors.green),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('course-hex')), '#FAED23');
    tester.testTextInput.hide();
    await tester.pumpAndSettle();
    await capture('course-color-picker');
    await tester.tap(find.text('保存'));
    picked = await dialog;
    await tester.runAsync(() => app.saveColor(course.id, picked!));
    await tester.pumpAndSettle();
    final materials = tester.widgetList<Material>(find.byType(Material));
    expect(
      materials.any(
        (m) => m.color == const Color(0xFFFAED23).withValues(alpha: .88),
      ),
      isTrue,
    );
    await capture('custom-color-week');
    await tester.tap(find.text('今天').last);
    await tester.pumpAndSettle();
    expect(
      tester
          .widgetList<Container>(find.byType(Container))
          .any((c) => c.color == const Color(0xFFFAED23)),
      isTrue,
    );
    await capture('custom-color-today');
    await tester.pumpWidget(const SizedBox.shrink());
    await db.close();
  });
}
