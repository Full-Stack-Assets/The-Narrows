# Compile Mount Hope on Windows when Unreal Engine is installed.
# Usage:
#   .\Scripts\build.ps1
#   $env:UE_ROOT = "D:\Epic\UE_5.8"; .\Scripts\build.ps1
param(
    [string]$UeRoot = $env:UE_ROOT,
    [string]$Platform = $(if ($env:PLATFORM) { $env:PLATFORM } else { "Win64" }),
    [string]$Configuration = $(if ($env:CONFIGURATION) { $env:CONFIGURATION } else { "Development" }),
    [string]$Target = $(if ($env:TARGET) { $env:TARGET } else { "MountHopeEditor" })
)

$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Split-Path -Parent $ScriptDir
$UProject = Join-Path $ProjectRoot "MountHope.uproject"

function Find-UnrealEngineRoot {
    param([string]$PreferredRoot)

    if ($PreferredRoot -and (Test-Path $PreferredRoot)) {
        return (Resolve-Path $PreferredRoot).Path
    }

    $candidates = @(
        "C:\Program Files\Epic Games\UE_5.8",
        "C:\Program Files\Epic Games\UE_5.7",
        "C:\Program Files\Epic Games\UE_5.6",
        "C:\Program Files\Epic Games\UE_5.5",
        "D:\Epic Games\UE_5.8",
        "D:\Epic Games\UE_5.7",
        "D:\Epic Games\UE_5.6",
        "E:\Epic Games\UE_5.8",
        "E:\Epic Games\UE_5.7",
        "E:\Epic Games\UE_5.6"
    )

    foreach ($path in $candidates) {
        $runUbt = Join-Path $path "Engine\Build\BatchFiles\RunUBT.bat"
        if (Test-Path $runUbt) {
            return $path
        }
    }

    $epicRoot = "C:\Program Files\Epic Games"
    if (Test-Path $epicRoot) {
        $found = Get-ChildItem -Path $epicRoot -Directory -Filter "UE_5.*" |
            Sort-Object Name -Descending |
            Where-Object { Test-Path (Join-Path $_.FullName "Engine\Build\BatchFiles\RunUBT.bat") } |
            Select-Object -First 1
        if ($found) {
            return $found.FullName
        }
    }

    return $null
}

$UeRoot = Find-UnrealEngineRoot -PreferredRoot $UeRoot
if (-not $UeRoot) {
    Write-Error @"
Unreal Engine not found.

Install UE 5.8 from Epic Games Launcher, then either:
  1. Re-run this script (auto-detects C:\Program Files\Epic Games\UE_5.x), or
  2. Set UE_ROOT first:
       `$env:UE_ROOT = 'C:\Program Files\Epic Games\UE_5.8'
       .\Scripts\build.ps1
"@
}

$RunUbt = Join-Path $UeRoot "Engine\Build\BatchFiles\RunUBT.bat"
if (-not (Test-Path $RunUbt)) {
    Write-Error "RunUBT.bat not found at: $RunUbt"
}

Write-Host "Using UE_ROOT: $UeRoot"
Write-Host "Building $Target $Platform $Configuration ..."

& $RunUbt $Target $Platform $Configuration `
    -Project="$UProject" `
    -WaitMutex `
    -FromMsBuild

if ($LASTEXITCODE -ne 0) {
    Write-Error "Build failed with exit code $LASTEXITCODE"
}

Write-Host "Build succeeded."
