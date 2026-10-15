import 'dart:convert';
import 'dart:io';
import 'package:schedule_core/schedule_core.dart';
import 'package:test/test.dart';

Map<String, dynamic> fixture() => jsonDecode(
      File('../../apps/campus_time/assets/default_timetable.json').readAsStringSync(),
    ) as Map<String, dynamic>;

void main() {
  final weeks = WeekExpressionParser();
  final examples = <String, List<int>>{
    '1-10周,12-17周': [
      ...List.generate(10, (i) => i + 1),
      12,
      13,
      14,
      15,
      16,
      17
    ],
    '9-10周,12-17周': [9, 10, 12, 13, 14, 15, 16, 17],
    '1-8周': [1, 2, 3, 4, 5, 6, 7, 8],
    '14周': [14],
    '14-17周': [14, 15, 16, 17],
    '1-2周,4-8周': [1, 2, 4, 5, 6, 7, 8],
    '(9-10节)5-10周,12-13周': [5, 6, 7, 8, 9, 10, 12, 13],
    '（9-10节）5-10周，12-13周': [5, 6, 7, 8, 9, 10, 12, 13],
    '3周,1-3周': [1, 2, 3],
  };
  for (final entry in examples.entries) {
    test('weeks ${entry.key}',
        () => expect(weeks.parse(entry.key), entry.value));
  }
  for (final value in [
    '',
    '0周',
    '10-5周',
    '1-3周垃圾',
    '1-3周,',
    '1-3周单周',
    '-1周',
    '1-99999周'
  ]) {
    test('reject $value',
        () => expect(() => weeks.parse(value), throwsFormatException));
  }
  test('real PDF preserves metadata and 22 rules plus unresolved footer', () {
    final parsed = PdfScheduleParser().parse(fixture());
    expect(parsed.semester['startDate'], '2026-08-30');
    expect(parsed.semester['endDate'], '2027-01-16');
    expect(parsed.semester['totalWeeks'], 20);
    expect(parsed.semester['weekStartDay'], 'unclear');
    expect(parsed.records.length, 23);
    final projection = parsed.projectResolvedRecords();
    expect(projection.schedules.length, 22);
    expect(projection.courses.length, 14);
    expect(projection.skippedRecordIds, ['other_1']);
    expect(parsed.records.first.fields['totalHours'], 64);
    expect(parsed.records.first.fields['credits'], 'unclear');
    expect(parsed.records.first.fields['remark'], '');
    expect(projection.courses.where((c) => c.name == '面向对象程序设计').single.teacher,
        'Jobin Joy');
    expect(projection.courses.where((c) => c.name == '专业拓展实践2').single.teacher,
        'Jobin Joy');
    final issues = ImportValidation().validate(parsed);
    expect(issues.any((i) => i.code == 'weekStartDayUnclear'), isTrue);
    expect(issues.any((i) => i.recordId == 'other_1' && i.severity == 'error'),
        isTrue);
    expect(
        issues
            .where((i) => i.severity == 'error' && i.recordId != 'other_1')
            .map((i) => i.code),
        ['weekStartDayUnclear']);
  });
  test('explicit sections override row; other courses never get invented slots',
      () {
    final parsed = PdfScheduleParser().parse(fixture());
    final records = parsed.records;
    expect(
        records
            .where((r) =>
                r.fields['name'] == '关系数据库编程' && r.fields['weekday'] == 2)
            .single
            .fields['endSection'],
        10);
    expect(
        records
            .where((r) => r.fields['name'] == '概率统计A')
            .single
            .fields['endSection'],
        11);
    expect(records.last.fields['weekday'], 'unclear');
    expect(records.last.fields['startSection'], 'unclear');
    expect(records.last.fields['name'], '大学英语（三）');
    expect(records.last.fields['teacher'], '巩艺超');
    expect((records.last.fields['activeWeeks'] as List<int>).length, 18);
  });
  test('corrupted weeks stay visible and fail validation', () {
    final input = fixture();
    final cell = (input['cells'] as List).first as Map<String, dynamic>;
    cell['rawText'] =
        (cell['rawText'] as String).replaceFirst('12-17周', '17-12周');
    final parsed = PdfScheduleParser().parse(input);
    expect(parsed.records.first.fields['activeWeeks'], 'unclear');
    expect(
        ImportValidation().validate(parsed).any((i) =>
            i.recordId == parsed.records.first.id && i.severity == 'error'),
        isTrue);
    expect(parsed.projectResolvedRecords().schedules.length, 21);
  });
  test('unsupported extraction schema is rejected', () {
    expect(() => PdfScheduleParser().parse({'schemaVersion': 99}),
        throwsFormatException);
  });
}
