[CmdletBinding()]
param(
    [ValidateSet("release", "profile", "debug")]
    [string]$Mode = "release",
    [ValidateSet("android-arm", "android-arm64", "android-x64")]
    [string]$TargetPlatform = "android-arm64",
    [ValidatePattern("^[a-z0-9]+(?:-[a-z0-9]+)*$")]
    [string]$Channel,
    [string]$ApiBaseUrl,
    [switch]$AllowOfflinePreview
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

    if ([string]::IsNullOrWhiteSpace($ApiBaseUrl)) {
        $ApiBaseUrl = $env:VISTARA_API_BASE_URL
    }

    if ([string]::IsNullOrWhiteSpace($ApiBaseUrl)) {
        if ($Mode -eq "release" -and -not $AllowOfflinePreview) {
            throw (
                "A release APK requires a deployed HTTPS Vistara origin. " +
                "Pass -ApiBaseUrl or set VISTARA_API_BASE_URL. " +
                "Use -AllowOfflinePreview only for an intentional preview build."
            )
        }
    } else {
        $apiUri = $null
        if (-not [Uri]::TryCreate($ApiBaseUrl, [UriKind]::Absolute, [ref]$apiUri) -or
            @("http", "https") -notcontains $apiUri.Scheme -or
            [string]::IsNullOrWhiteSpace($apiUri.Host) -or
            -not [string]::IsNullOrEmpty($apiUri.UserInfo) -or
            $apiUri.Query -or
            $apiUri.Fragment -or
            $apiUri.AbsolutePath -ne "/") {
            throw "ApiBaseUrl must be an HTTP(S) origin without a path, query, or credentials."
        }
        if ($Mode -eq "release" -and $apiUri.Scheme -ne "https") {
            throw "Release APKs require an HTTPS Vistara origin."
        }
    }

    $flutterArguments = @(
        "build",
        "apk",
        "--$Mode",
        "--target-platform",
        $TargetPlatform
    )
    if (-not [string]::IsNullOrWhiteSpace($ApiBaseUrl)) {
        $flutterArguments += "--dart-define=VISTARA_API_BASE_URL=$ApiBaseUrl"
        $origin = [Uri]$ApiBaseUrl
        Write-Output "Embedding Vistara API origin: $($origin.GetLeftPart([UriPartial]::Authority))"
    } else {
        Write-Warning "Building without a Vistara API origin; live data and account features will be unavailable."
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
