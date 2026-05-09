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

$currentMajor = [int]$match.Groups[1].Value
$currentMinor = [int]$match.Groups[2].Value
$currentPatch = [int]$match.Groups[3].Value
$versionName = "$currentMajor.$currentMinor.$currentPatch"
$currentBuildNumber = [int]$match.Groups[4].Value

function Get-NextVersionName {
    param(
        [int]$Major,
        [int]$Minor,
        [int]$Patch
    )

    $nextPatch = $Patch + 1
    $nextMinor = $Minor
    $nextMajor = $Major

    if ($nextPatch -ge 10) {
        $nextPatch = 0
        $nextMinor += 1
    }

    if ($nextMinor -ge 10) {
        $nextMinor = 0
        $nextMajor += 1
    }

    return "$nextMajor.$nextMinor.$nextPatch"
}

$nextVersionName = Get-NextVersionName -Major $currentMajor -Minor $currentMinor -Patch $currentPatch
$nextBuildNumber = $currentBuildNumber + 1
$nextVersionLine = "version: $nextVersionName+$nextBuildNumber"

if ($Preview) {
    Write-Host "Current version: $versionName"
    Write-Host "Current build number: $currentBuildNumber"
    Write-Host "Next version: $nextVersionName"
    Write-Host "Next build number: $nextBuildNumber"
    exit 0
}

$androidKeyPropertiesPath = Join-Path $projectRoot 'android\key.properties'
if (-not $NoBuild -and -not (Test-Path $androidKeyPropertiesPath)) {
    throw @"
Release signing config was not found: android\key.properties

Create a fixed release keystore before building:
1. Copy android\key.properties.example to android\key.properties
2. Generate android\app\smartnote-release.jks with keytool
3. Keep both files private and backed up
"@
}

$nextContent = [regex]::Replace($content, $versionPattern, $nextVersionLine, 1)
$utf8NoBom = [System.Text.UTF8Encoding]::new($false)
[System.IO.File]::WriteAllText($pubspecPath, $nextContent, $utf8NoBom)

Write-Host "Version updated: $versionName+$currentBuildNumber -> $nextVersionName+$nextBuildNumber"

if ($NoBuild) {
    Write-Host "APK build skipped."
    exit 0
}

Push-Location $projectRoot
try {
    flutter pub get
    flutter build apk --release --build-name $nextVersionName --build-number $nextBuildNumber

    $sourceApk = Join-Path $projectRoot 'build\app\outputs\flutter-apk\app-release.apk'
    if (-not (Test-Path $sourceApk)) {
        throw "Release APK was not found: $sourceApk"
    }

    $workspaceRoot = if ($env:GITHUB_WORKSPACE) { $env:GITHUB_WORKSPACE } else { $projectRoot }
    $artifactDir = Join-Path $workspaceRoot 'artifacts'
    New-Item -ItemType Directory -Path $artifactDir -Force | Out-Null

    $versionedApkName = "SmartNote-v$nextVersionName.apk"
    $versionedApkPath = Join-Path $artifactDir $versionedApkName
    Copy-Item -Path $sourceApk -Destination $versionedApkPath -Force

    Write-Host "Version: $nextVersionName"
    Write-Host "Build number: $nextBuildNumber"
    Write-Host "APK generated: build\app\outputs\flutter-apk\app-release.apk"
    Write-Host "Versioned APK copied: $versionedApkPath"
}
finally {
    Pop-Location
}
