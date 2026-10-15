import 'dart:io';
import 'dart:ui' as ui;

import 'package:campus_time/features/pomodoro/focus_pages.dart';
import 'package:campus_time/features/pomodoro/focus_bridge.dart';
import 'package:campus_time/features/pomodoro/pomodoro_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

class PreviewBridge extends FocusBridge {
  @override
  Future<dynamic> call(String method, [Map<String, dynamic>? args]) async {
    final now = DateTime.now();
    final started = DateTime(
      now.year,
      now.month,
      now.day,
      9,
    ).millisecondsSinceEpoch;
    if (method == 'status') {
      return {
        'active': {'state': 'running', 'planned': 1500000, 'timer_ms': 10000},
        'remaining': 2,
        'ready': true,
      };
    }
    if (method == 'armExit') return 'preview';
    if (method == 'apps') {
      return [
        for (final name in ['课间', '电话', '计算器', '备忘录', '地图'])
          {
            'package': 'preview.$name',
            'name': name,
            'icon': null,
            'selected': name != '地图',
            'mandatory': name == '课间' || name == '电话',
          },
      ];
    }
    if (method == 'history') {
      return {
        'sessions': [
          for (var i = 0; i < 4; i++)
            {
              'id': '$i',
              'started': started - i * 86400000,
              'ended': started - i * 86400000 + 1500000,
              'planned': 1500000,
              'timer_ms': 1500000,
              'restricted_ms': 1500000,
              'state': 'completed',
              'consumed': 0,
            },
        ],
        'segments': [
          for (var i = 0; i < 4; i++)
            {
              'session_id': '$i',
              'start': started - i * 86400000,
              'end': started - i * 86400000 + 1500000,
              'timer_ms': 1500000,
              'restricted_ms': 1500000,
            },
        ],
      };
    }
    return null;
  }
}

void main() {
  testWidgets('render focus whitelist, statistics and exit confirmation', (
    tester,
  ) async {
    await tester.runAsync(() async {
      final f = File('C:/Windows/Fonts/msyh.ttc');
      if (f.existsSync()) {
        await (FontLoader('Roboto')..addFont(
              Future.value(ByteData.sublistView(await f.readAsBytes())),
            ))
            .load();
      }
      await (FontLoader(
        'MaterialIcons',
      )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
    });
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final bridge = PreviewBridge();
    final timer = PomodoroController(focusBridge: bridge);
    await timer.refreshFocus();
    Future<void> capture(String name, Widget child) async {
      final key = GlobalKey();
      await tester.pumpWidget(
        RepaintBoundary(
          key: key,
          child: MaterialApp(
            theme: ThemeData(
              useMaterial3: true,
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFF247B68),
              ),
              scaffoldBackgroundColor: const Color(0xFFF7F8F3),
            ),
            home: child,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.runAsync(() async {
        final image =
            await (key.currentContext!.findRenderObject()!
                    as RenderRepaintBoundary)
                .toImage();
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        final file = File('../../output/android/preview-focus-$name.png');
        await file.parent.create(recursive: true);
        await file.writeAsBytes(bytes!.buffer.asUint8List());
        image.dispose();
      });
    }

    await capture('whitelist', FocusWhitelistPage(bridge: bridge));
    await capture('statistics', FocusStatisticsPage(bridge: bridge));
    await capture(
      'exit',
      Scaffold(
        body: FocusExitDialog(timer: timer, elapsedMilliseconds: () => 0),
      ),
    );
    await tester.pumpWidget(const SizedBox());
    timer.dispose();
  });
}
