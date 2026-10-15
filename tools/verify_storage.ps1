$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$dartExecutable = Join-Path $projectRoot '.tools\dart-sdk\bin\dart.exe'
if (-not (Test-Path -LiteralPath $dartExecutable)) {
    $dartExecutable = (Get-Command dart -ErrorAction Stop).Source
}
$previousPubCache = $env:PUB_CACHE
$env:PUB_CACHE = Join-Path $projectRoot '.tools\pub-cache'
Push-Location (Join-Path $projectRoot 'packages\schedule_storage')
try {
    New-Item -ItemType Directory -Force -Path '../../output/database','../../tmp/storage-schema' | Out-Null
    & $dartExecutable pub get
    if ($LASTEXITCODE -ne 0) { throw 'Storage dependencies failed' }
    & $dartExecutable run build_runner build
    if ($LASTEXITCODE -ne 0) { throw 'Drift generation failed' }
    & $dartExecutable run drift_dev schema dump lib/src/database.dart ../../tmp/storage-schema
    if ($LASTEXITCODE -ne 0) { throw 'Schema export failed' }
    $expected = (Get-FileHash -LiteralPath 'schemas/drift_schema_v6.json').Hash
    $actual = (Get-FileHash -LiteralPath '../../tmp/storage-schema/drift_schema_v6.json').Hash
    if ($actual -ne $expected) { throw 'Schema v6 changed; review version and migration before updating baseline' }
    & $dartExecutable format --output=none --set-exit-if-changed lib test
    if ($LASTEXITCODE -ne 0) { throw 'Storage formatting failed' }
    & $dartExecutable analyze --fatal-infos | Tee-Object -FilePath ../../output/database/analyze.log
    if ($LASTEXITCODE -ne 0) { throw 'Storage analysis failed' }
    # Build first: the test process must not trigger a rebuild of a DLL already loaded on Windows.
    & $dartExecutable build cli --target test/support/reopen_probe.dart --output build/reopen_probe
    if ($LASTEXITCODE -ne 0) { throw 'Independent restart probe build failed' }
    & $dartExecutable test --reporter expanded | Tee-Object -FilePath ../../output/database/tests.log
    if ($LASTEXITCODE -ne 0) { throw 'Storage tests failed' }
    Write-Output 'PASS: Drift repositories, atomic imports and separate-process persistence. Temporary test databases only.'
} finally {
    Pop-Location
    $env:PUB_CACHE = $previousPubCache
}
