import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:pdfrx_engine/pdfrx_engine.dart';
import 'package:schedule_core/schedule_core.dart';
import 'package:schedule_pdf/schedule_pdf.dart';
import 'package:test/test.dart';

void main() {
  setUpAll(() => pdfrxInitialize());
  test(
    'PDFium byte extraction agrees with independently reviewed real PDF fixture',
    () async {
      final path =
          Platform.environment['SCHEDULE_PDF'] ?? r'C:\Users\huang\黄锐课表.pdf';
      final extracted = await SchoolPdfAdapter().extract(
        await File(path).readAsBytes(),
      );
      final actual = PdfScheduleParser().parse(extracted);
      final expected = PdfScheduleParser().parse(
        jsonDecode(
              File(
                '../schedule_core/test/fixtures/huang_extracted.json',
              ).readAsStringSync(),
            )
            as Map<String, dynamic>,
      );
      expect(actual.sourceSha256, expected.sourceSha256);
      expect(actual.semester, expected.semester);
      expect(actual.records.length, expected.records.length);
      for (var i = 0; i < expected.records.length; i++) {
        expect(
          actual.records[i].fields,
          expected.records[i].fields,
          reason: 'record $i',
        );
      }
    },
  );
  test('non PDF data is rejected without a fabricated schedule', () async {
    await expectLater(
      SchoolPdfAdapter().extract(Uint8List.fromList([1, 2, 3])),
      throwsA(anything),
    );
  });
}
