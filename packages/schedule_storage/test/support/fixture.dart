import 'dart:convert';
import 'dart:io';
import 'package:schedule_core/schedule_core.dart';

ParsedSchedule realPdf() => PdfScheduleParser().parse(
  jsonDecode(
        File(
          '../../apps/campus_time/assets/default_timetable.json',
        ).readAsStringSync(),
      )
      as Map<String, dynamic>,
);

Future<ImportDraft> reviewed(ImportRepository repo) async {
  final draft = await repo.createDraft(realPdf());
  return repo.editDraft(
    draft.id,
    expectedRevision: draft.revision,
    semesterChanges: {'weekStartDay': 7},
    exclusions: {'other_1': '测试中明确排除未排课记录'},
    reason: '测试输入：周日作为周起点，不代表学校实际约定',
  );
}
