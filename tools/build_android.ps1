param([switch]$SkipChecks)
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'android_env.ps1')
$output = Join-Path $projectRoot 'output\android'
New-Item -ItemType Directory -Force -Path $output | Out-Null
Push-Location (Join-Path $projectRoot 'apps\campus_time')
try {
    & $flutterExecutable pub get
    if ($LASTEXITCODE -ne 0) { throw 'Flutter dependency resolution failed' }
    if (-not $SkipChecks) {
        & $flutterExecutable analyze | Tee-Object -FilePath (Join-Path $output 'flutter-analyze.log')
        if ($LASTEXITCODE -ne 0) { throw 'Flutter analysis failed' }
        & $flutterExecutable test --reporter expanded | Tee-Object -FilePath (Join-Path $output 'flutter-tests.log')
        if ($LASTEXITCODE -ne 0) { throw 'Flutter tests failed' }
    }
    & $flutterExecutable build apk --release | Tee-Object -FilePath (Join-Path $output 'build.log')
    if ($LASTEXITCODE -ne 0) { throw 'Android build failed' }
    $appVersion=[regex]::Match((Get-Content pubspec.yaml -Raw),'(?m)^version:\s*([^\s+]+)').Groups[1].Value
    if (-not $appVersion) { throw 'Missing app version' }
    $apk=Join-Path $output "campus-time-$appVersion.apk"
    Copy-Item -LiteralPath 'build\app\outputs\flutter-apk\app-release.apk' -Destination $apk
    & (Join-Path $PSScriptRoot 'verify_android.ps1') -ApkPath $apk
    Write-Output "APK: $apk"
} finally { Pop-Location }
