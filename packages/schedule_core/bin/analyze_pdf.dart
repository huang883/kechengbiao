import 'dart:convert';
import 'dart:io';
import 'package:schedule_core/schedule_core.dart';

void main(List<String> args) {
  if (args.length != 2) {
    stderr.writeln(
        'Usage: dart run bin/analyze_pdf.dart extracted.json output.json');
    exitCode = 64;
    return;
  }
  final parsed = PdfScheduleParser().parse(
      jsonDecode(File(args[0]).readAsStringSync()) as Map<String, dynamic>);
  final projection = parsed.projectResolvedRecords();
  final result = {
    ...parsed.toJson(),
    'issues':
        ImportValidation().validate(parsed).map((i) => i.toJson()).toList(),
    'courses': projection.courses
        .map((c) => {'id': c.id, 'name': c.name, 'teacher': c.teacher})
        .toList(),
    'courseSchedules': projection.schedules.map((s) => s.toJson()).toList(),
    'skippedRecordIds': projection.skippedRecordIds,
    'confirmed': false,
    'databaseWritten': false,
  };
  File(args[1])
      .writeAsStringSync(const JsonEncoder.withIndent('  ').convert(result));
  stdout.writeln(
      '${projection.courses.length} courses, ${projection.schedules.length} rules, '
      '${projection.skippedRecordIds.length} unresolved records. Analysis only; nothing imported.');
}
