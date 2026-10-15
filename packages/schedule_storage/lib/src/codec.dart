import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:schedule_core/schedule_core.dart';
import 'database.dart' show ScheduleDatabase;

List<Variable> bind(List<Object> args) => args
    .map(
      (a) => switch (a) {
        String s => Variable<String>(s),
        int n => Variable<int>(n),
        _ => throw ArgumentError('Unsupported query argument'),
      },
    )
    .toList();

Future<List<QueryRow>> rows(
  ScheduleDatabase db,
  String sql, [
  List<Object> args = const [],
]) => db.customSelect(sql, variables: bind(args)).get();

ParsedSchedule decodeParsed(String json) {
  final data = jsonDecode(json) as Map<String, dynamic>;
  return ParsedSchedule(
    data['sourceSha256'] as String,
    data['semester'] as Map<String, dynamic>,
    (data['records'] as List).map((value) {
      final r = value as Map<String, dynamic>;
      final fields = Map<String, dynamic>.from(r)
        ..remove('id')
        ..remove('source');
      if (fields['activeWeeks'] is List) {
        fields['activeWeeks'] = (fields['activeWeeks'] as List).cast<int>();
      }
      return ParsedCourseRecord(
        r['id'] as String,
        fields,
        r['source'] as Map<String, dynamic>,
      );
    }).toList(),
  );
}

String canonicalJson(Object? value) {
  Object? sorted(Object? v) {
    if (v is Map) {
      final keys = v.keys.cast<String>().toList()..sort();
      return {for (final k in keys) k: sorted(v[k])};
    }
    if (v is List) return v.map(sorted).toList();
    return v;
  }

  return jsonEncode(sorted(value));
}

Never fail(String code, String message) =>
    throw RepositoryException(code, message);
