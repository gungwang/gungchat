[CmdletBinding()]
param(
  [string]$AvdName = 'Pixel_10',
  [string]$AppId = 'com.example.gungchat',
  [string]$ProjectRoot = '',
  [string]$GpuMode = 'swiftshader_indirect',
  [int]$SignalPort = 45454,
  [int]$ForwardPort = 45455,
  [switch]$PubGet,
  [switch]$SkipFlutterRun
)

$ErrorActionPreference = 'Stop'

function Write-Step {
  param([string]$Message)

  Write-Host "==> $Message" -ForegroundColor Cyan
}

function Get-AndroidSdkRoot {
  if ($env:ANDROID_SDK_ROOT -and (Test-Path $env:ANDROID_SDK_ROOT)) {
    return $env:ANDROID_SDK_ROOT
  }

  $defaultSdkRoot = Join-Path $env:LOCALAPPDATA 'Android\Sdk'
  if (Test-Path $defaultSdkRoot) {
    return $defaultSdkRoot
  }

  throw "Android SDK not found. Set ANDROID_SDK_ROOT or install the SDK under $defaultSdkRoot"
}

function Get-RunningEmulatorSerial {
  param(
    [string]$AdbExe,
    [string]$ExpectedAvdName
  )

  $emulatorCandidates = @()
  $deviceLines = & $AdbExe devices
  foreach ($line in $deviceLines) {
    if ($line -notmatch '^(emulator-\d+)\s+(device|offline)$') {
      continue
    }

    $emulatorCandidates += $matches[1]
  }

  foreach ($serial in $emulatorCandidates) {
    $resolvedAvdName = (& $AdbExe -s $serial emu avd name 2>$null | Out-String).Trim()
    if ($resolvedAvdName -eq $ExpectedAvdName) {
      return $serial
    }
  }

  if ($emulatorCandidates.Count -eq 1) {
    return $emulatorCandidates[0]
  }

  return $null
}

function Wait-ForEmulatorSerial {
  param(
    [string]$AdbExe,
    [string]$ExpectedAvdName,
    [int]$TimeoutSeconds = 180
  )

  $deadline = (Get-Date).AddSeconds($TimeoutSeconds)
  while ((Get-Date) -lt $deadline) {
    $serial = Get-RunningEmulatorSerial -AdbExe $AdbExe -ExpectedAvdName $ExpectedAvdName
    if ($serial) {
      return $serial
    }

    Start-Sleep -Seconds 2
  }

  throw "Timed out waiting for emulator '$ExpectedAvdName' to register with adb."
}

function Wait-ForAndroidBoot {
  param(
    [string]$AdbExe,
    [string]$Serial,
    [int]$TimeoutSeconds = 240
  )

  & $AdbExe -s $Serial wait-for-device | Out-Null

  $deadline = (Get-Date).AddSeconds($TimeoutSeconds)
  while ((Get-Date) -lt $deadline) {
    $bootCompleted = (& $AdbExe -s $Serial shell getprop sys.boot_completed 2>$null | Out-String).Trim()
    if ($bootCompleted -eq '1') {
      return
    }

    Start-Sleep -Seconds 2
  }

  throw "Timed out waiting for Android to finish booting on $Serial."
}

function Ensure-AvdExists {
  param(
    [string]$EmulatorExe,
    [string]$ExpectedAvdName
  )

  $availableAvds = & $EmulatorExe -list-avds
  if ($ExpectedAvdName -notin $availableAvds) {
    throw "AVD '$ExpectedAvdName' was not found. Available AVDs: $($availableAvds -join ', ')"
  }
}

$sdkRoot = Get-AndroidSdkRoot
$env:ANDROID_SDK_ROOT = $sdkRoot
$adbExe = Join-Path $sdkRoot 'platform-tools\adb.exe'
$emulatorExe = Join-Path $sdkRoot 'emulator\emulator.exe'

if (!(Test-Path $adbExe)) {
  throw "adb.exe not found at $adbExe"
}
if (!(Test-Path $emulatorExe)) {
  throw "emulator.exe not found at $emulatorExe"
}
if (!(Get-Command flutter -ErrorAction SilentlyContinue)) {
  throw 'flutter is not available on PATH.'
}

Ensure-AvdExists -EmulatorExe $emulatorExe -ExpectedAvdName $AvdName

Write-Step 'Starting adb server'
& $adbExe start-server | Out-Null

$deviceSerial = Get-RunningEmulatorSerial -AdbExe $adbExe -ExpectedAvdName $AvdName
if (!$deviceSerial) {
  Write-Step "Launching emulator '$AvdName' with GPU mode '$GpuMode'"
  $emulatorArgs = @(
    '-avd', $AvdName,
    '-gpu', $GpuMode,
    '-no-snapshot-load'
  )
  Start-Process -FilePath $emulatorExe -ArgumentList $emulatorArgs | Out-Null
  $deviceSerial = Wait-ForEmulatorSerial -AdbExe $adbExe -ExpectedAvdName $AvdName
} else {
  Write-Step "Using already running emulator '$AvdName' ($deviceSerial)"
}

Write-Step "Waiting for Android boot on $deviceSerial"
Wait-ForAndroidBoot -AdbExe $adbExe -Serial $deviceSerial

Write-Step "Configuring ADB bridge ports on $deviceSerial"
$forwardBindings = (& $adbExe -s $deviceSerial forward --list 2>$null | Out-String)
if ($forwardBindings -match "tcp:$ForwardPort") {
  & $adbExe -s $deviceSerial forward --remove "tcp:$ForwardPort" | Out-Null
}
& $adbExe -s $deviceSerial forward "tcp:$ForwardPort" "tcp:$SignalPort" | Out-Null

Write-Step "Force-stopping $AppId before launch"
& $adbExe -s $deviceSerial shell am force-stop $AppId | Out-Null
if ($SkipFlutterRun) {
  Write-Step "Emulator ready on $deviceSerial"
  Write-Host "ADB forward: host:$ForwardPort -> device:$SignalPort" -ForegroundColor Green
  Write-Host "Next command: flutter run -d $deviceSerial" -ForegroundColor Green
  exit 0
}

$resolvedProjectRoot = if ([string]::IsNullOrWhiteSpace($ProjectRoot)) {
  $PSScriptRoot
} else {
  (Resolve-Path $ProjectRoot).Path
}

Push-Location $resolvedProjectRoot
try {
  if ($PubGet) {
    Write-Step 'Running flutter pub get'
    & flutter pub get
    if ($LASTEXITCODE -ne 0) {
      exit $LASTEXITCODE
    }
  }

  Write-Step "Running flutter on $deviceSerial"
  & flutter run -d $deviceSerial
  if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
  }
} finally {
  Pop-Location
}
