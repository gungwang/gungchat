[CmdletBinding(SupportsShouldProcess)]
param(
  [string]$ProjectRoot = ''
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$script:BuildInstallerCmdlet = $PSCmdlet

function Write-Step {
  param([string]$Message)

  Write-Host "==> $Message" -ForegroundColor Cyan
}

function Resolve-ProjectRoot {
  param([string]$ProjectRoot)

  if ([string]::IsNullOrWhiteSpace($ProjectRoot)) {
    return $PSScriptRoot
  }

  return (Resolve-Path $ProjectRoot).Path
}

function Get-PubspecVersion {
  param([string]$PubspecPath)

  $match = Select-String -Path $PubspecPath -Pattern '^\s*version:\s*([^\s#]+)' |
    Select-Object -First 1
  if (-not $match) {
    throw "Could not find a version entry in $PubspecPath"
  }

  return $match.Matches[0].Groups[1].Value.Trim()
}

function Get-InstallerVersion {
  param([string]$AppVersion)

  return ($AppVersion -split '\+', 2)[0]
}

function Sync-InstallerVersion {
  param(
    [string]$InstallerPath,
    [string]$InstallerVersion
  )

  $linePattern = '^\s*#define\s+MyAppVersion\s+"[^"]+"\s*$'
  $replacement = "#define MyAppVersion `"$InstallerVersion`""
  $lines = Get-Content -Path $InstallerPath
  $lineIndex = -1

  for ($index = 0; $index -lt $lines.Count; $index++) {
    if ($lines[$index] -match $linePattern) {
      $lineIndex = $index
      break
    }
  }

  if ($lineIndex -lt 0) {
    throw "Could not find MyAppVersion in $InstallerPath"
  }

  if ($lines[$lineIndex] -ceq $replacement) {
    return $false
  }

  $lines[$lineIndex] = $replacement
  $updated = [string]::Join([Environment]::NewLine, $lines)
  if (-not $updated.EndsWith([Environment]::NewLine)) {
    $updated += [Environment]::NewLine
  }

  [System.IO.File]::WriteAllText(
    $InstallerPath,
    $updated,
    [System.Text.Encoding]::ASCII
  )
  return $true
}

function Get-InnoSetupCompiler {
  $defaultPath = Join-Path $env:LOCALAPPDATA 'Programs\Inno Setup 6\ISCC.exe'
  if (Test-Path $defaultPath) {
    return $defaultPath
  }

  $command = Get-Command 'ISCC.exe' -ErrorAction SilentlyContinue
  if ($command) {
    return $command.Source
  }

  $command = Get-Command 'iscc' -ErrorAction SilentlyContinue
  if ($command) {
    return $command.Source
  }

  throw 'ISCC.exe was not found. Install Inno Setup 6 or add ISCC.exe to PATH.'
}

function Invoke-ExternalStep {
  param(
    [string]$Description,
    [string]$Target,
    [scriptblock]$Command
  )

  Write-Step $Description
  if (-not $script:BuildInstallerCmdlet.ShouldProcess($Target, $Description)) {
    return
  }

  & $Command
  if ($LASTEXITCODE -ne 0) {
    throw "$Description failed with exit code $LASTEXITCODE."
  }
}

$resolvedProjectRoot = Resolve-ProjectRoot -ProjectRoot $ProjectRoot
$pubspecPath = Join-Path $resolvedProjectRoot 'pubspec.yaml'
$installerPath = Join-Path $resolvedProjectRoot 'installer\gungchat.iss'
$installerOutputDir = Join-Path $resolvedProjectRoot 'installer\output'

if (-not (Test-Path $pubspecPath)) {
  throw "pubspec.yaml not found at $pubspecPath"
}
if (-not (Test-Path $installerPath)) {
  throw "Installer script not found at $installerPath"
}
if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
  throw 'flutter is not available on PATH.'
}

$appVersion = Get-PubspecVersion -PubspecPath $pubspecPath
$installerVersion = Get-InstallerVersion -AppVersion $appVersion
$isccPath = Get-InnoSetupCompiler

Write-Step "Using app version $appVersion"
Write-Step "Using Inno Setup compiler at $isccPath"

if ($script:BuildInstallerCmdlet.ShouldProcess(
    $installerPath,
    "Sync installer version to $installerVersion"
  )) {
  if (Sync-InstallerVersion -InstallerPath $installerPath -InstallerVersion $installerVersion) {
    Write-Host "Synced installer version to $installerVersion" -ForegroundColor Green
  } else {
    Write-Host "Installer version already matches $installerVersion" -ForegroundColor DarkGreen
  }
}

Push-Location $resolvedProjectRoot
try {
  if (Get-Process gungchat -ErrorAction SilentlyContinue) {
    Write-Warning 'gungchat.exe is running. If flutter build windows fails with a geolocator_windows_plugin.dll permission error, close the app and rerun this script.'
  }

  Invoke-ExternalStep -Description 'Running flutter pub get' -Target $resolvedProjectRoot -Command { flutter pub get }
  Invoke-ExternalStep -Description 'Building Windows release' -Target (Join-Path $resolvedProjectRoot 'build\windows\x64\runner\Release') -Command { flutter build windows }
  Invoke-ExternalStep -Description 'Compiling Windows installer' -Target $installerPath -Command { & $isccPath $installerPath }
} finally {
  Pop-Location
}

$installerFileName = "gungchat-setup-$installerVersion.exe"
$installerFilePath = Join-Path $installerOutputDir $installerFileName

if ($WhatIfPreference) {
  Write-Host "Expected installer output: $installerFilePath" -ForegroundColor Yellow
  return
}

if (-not (Test-Path $installerFilePath)) {
  throw "Installer build finished, but the expected output file was not found: $installerFilePath"
}

Write-Host "Installer ready: $installerFilePath" -ForegroundColor Green