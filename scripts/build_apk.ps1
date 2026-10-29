[CmdletBinding()]
param(
    [ValidateSet("release", "profile", "debug")]
    [string]$Mode = "release",
    [ValidateSet("android-arm", "android-arm64", "android-x64")]
    [string]$TargetPlatform = "android-arm64",
    [ValidatePattern("^[a-z0-9]+(?:-[a-z0-9]+)*$")]
    [string]$Channel,
    [string]$ApiBaseUrl
)

$previousChannel = $env:VISTARA_CHANNEL
$projectRoot = Split-Path -Parent $PSScriptRoot
$enteredProject = $false

if ([string]::IsNullOrWhiteSpace($Channel)) {
    $Channel = switch ($Mode) {
        "release" { "stable" }
        "profile" { "beta" }
        "debug" { "development" }
    }
}

try {
    Push-Location $projectRoot
    $enteredProject = $true
    $env:VISTARA_CHANNEL = $Channel

    $flutterArguments = @(
        "build",
        "apk",
        "--$Mode",
        "--target-platform",
        $TargetPlatform
    )
    if (-not [string]::IsNullOrWhiteSpace($ApiBaseUrl)) {
        $flutterArguments += "--dart-define=VISTARA_API_BASE_URL=$ApiBaseUrl"
    }

    & flutter @flutterArguments
    if ($LASTEXITCODE -ne 0) {
        throw "Flutter APK build failed with exit code $LASTEXITCODE."
    }

    $versionMatch = [regex]::Match(
        (Get-Content "pubspec.yaml" -Raw),
        "(?m)^version:\s*(\d+\.\d+\.\d+)(?:\+(\d+))?\s*$"
    )
    if (-not $versionMatch.Success) {
        throw "Unable to read a valid semantic version from pubspec.yaml."
    }

    $revisionSuffix = if ($versionMatch.Groups[2].Success) {
        "-$($versionMatch.Groups[2].Value)"
    } else {
        ""
    }
    $artifactPrefix = "vistara-$($versionMatch.Groups[1].Value)-$Channel$revisionSuffix"
    $outputDirectory = Join-Path $projectRoot "build\app\outputs\flutter-apk"
    $artifacts = @(Get-ChildItem -LiteralPath $outputDirectory -File |
        Where-Object { $_.Name -like "$artifactPrefix*.apk" })
    if ($artifacts.Count -eq 0) {
        throw "Flutter completed, but no Vistara APK matching '$artifactPrefix' was generated."
    }

    Get-ChildItem -LiteralPath $outputDirectory -File |
        Where-Object {
            $_.Name -match "^app(?:-[a-z0-9-]+)?-$Mode\.apk(?:\.sha1)?$"
        } |
        Remove-Item -Force

    $artifacts | ForEach-Object { Write-Output "Vistara APK: $($_.FullName)" }
} finally {
    if ($enteredProject) {
        Pop-Location
    }
    if ($null -eq $previousChannel) {
        Remove-Item Env:VISTARA_CHANNEL -ErrorAction SilentlyContinue
    } else {
        $env:VISTARA_CHANNEL = $previousChannel
    }
}
