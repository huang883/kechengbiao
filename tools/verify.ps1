param([string]$PdfPath = 'C:\Users\huang\黄锐课表.pdf')
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$dartExecutable = Join-Path $projectRoot '.tools\dart-sdk\bin\dart.exe'
if (-not (Test-Path -LiteralPath $dartExecutable)) {
    $dartExecutable = (Get-Command dart -ErrorAction Stop).Source
}
$previousPubCache = $env:PUB_CACHE
$env:PUB_CACHE = Join-Path $projectRoot '.tools\pub-cache'
Push-Location $projectRoot
try {
    New-Item -ItemType Directory -Force -Path 'tmp\pdfs','output\analysis' | Out-Null
    python tools/extract_pdf.py $PdfPath tmp/pdfs/reextracted.json
    if ($LASTEXITCODE -ne 0) { throw 'PDF extraction failed' }
    $actual = (Get-FileHash -LiteralPath 'tmp\pdfs\reextracted.json').Hash
    $expected = (Get-FileHash -LiteralPath 'apps\campus_time\assets\default_timetable.json').Hash
    if ($actual -ne $expected) { throw 'Source extraction differs from reviewed fixture; manual review required' }
    Set-Location packages/schedule_core
    & $dartExecutable pub get
    if ($LASTEXITCODE -ne 0) { throw 'Dependency resolution failed' }
    & $dartExecutable format --output=none --set-exit-if-changed lib test bin
    if ($LASTEXITCODE -ne 0) { throw 'Dart formatting check failed' }
    & $dartExecutable analyze --fatal-infos | Tee-Object -FilePath ../../output/analysis/analyze.log
    if ($LASTEXITCODE -ne 0) { throw 'Dart analysis failed' }
    & $dartExecutable test --reporter expanded | Tee-Object -FilePath ../../output/analysis/tests.log
    if ($LASTEXITCODE -ne 0) { throw 'Dart tests failed' }
    & $dartExecutable run bin/analyze_pdf.dart ../../tmp/pdfs/reextracted.json ../../output/analysis/parsed_schedule.json
    if ($LASTEXITCODE -ne 0) { throw 'Parsing failed' }
    Set-Location $projectRoot
    python tools/write_analysis_report.py output/analysis/parsed_schedule.json output/analysis/PDF_ANALYSIS.md
    if ($LASTEXITCODE -ne 0) { throw 'Report generation failed' }
    & (Join-Path $projectRoot 'tools\verify_storage.ps1')
    Write-Output 'PASS: real PDF -> Dart parser -> domain -> Drift persistence tests. No production database was created.'
} finally {
    Pop-Location
    $env:PUB_CACHE = $previousPubCache
}
