import 'dart:io';
import 'dart:convert';
import 'package:pdfrx_engine/pdfrx_engine.dart';

Future<void> main(List<String> args) async {
  await pdfrxInitialize();
  final doc = await PdfDocument.openFile(args[0]);
  final text = (await doc.pages.single.loadText())!;
  await File(args[1]).writeAsString(
    jsonEncode({
      'text': text.fullText,
      'rects': text.charRects
          .map((r) => [r.left, r.top, r.right, r.bottom])
          .toList(),
    }),
  );
  await doc.dispose();
}
