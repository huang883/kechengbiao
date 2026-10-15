param([string]$ApkPath)
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'android_env.ps1')
if (-not $ApkPath) {
    $appVersion=[regex]::Match((Get-Content (Join-Path $projectRoot 'apps\campus_time\pubspec.yaml') -Raw),'(?m)^version:\s*([^\s+]+)').Groups[1].Value
    if (-not $appVersion) { throw 'Missing app version' }
    $ApkPath=Join-Path $projectRoot "output\android\campus-time-$appVersion.apk"
}
$ApkPath=(Resolve-Path -LiteralPath $ApkPath).Path
$folder=Split-Path -Parent $ApkPath
$buildTools=Join-Path $env:ANDROID_HOME 'build-tools\36.0.0'
& (Join-Path $buildTools 'apksigner.bat') verify --verbose $ApkPath | Tee-Object -FilePath (Join-Path $folder 'apk-signature.log')
if ($LASTEXITCODE -ne 0) { throw 'APK signature verification failed' }
& (Join-Path $buildTools 'zipalign.exe') -c -P 16 4 $ApkPath
if ($LASTEXITCODE -ne 0) { throw 'APK alignment verification failed' }
$metadata=& (Join-Path $buildTools 'aapt.exe') dump badging $ApkPath
if ($LASTEXITCODE -ne 0) { throw 'APK metadata could not be read' }
$metadata | Set-Content -LiteralPath (Join-Path $folder 'apk-metadata.txt') -Encoding utf8
if (-not ($metadata -match "package: name='cn.huangrui.campus_time'")) { throw 'Unexpected package ID' }
if (-not ($metadata -match "sdkVersion:'24'")) { throw 'Unexpected minimum Android version' }
$hash=(Get-FileHash -LiteralPath $ApkPath -Algorithm SHA256).Hash.ToLowerInvariant()
"$hash  $(Split-Path -Leaf $ApkPath)" | Set-Content -LiteralPath (Join-Path $folder 'SHA256SUMS.txt') -Encoding ascii
Write-Output 'PASS: APK signature, 16 KB zip alignment and application metadata.'
