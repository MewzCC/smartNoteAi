param(
    [switch]$Preview,
    [switch]$NoBuild
)

$ErrorActionPreference = 'Stop'

$projectRoot = Split-Path -Parent $PSScriptRoot
$pubspecPath = Join-Path $projectRoot 'pubspec.yaml'

if (-not (Test-Path $pubspecPath)) {
    throw "pubspec.yaml was not found. Please run this script inside the Flutter project."
}

$content = [System.IO.File]::ReadAllText($pubspecPath, [System.Text.Encoding]::UTF8)
$versionPattern = '(?m)^version:\s*([0-9]+)\.([0-9]+)\.([0-9]+)\+([0-9]+)\s*$'
$match = [regex]::Match($content, $versionPattern)

if (-not $match.Success) {
    throw "Invalid version. Expected a pubspec line like: version: 1.0.0+1"
}

$versionName = "$($match.Groups[1].Value).$($match.Groups[2].Value).$($match.Groups[3].Value)"
$currentBuildNumber = [int]$match.Groups[4].Value
$nextBuildNumber = $currentBuildNumber + 1
$nextVersionLine = "version: $versionName+$nextBuildNumber"

if ($Preview) {
    Write-Host "Current version: $versionName+$currentBuildNumber"
    Write-Host "Next build: $versionName+$nextBuildNumber"
    exit 0
}

$nextContent = [regex]::Replace($content, $versionPattern, $nextVersionLine, 1)
$utf8NoBom = [System.Text.UTF8Encoding]::new($false)
[System.IO.File]::WriteAllText($pubspecPath, $nextContent, $utf8NoBom)

Write-Host "Version updated: $versionName+$currentBuildNumber -> $versionName+$nextBuildNumber"

if ($NoBuild) {
    Write-Host "APK build skipped."
    exit 0
}

Push-Location $projectRoot
try {
    flutter pub get
    flutter build apk --release --build-name $versionName --build-number $nextBuildNumber
    Write-Host "APK generated: build\app\outputs\flutter-apk\app-release.apk"
}
finally {
    Pop-Location
}
