"""Format the parsed evidence as a reviewable Markdown report (never confirms import)."""
import json
import sys
from pathlib import Path

data = json.loads(Path(sys.argv[1]).read_text(encoding='utf-8'))
lines = [
    '# 真实 PDF 解析报告', '',
    '状态：仅供检查的解析结果，尚未确认导入，没有写入数据库。', '',
    f"来源 SHA-256：`{data['sourceSha256']}`", '',
    '## 学期', '',
]
for key, value in data['semester'].items():
    lines.append(f'- {key}：{value}')
lines += ['', '## 22 条已确定排课', '',
          '一行代表一条独立 CourseSchedule；节次不是钟点。', '',
          '|星期|节次|课程|教师|教室|activeWeeks|',
          '|---|---|---|---|---|---|']
for record in data['records']:
    if record['id'] in data['skippedRecordIds']:
        continue
    lines.append('|{weekday}|{startSection}-{endSection}|{name}|{teacher}|{classroom}|{weeks}|'.format(
        **record, weeks=', '.join(map(str, record['activeWeeks']))))
lines += ['', '## 各教学周的排课条数', '',
          '以下仅按 activeWeeks 统计；未配置周起始日，所以不把周号映射为实际日期。', '',
          '|周次|排课条数|', '|---|---|']
for week in range(1, data['semester']['totalWeeks'] + 1):
    count = sum(week in r['activeWeeks'] for r in data['courseSchedules'])
    lines.append(f'|{week}|{count}|')
lines += ['', '## 待确认信息', '',
          '- weekStartDay：unclear。PDF 开始日期为周日，不能假定学校周序。',
          '- ClassTimeConfig：unclear。PDF 不含每节课的起止钟点。',
          '- 学分：unclear。尾部 64、32 等位于总学时字段，不能当作学分。',
          '- 底部“其他课程”的星期、节次不明确，不能自动补到星期三。', '']
for record in data['records']:
    if record['id'] in data['skippedRecordIds']:
        lines += [f"原文：{record['source']['rawText']}", '',
                  f"已识别：{record['name']} / {record['teacher']} / 周次 {record['activeWeeks']}", '']
lines += ['## 验证范围', '',
          '已验证桌面 PDF 几何提取 → 纯 Dart 解析 → 内存 CourseSchedule → 周/日期筛选。',
          'SQLite、确认事务与 Repository 已通过临时库及跨进程测试。导入纠错页面、手机端 PDF 提取和 APK 尚未实现。', '']
Path(sys.argv[2]).write_text('\n'.join(lines), encoding='utf-8')
