[CmdletBinding()]
param(
    [ValidateSet('apk', 'appbundle', 'all')]
    [string]$Format = 'all'
)

$ErrorActionPreference = 'Stop'

$sourcePath = (Resolve-Path -LiteralPath $PSScriptRoot).Path
$temporaryRoot = [System.IO.Path]::GetFullPath(
    [System.IO.Path]::GetTempPath()
)
$buildName = 'fidelio_release_' + [Guid]::NewGuid().ToString('N')
$buildPath = [System.IO.Path]::GetFullPath(
    (Join-Path -Path $temporaryRoot -ChildPath $buildName)
)

if (-not $buildPath.StartsWith(
        $temporaryRoot,
        [System.StringComparison]::OrdinalIgnoreCase
    ) -or (Split-Path -Leaf $buildPath) -notlike 'fidelio_release_*') {
    throw 'Unsafe temporary build path.'
}

$versionLine = Select-String -LiteralPath (Join-Path $sourcePath 'pubspec.yaml') `
    -Pattern '^version:\s*([0-9.]+)\+([0-9]+)\s*$'
if (-not $versionLine) {
    throw 'Unable to read the application version from pubspec.yaml.'
}
$versionName = $versionLine.Matches[0].Groups[1].Value
$buildNumber = $versionLine.Matches[0].Groups[2].Value
New-Item -ItemType Directory -Path $buildPath | Out-Null

try {
    Write-Host 'Copying the project to an ASCII-only temporary path...'
    & robocopy $sourcePath $buildPath /E `
        /XD build .dart_tool .git .idea release `
        /XF '*.log' | Out-Null
    if ($LASTEXITCODE -ge 8) {
        throw "Project copy failed (robocopy exit code $LASTEXITCODE)."
    }

    Push-Location $buildPath
    try {
        & flutter pub get
        if ($LASTEXITCODE -ne 0) { throw 'flutter pub get failed.' }

        if ($Format -in @('apk', 'all')) {
            & flutter build apk --release
            if ($LASTEXITCODE -ne 0) { throw 'APK build failed.' }
        }

        if ($Format -in @('appbundle', 'all')) {
            & flutter build appbundle --release
            if ($LASTEXITCODE -ne 0) { throw 'App Bundle build failed.' }
        }
    }
    finally {
        Pop-Location
    }

    if ($Format -in @('apk', 'all')) {
        $apkSource = Join-Path $buildPath `
            'build\app\outputs\flutter-apk\app-release.apk'
        $apkOutputPath = Join-Path $sourcePath `
            'build\app\outputs\flutter-apk'
        New-Item -ItemType Directory -Force -Path $apkOutputPath | Out-Null
        $apkDestination = Join-Path $apkOutputPath 'app-release.apk'
        Copy-Item -LiteralPath $apkSource -Destination $apkDestination -Force
        Write-Host "APK ready: $apkDestination"
    }

    if ($Format -in @('appbundle', 'all')) {
        $bundleSource = Join-Path $buildPath `
            'build\app\outputs\bundle\release\app-release.aab'
        $bundleOutputPath = Join-Path $sourcePath `
            'build\app\outputs\bundle\release'
        New-Item -ItemType Directory -Force -Path $bundleOutputPath | Out-Null
        $bundleDestination = Join-Path $bundleOutputPath 'app-release.aab'
        Copy-Item -LiteralPath $bundleSource `
            -Destination $bundleDestination -Force
        Write-Host "App Bundle ready: $bundleDestination"
    }
}
finally {
    if (Test-Path -LiteralPath $buildPath) {
        Remove-Item -LiteralPath $buildPath -Recurse -Force
    }
}
