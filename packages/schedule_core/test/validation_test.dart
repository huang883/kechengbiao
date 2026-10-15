import 'dart:convert';
import 'dart:io';
import 'package:schedule_core/schedule_core.dart';
import 'package:test/test.dart';

Map<String, dynamic> fixture() =>
    jsonDecode(File('../../apps/campus_time/assets/default_timetable.json').readAsStringSync())
        as Map<String, dynamic>;

void main() {
  test('invalid calendar date cannot pass preview validation', () {
    final input = fixture();
    input['footer'] =
        (input['footer'] as String).replaceFirst('2026-08-30', '2026-02-30');
    final issues =
        ImportValidation().validate(PdfScheduleParser().parse(input));
    expect(issues.any((i) => i.code == 'invalidSemesterDate'), isTrue);
  });
  test('reversed semester date range cannot pass validation', () {
    final input = fixture();
    input['footer'] =
        (input['footer'] as String).replaceFirst('2027-01-16', '2026-01-16');
    final issues =
        ImportValidation().validate(PdfScheduleParser().parse(input));
    expect(issues.any((i) => i.code == 'invalidSemesterRange'), isTrue);
  });
  for (final expression in ['1-21周', '(10-9节)1-10周', '(0-2节)1-10周']) {
    test('preview rejects out of bounds or reversed rule: $expression', () {
      final input = fixture();
      final cell = (input['cells'] as List).first as Map<String, dynamic>;
      cell['rawText'] = (cell['rawText'] as String)
          .replaceFirst('1-\n10周,12-17周', expression);
      final parsed = PdfScheduleParser().parse(input);
      expect(parsed.projectResolvedRecords().skippedRecordIds,
          contains(parsed.records.first.id));
      expect(
          ImportValidation().validate(parsed).any((i) =>
              i.recordId == parsed.records.first.id && i.severity == 'error'),
          isTrue);
    });
  }
  test('missing footer is unclear instead of estimated from latest active week',
      () {
    final input = fixture()..['footer'] = '';
    final parsed = PdfScheduleParser().parse(input);
    expect(parsed.semester['startDate'], unclear);
    expect(parsed.semester['totalWeeks'], unclear);
    expect(parsed.projectResolvedRecords().schedules, isEmpty);
  });
  test('raw input and semester draft are not mutated by parsing or validation',
      () {
    final input = fixture();
    final before = jsonEncode(input);
    final parsed = PdfScheduleParser().parse(input);
    ImportValidation().validate(parsed);
    parsed.projectResolvedRecords();
    expect(jsonEncode(input), before);
    expect(() => parsed.semester['weekStartDay'] = 1, throwsUnsupportedError);
  });
}
