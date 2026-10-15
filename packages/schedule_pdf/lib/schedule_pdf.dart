import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:pdfrx_engine/pdfrx_engine.dart';

/// One verified school template. Coordinates are layout rules, never course data.
class SchoolPdfAdapter {
  Future<Map<String, dynamic>> extract(Uint8List bytes) async {
    if (bytes.length > 20 * 1024 * 1024) {
      throw const FormatException('文件超过 20 MB，请选择学校导出的课表 PDF');
    }
    final document = await PdfDocument.openData(bytes);
    try {
      if (document.pages.length != 1 || document.isEncrypted) {
        throw const FormatException('目前支持未加密的单页学校课表');
      }
      final page = document.pages.single;
      if ((page.width - 842).abs() > 1 || (page.height - 595).abs() > 1) {
        throw const FormatException('暂不支持此课表版式');
      }
      final text = await page.loadText();
      if (text == null) throw const FormatException('未识别到课程文字，扫描件暂不支持');
      String region(double left, double top, double right, double bottom) {
        final lines = <String>[];
        var line = StringBuffer();
        void flush() {
          if (line.toString().trim().isNotEmpty) {
            lines.add(line.toString().trim());
          }
          line = StringBuffer();
        }

        // PDFium keeps the source text runs and line breaks. Geometry selects the
        // cell; original character order preserves punctuation and real spaces.
        for (var i = 0; i < text.fullText.length; i++) {
          final char = text.fullText[i], r = text.charRects[i];
          if (char == '\r' || char == '\n') {
            flush();
            continue;
          }
          final x = (r.left + r.right) / 2,
              y = page.height - (r.top + r.bottom) / 2;
          if (x >= left && x < right && y >= top && y < bottom) {
            line.write(char);
          }
        }
        flush();
        return lines.join('\n');
      }

      const xs = [46.38, 158.02, 269.66, 381.3, 492.93, 604.57, 716.21, 827.85];
      const ys = [57.54, 144.84, 232.02235, 319.44, 406.62235, 494.04];
      const labels = ['第一二节', '第三四节', '第五六节', '第七八节', '第九十十一节'];
      for (var d = 0; d < 7; d++) {
        if (region(xs[d], 43, xs[d + 1], 57.54).replaceAll('\n', '') !=
            '星期${'一二三四五六日'[d]}') {
          throw const FormatException('无法确认星期列，请使用学校原始 PDF');
        }
      }
      for (var r = 0; r < 5; r++) {
        if (region(30, ys[r], 46.38, ys[r + 1]).replaceAll('\n', '') !=
            labels[r]) {
          throw const FormatException('无法确认节次行');
        }
      }
      final title = RegExp(
        r'\d{4}-\d{4}年第\d学期',
      ).firstMatch(region(14, 23, 280, 43).replaceAll('\n', ''));
      final footer = region(14, 508, 828, 522).replaceAll('\n', '');
      if (title == null || !footer.contains('正式上课至')) {
        throw const FormatException('课表缺少可识别的学期信息');
      }
      final cells = <Map<String, dynamic>>[];
      for (var r = 0; r < 5; r++) {
        for (var d = 0; d < 7; d++) {
          final raw = region(xs[d], ys[r], xs[d + 1], ys[r + 1]);
          if (raw.trim().isEmpty) continue;
          cells.add({
            'page': 1,
            'row': r + 2,
            'column': d + 2,
            'bbox': [xs[d], ys[r], xs[d + 1], ys[r + 1]],
            'weekday': d + 1,
            'sectionLabel': labels[r],
            'rawText': raw,
          });
        }
      }
      if (cells.isEmpty) throw const FormatException('未识别到课程文字，扫描件暂不支持');
      return {
        'schemaVersion': 1,
        'adapter': 'pdfium-ruled-template-v1',
        'sourceSha256': sha256.convert(bytes).toString(),
        'pageSize': [page.width, page.height],
        'semesterName': title.group(0),
        'footer': footer,
        'otherCourses': region(14, 494.04, 828, 508).replaceAll('\n', ''),
        'cells': cells,
      };
    } finally {
      await document.dispose();
    }
  }
}
