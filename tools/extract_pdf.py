"""Desktop evidence adapter: PDF geometry -> JSON, no course business rules.

Usage: python tools/extract_pdf.py INPUT.pdf OUTPUT.json
Install pdfplumber==0.11.10; this adapter is not an Android runtime dependency.
"""
import hashlib
import json
import re
import sys
from pathlib import Path

local_deps = Path(__file__).resolve().parents[1] / '.tools' / 'python'
if local_deps.exists():
    sys.path.insert(0, str(local_deps))
import pdfplumber


def extract(source):
    with pdfplumber.open(source) as pdf:
        if len(pdf.pages) != 1:
            raise ValueError('Unsupported layout: expected exactly one page')
        page = pdf.pages[0]
        tables = page.find_tables()
        if len(tables) != 1:
            raise ValueError('Unsupported layout: expected one ruled table')
        table = tables[0]
        rows = table.extract()
        compact = lambda text: re.sub(r'\s+', '', text or '')
        if len(rows) != 9 or any(len(row) != 9 for row in rows):
            raise ValueError('Unsupported table dimensions')
        if [compact(v) for v in rows[1][2:]] != ['星期' + d for d in '一二三四五六日']:
            raise ValueError('Unrecognized weekday headers')
        expected = ['第一二节', '第三四节', '第五六节', '第七八节', '第九十十一节']
        if [compact(row[1]) for row in rows[2:7]] != expected:
            raise ValueError('Unrecognized section headers')
        title = re.search(r'\d{4}-\d{4}年第\d学期', compact(rows[0][0]))
        if not title:
            raise ValueError('Missing semester title')
        cells = []
        for row_index in range(2, 7):
            for col_index in range(2, 9):
                text = rows[row_index][col_index]
                if text and text.strip():
                    cells.append({
                        'page': 1, 'row': row_index, 'column': col_index,
                        'bbox': list(table.rows[row_index].cells[col_index]),
                        'weekday': col_index - 1,
                        'sectionLabel': compact(rows[row_index][1]),
                        'rawText': text,
                    })
        return {
            'schemaVersion': 1, 'adapter': 'pdfplumber-ruled-table-v1',
            'sourceSha256': hashlib.sha256(Path(source).read_bytes()).hexdigest(),
            'pageSize': [page.width, page.height],
            'semesterName': title.group(),
            'footer': rows[-1][0], 'otherCourses': rows[-2][0], 'cells': cells,
        }


if __name__ == '__main__':
    data = extract(sys.argv[1])
    destination = Path(sys.argv[2])
    destination.parent.mkdir(parents=True, exist_ok=True)
    destination.write_text(json.dumps(data, ensure_ascii=False, indent=2), encoding='utf-8')
    print(f'Extracted {len(data["cells"])} nonempty cells; SHA256 {data["sourceSha256"]}')
