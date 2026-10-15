import 'package:flutter/material.dart';
import 'package:schedule_core/schedule_core.dart';

const ink = Color(0xFF213B37),
    mint = Color(0xFF247B68),
    paper = Color(0xFFF7F8F3);
// WakeUp 3.22 open-source customizedColors, also used for default course colors.
// Source and scope: docs/WAKEUP_COLORS.md. Explicit user colors remain unchanged.
const coursePalette = [
  '#FF1744', // 红
  '#FA6278', // 粉
  '#2979FF', // 蓝
  '#1DE9B6', // 薄荷绿
  '#FFEA00', // 黄
  '#FF9100', // 橙
  '#FF3D00', // 橙红
  '#2196F3', // 浅蓝
  '#005CAF', // 琉璃蓝
];
Color courseColor(String value, [String key = '']) {
  final selected = value == 'default'
      ? coursePalette[key.codeUnits.fold(0, (a, b) => a + b) %
            coursePalette.length]
      : value;
  return Color(
    int.tryParse(selected.replaceFirst('#', 'FF'), radix: 16) ?? 0xFF247B68,
  );
}

String clockText(DateTime d) =>
    '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
String dayLabel(DateTime d) =>
    '${d.month}月${d.day}日 · 星期${'一二三四五六日'[d.weekday - 1]}';
String friendlyError(Object e) {
  if (e is FormatException) return e.message;
  if (e is RepositoryException) {
    return switch (e.code) {
      'confirmationRequired' => '请先确认导入',
      'staleRevision' => '预览已更新，请重新检查后确认',
      'invalidImport' => '仍有未解决的课程或学期信息，请修正或明确排除',
      'alreadyCommitted' => '这份课表已导入，请在设置中查看',
      'invalidClassTimes' => '请检查节次是否重复、时间是否交叠或倒序',
      'sourceMismatch' => '这份文件已有不同解析版本，请先保留原记录并检查文件',
      _ => '操作未完成，请检查输入后重试',
    };
  }
  if (e is ArgumentError) return '请检查输入：起止时间、日期和必填内容必须有效';
  debugPrint('$e');
  return '操作未完成，请重试。文件可能不受支持。';
}

void message(BuildContext context, String text) =>
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
Future<void> action(BuildContext context, Future<void> Function() work) async {
  try {
    await work();
  } catch (e) {
    if (context.mounted) message(context, friendlyError(e));
  }
}

class SectionTitle extends StatelessWidget {
  final String title;
  final Widget? trailing;
  const SectionTitle(this.title, {super.key, this.trailing});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 24, bottom: 12),
    child: Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
        ?trailing,
      ],
    ),
  );
}

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title, body;
  final Widget? button;
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.body,
    this.button,
  });
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 44, color: mint),
        const SizedBox(height: 16),
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 10),
        Text(
          body,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.black54, height: 1.6),
        ),
        if (button != null)
          Padding(padding: const EdgeInsets.only(top: 20), child: button),
      ],
    ),
  );
}

class InfoCard extends StatelessWidget {
  final String text;
  final VoidCallback? onTap;
  const InfoCard(this.text, {super.key, this.onTap});
  @override
  Widget build(BuildContext context) => Card(
    color: const Color(0xFFF1EBD9),
    child: ListTile(
      leading: const Icon(Icons.info_outline, color: Color(0xFF936B28)),
      title: Text(text, style: const TextStyle(fontSize: 13, height: 1.4)),
      trailing: onTap == null ? null : const Icon(Icons.chevron_right),
      onTap: onTap,
    ),
  );
}
