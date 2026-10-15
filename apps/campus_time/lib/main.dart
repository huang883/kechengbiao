import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:schedule_storage/schedule_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqlite3/sqlite3.dart';

import 'app.dart';
import 'features/pomodoro/focus_bridge.dart';
import 'application/default_timetable.dart';
import 'application/app_controller.dart';
import 'application/notifications.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  LicenseRegistry.addLicense(() async* {
    yield LicenseEntryWithLineBreaks([
      'flutter_pomodoro_cat',
    ], await rootBundle.loadString('assets/licenses/pomodoro_cat.txt'));
  });
  try {
    await pdfrxFlutterInitialize();
    final directory = await getApplicationSupportDirectory();
    sqlite3.tempDirectory = (await getTemporaryDirectory()).path;
    final db = ScheduleDatabase.file(
      File('${directory.path}/campus_time.sqlite'),
    );
    await ensureDefaultTimetable(db);
    final notifications = NotificationService();
    try {
      await notifications.initialize();
    } catch (e) {
      debugPrint('Notifications unavailable: $e');
    }
    final app = AppController(
      focusBridge: Platform.isAndroid ? const FocusBridge() : null,
      imports: DriftImportRepository(db),
      courses: DriftCourseRepository(db),
      taskStore: DriftTaskRepository(db),
      settings: DriftSettingsRepository(db),
      preferences: await SharedPreferences.getInstance(),
      notifications: notifications,
    );
    await app.initialize();
    runApp(
      ProviderScope(
        overrides: [appProvider.overrideWith((ref) => app)],
        child: const CampusApp(),
      ),
    );
  } catch (e, stack) {
    debugPrint('$e\n$stack');
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('课间暂时无法打开，请检查存储空间后重试。'),
                  const SizedBox(height: 20),
                  FilledButton(onPressed: main, child: const Text('重试')),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
