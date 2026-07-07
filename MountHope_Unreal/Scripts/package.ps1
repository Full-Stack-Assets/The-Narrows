# Package Mount Hope for Windows (requires editor content and cooked maps).
param(
    [string]$UeRoot = $env:UE_ROOT,
    [string]$Platform = $(if ($env:PLATFORM) { $env:PLATFORM } else { "Win64" }),
    [string]$Configuration = $(if ($env:CONFIGURATION) { $env:CONFIGURATION } else { "Development" }),
    [string]$ArchiveDir = $(if ($env:ARCHIVE_DIR) { $env:ARCHIVE_DIR } else { "" })
)

$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Split-Path -Parent $ScriptDir
$UProject = Join-Path $ProjectRoot "MountHope.uproject"

if (-not $ArchiveDir) {
    $ArchiveDir = Join-Path $ProjectRoot "Packaged\$Platform"
}

if (-not $UeRoot) {
    $candidates = @(
        "C:\Program Files\Epic Games\UE_5.8",
        "C:\Program Files\Epic Games\UE_5.7",
        "C:\Program Files\Epic Games\UE_5.6",
        "D:\Epic Games\UE_5.8",
        "D:\Epic Games\UE_5.6"
    )
    foreach ($path in $candidates) {
        if (Test-Path (Join-Path $path "Engine\Build\BatchFiles\RunUAT.bat")) {
            $UeRoot = $path
            break
        }
    }
}

if (-not $UeRoot) {
    Write-Error "Set UE_ROOT to your engine install, e.g. `$env:UE_ROOT = 'C:\Program Files\Epic Games\UE_5.8'"
}

$RunUat = Join-Path $UeRoot "Engine\Build\BatchFiles\RunUAT.bat"
if (-not (Test-Path $RunUat)) {
    Write-Error "RunUAT.bat not found at: $RunUat"
}

New-Item -ItemType Directory -Force -Path $ArchiveDir | Out-Null

Write-Host "Using UE_ROOT: $UeRoot"
Write-Host "Packaging to: $ArchiveDir"

& $RunUat BuildCookRun `
    -project="$UProject" `
    -noP4 `
    -platform=$Platform `
    -clientconfig=$Configuration `
    -serverconfig=$Configuration `
    -cook `
    -build `
    -stage `
    -pak `
    -archive `
    -archivedirectory="$ArchiveDir"

if ($LASTEXITCODE -ne 0) {
    Write-Error "Package failed with exit code $LASTEXITCODE"
}

Write-Host "Package archived to: $ArchiveDir"
