import 'models.dart';

class WeekExpressionParser {
  List<int> parse(String expression) {
    var value = expression
        .replaceAll(RegExp(r'\s+'), '')
        .replaceAll('，', ',')
        .replaceAll('（', '(')
        .replaceAll('）', ')');
    value = value.replaceFirst(RegExp(r'^\(\d+(?:-\d+)?节\)'), '');
    if (!RegExp(r'^\d+(?:-\d+)?周(?:,\d+(?:-\d+)?周)*$').hasMatch(value)) {
      throw FormatException('Unsupported week expression', expression);
    }
    final result = <int>{};
    for (final piece in value.split(',')) {
      final bounds =
          piece.replaceAll('周', '').split('-').map(int.parse).toList();
      final first = bounds.first, last = bounds.last;
      if (first < 1 || last < first || last > 366) {
        throw FormatException('Invalid week range', expression);
      }
      for (var w = first; w <= last; w++) {
        result.add(w);
      }
    }
    return result.toList()..sort();
  }
}

String _unwrap(String text) => text
    .replaceAllMapped(RegExp(r'([A-Za-z])\n(?=[A-Za-z])'), (m) => '${m[1]} ')
    .replaceAll('\n', '')
    .replaceAll(RegExp(r'[ \t]+'), ' ')
    .trim();

class PdfScheduleParser {
  static const sections = {
    '第一二节': (1, 2),
    '第三四节': (3, 4),
    '第五六节': (5, 6),
    '第七八节': (7, 8),
    '第九十十一节': (9, 11)
  };
  final _weeks = WeekExpressionParser();

  ParsedSchedule parse(Map<String, dynamic> input) {
    if (input['schemaVersion'] != 1 ||
        !{'pdfplumber-ruled-table-v1', 'pdfium-ruled-template-v1'}
            .contains(input['adapter']) ||
        input['cells'] is! List) {
      throw const FormatException('Unsupported PDF extraction schema');
    }
    final footer = (input['footer'] as String).replaceAll(RegExp(r'\s+'), '');
    final dates =
        RegExp(r'本学期(\d{4}-\d{2}-\d{2})正式上课至(\d{4}-\d{2}-\d{2})结束，共(\d+)周')
            .firstMatch(footer);
    final semester = <String, dynamic>{
      'id': 'semester_1',
      'name': input['semesterName'],
      'startDate': dates?[1] ?? unclear,
      'endDate': dates?[2] ?? unclear,
      'totalWeeks': dates == null ? unclear : int.parse(dates[3]!),
      'weekStartDay': unclear,
      'manualWeekOffset': 0,
      'classTimeConfig': unclear
    };
    final records = <ParsedCourseRecord>[];
    for (final cell in (input['cells'] as List).cast<Map<String, dynamic>>()) {
      final raw = cell['rawText'] as String;
      // Preserve line wrapping until separate course blocks have been identified.
      final blocks = raw.split(RegExp(
          r'(?<=\d)\n(?=[^/\n]+/(?:[（(][\d\s-]+节[）)])?[\d\s,，周-]+周\s*/)'));
      for (var i = 0; i < blocks.length; i++) {
        final fields = blocks[i].split('/').map(_unwrap).toList();
        final f = <String, dynamic>{};
        const names = [
          'name',
          'weekExpression',
          'classroom',
          'teacher',
          'teachingClass',
          'remark',
          'totalHours',
          'credits'
        ];
        for (var j = 0; j < names.length; j++) {
          f[names[j]] = j < fields.length ? fields[j] : unclear;
        }
        // A malformed block remains visible but cannot silently become a valid record.
        if (fields.length < 7 || fields.length > 8) {
          f['weekExpression'] = unclear;
        }
        for (final name in ['name', 'classroom', 'teacher', 'teachingClass']) {
          if (f[name] == '') f[name] = unclear;
        }
        for (final name in ['totalHours', 'credits']) {
          f[name] = int.tryParse(f[name] as String) ?? unclear;
        }
        f['weekday'] = cell['weekday'];
        final rowSections = sections[cell['sectionLabel']];
        f['startSection'] = rowSections?.$1 ?? unclear;
        f['endSection'] = rowSections?.$2 ?? unclear;
        final expression = (f['weekExpression'] as String)
            .replaceAll(RegExp(r'\s+'), '')
            .replaceAll('（', '(')
            .replaceAll('）', ')');
        final override =
            RegExp(r'^\((\d+)(?:-(\d+))?节\)').firstMatch(expression);
        if (override != null) {
          f['startSection'] = int.parse(override[1]!);
          f['endSection'] = int.parse(override[2] ?? override[1]!);
        }
        try {
          f['activeWeeks'] = _weeks.parse(expression);
        } on FormatException {
          f['activeWeeks'] = unclear;
        }
        records.add(ParsedCourseRecord(
            'p${cell['page']}_r${cell['row']}_c${cell['column']}_$i',
            f,
            {...cell, 'blockIndex': i, 'rawBlock': blocks[i]}));
      }
    }
    final other = input['otherCourses'] as String;
    if (other.trim().isNotEmpty) {
      final footerMatch = RegExp(r'^其他课程：(.*)\(共\d+周\)/([^/]+)/[^/]+;?$')
          .firstMatch(_unwrap(other));
      final identities = <String, Map<String, dynamic>>{};
      if (footerMatch != null) {
        for (final record in records) {
          final f = record.fields;
          if ('${f['name']}${f['teacher']}' == footerMatch[1]) {
            identities['${f['name']}|${f['teacher']}'] = f;
          }
        }
      }
      // Recover an identity only when the literal text exactly matches a unique
      // course/teacher pair already present. Never infer a slot from that match.
      final identity = identities.length == 1 ? identities.values.single : null;
      Object otherWeeks = unclear;
      if (footerMatch != null) {
        try {
          otherWeeks = _weeks.parse(footerMatch[2]!);
        } on FormatException {/* Keep the original footer for correction. */}
      }
      records.add(ParsedCourseRecord('other_1', {
        'name': identity?['name'] ?? unclear,
        'teacher': identity?['teacher'] ?? unclear,
        'teachingClass': unclear,
        'classroom': unclear,
        'weekday': unclear,
        'startSection': unclear,
        'endSection': unclear,
        'weekExpression': footerMatch?[2] ?? unclear,
        'activeWeeks': otherWeeks,
        'remark': unclear,
        'totalHours': unclear,
        'credits': unclear,
      }, {
        'page': 1,
        'region': 'otherCourses',
        'rawText': other
      }));
    }
    return ParsedSchedule(input['sourceSha256'] as String, semester, records);
  }
}

class ImportValidation {
  DateTime? _strictDate(Object? value) {
    if (value is! String || !RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value)) {
      return null;
    }
    final date = DateTime.tryParse('${value}T00:00:00Z');
    return date != null && date.toIso8601String().substring(0, 10) == value
        ? date
        : null;
  }

  List<ValidationIssue> validate(ParsedSchedule draft) {
    final issues = <ValidationIssue>[];
    for (final field in [
      'name',
      'startDate',
      'endDate',
      'totalWeeks',
      'weekStartDay'
    ]) {
      if (draft.semester[field] == unclear || draft.semester[field] == null) {
        issues
            .add(ValidationIssue('${field}Unclear', 'error', '需确认学期字段：$field'));
      }
    }
    final start = _strictDate(draft.semester['startDate']);
    final end = _strictDate(draft.semester['endDate']);
    for (final field in ['startDate', 'endDate']) {
      if (draft.semester[field] != unclear &&
          _strictDate(draft.semester[field]) == null) {
        issues.add(
            ValidationIssue('invalidSemesterDate', 'error', '无效的学期日期：$field'));
      }
    }
    if (start != null && end != null && end.isBefore(start)) {
      issues.add(const ValidationIssue(
          'invalidSemesterRange', 'error', '学期结束日期早于开始日期'));
    }
    final total = draft.semester['totalWeeks'];
    if (total != unclear && (total is! int || total < 1 || total > 366)) {
      issues.add(const ValidationIssue(
          'invalidTotalWeeks', 'error', '总周数必须为 1..366 的整数'));
    }
    final day = draft.semester['weekStartDay'];
    if (day != unclear && (day is! int || day < 1 || day > 7)) {
      issues.add(const ValidationIssue(
          'invalidWeekStartDay', 'error', '每周起始日必须为 ISO 1..7'));
    }
    if (draft.semester['classTimeConfig'] == unclear) {
      issues.add(const ValidationIssue(
          'classTimesUnclear', 'warning', 'PDF 未提供节次钟点；配置前不能生成真实时间轴或通知'));
    }
    final projected = draft.projectResolvedRecords();
    for (final r in draft.records) {
      if (projected.skippedRecordIds.contains(r.id)) {
        issues.add(ValidationIssue(
            'unresolvedRecord', 'error', '排课字段无法确认或周次越界，请修正或显式排除', r.id));
      }
      if (r.fields['credits'] == unclear) {
        issues.add(
            ValidationIssue('creditsUnclear', 'warning', '原文未给出可确定学分', r.id));
      }
    }
    return issues;
  }
}
