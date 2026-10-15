import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:schedule_core/schedule_core.dart';
import 'package:schedule_storage/schedule_storage.dart';

import '../shared/default_class_times.dart';

/// Seed only empty installations, atomically; preserve all upgrade data.
Future<void> ensureDefaultTimetable(ScheduleDatabase db) async {
  final courses = DriftCourseRepository(db);
  if ((await courses.listSemesters()).isNotEmpty) return;
  final raw = jsonDecode(
    await rootBundle.loadString('assets/default_timetable.json'),
  ) as Map<String, dynamic>;
  await db.transaction(() async {
    if ((await courses.listSemesters()).isNotEmpty) return;
    final imports = DriftImportRepository(db);
    final parsed = PdfScheduleParser().parse(raw);
    // An existing preview may contain unconfirmed user edits. Never commit it silently.
    if (await imports.readDraft(parsed.sourceSha256) != null) return;
    var draft = await imports.createDraft(parsed);
    draft = await imports.editDraft(
      draft.id,
      expectedRevision: draft.revision,
      semesterChanges: {
        'name': '黄锐的课表',
        'startDate': '2026-08-31',
        'weekStartDay': 1,
      },
      exclusions: {'other_1': '用户已确认忽略未排课的其他课程大学英语（三）'},
      reason: '根据用户确认的 PDF 与校历设置默认课程表',
    );
    final result = await imports.confirmImport(
      draft.id,
      expectedRevision: draft.revision,
      confirmed: true,
    );
    final settings = DriftSettingsRepository(db);
    await settings.replaceClassTimes(
      result.semesterId,
      defaultClassTimes(result.semesterId),
    );
    for (final d in [
      (DateTime.utc(2026, 9, 25), '中秋节'),
      (DateTime.utc(2026, 10, 1), '国庆节'),
      (DateTime.utc(2027, 1, 1), '元旦'),
    ]) {
      await settings.saveDayOff(
        result.semesterId,
        ClassDayOff(date: d.$1, reason: d.$2),
      );
    }
  });
}
