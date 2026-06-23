[CmdletBinding()]
param(
    [string]$RuntimeDir = "",
    [string]$OutputDir = "",
    [string]$ArchivePrefix = "rizin-windows-x64-bundle"
)

$ErrorActionPreference = "Stop"

$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
if (-not $RuntimeDir) {
    $RuntimeDir = Join-Path $scriptRoot "..\build\rizin"
}
if (-not $OutputDir) {
    $OutputDir = Join-Path $scriptRoot "..\build"
}

$repoRoot = (Resolve-Path -LiteralPath (Join-Path $scriptRoot "..")).Path
$runtimePath = (Resolve-Path -LiteralPath $RuntimeDir).Path
$outputPath = (Resolve-Path -LiteralPath $OutputDir).Path

$runtimeRoot = Join-Path $repoRoot "build"
if (-not $runtimePath.StartsWith($runtimeRoot, [System.StringComparison]::OrdinalIgnoreCase)) {
    throw "RuntimeDir must be inside the repository build directory: $runtimePath"
}

$tag = (& git -C $repoRoot describe --tags --abbrev=0 2>$null).Trim()
if (-not $tag) {
    throw "No Git tag found. Create a release tag first, for example: git tag v0.1.0"
}

$archiveName = "$ArchivePrefix-$tag.zip"
$archivePath = Join-Path $outputPath $archiveName
$stage = Join-Path ([System.IO.Path]::GetTempPath()) ("rizin-bundle-stage-" + [guid]::NewGuid().ToString("N"))

try {
    New-Item -ItemType Directory -Path $stage | Out-Null
    Copy-Item -LiteralPath $runtimePath -Destination $stage -Recurse -Force
    Compress-Archive -Path (Join-Path $stage "rizin") -DestinationPath $archivePath -Force
}
finally {
    if (Test-Path -LiteralPath $stage) {
        Remove-Item -LiteralPath $stage -Recurse -Force
    }
}

Write-Host "Created $archivePath"
