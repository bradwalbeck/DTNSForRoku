# =============================================================================
# Name: build_and_deploy.ps1
# Path: tools\build_and_deploy.ps1
# Purpose: Package the channel and deploy it to a Roku device (reads root deploy.config.json).
# =============================================================================
[CmdletBinding()]
param(
    [string]$DeviceIP,
    [string]$Username,
    [string]$Password,
    [string]$ConfigPath,
    [string]$SourceDir,
    [string]$OutDir,
    [string]$ZipName = "DTNSForRoku.zip"
)

$ErrorActionPreference = "Stop"

# Resolve repo root and defaults
$repoRoot = Split-Path $PSScriptRoot -Parent
if ([string]::IsNullOrWhiteSpace($ConfigPath)) { $ConfigPath = Join-Path $repoRoot "deploy.config.json" }
if ([string]::IsNullOrWhiteSpace($SourceDir)) { $SourceDir  = Join-Path $repoRoot "channel" }
if ([string]::IsNullOrWhiteSpace($OutDir))    { $OutDir     = Join-Path $repoRoot "dist" }

# If config is missing at the expected path, show directions
if (-not (Test-Path -LiteralPath $ConfigPath)) {
    Write-Host "[build] Config file not found at: $ConfigPath"
    Write-Host "[build] Create the file at the project root with this content:"
    $example = @'
{
  "deviceIP": "192.168.1.50",
  "username": "rokudev",
  "password": "your_dev_password"
}
'@
    Write-Host $example
    Write-Host "[build] Or pass -DeviceIP and -Password on the command line."
}

# Load config (if present); CLI overrides config
if (Test-Path -LiteralPath $ConfigPath) {
    $cfg = Get-Content -LiteralPath $ConfigPath -Raw | ConvertFrom-Json
    if (-not $DeviceIP  -and $cfg.deviceIP) { $DeviceIP  = $cfg.deviceIP }
    if (-not $Username  -and $cfg.username) { $Username  = $cfg.username }
    if (-not $Password  -and $cfg.password) { $Password  = $cfg.password }
}
if (-not $DeviceIP) { throw "DeviceIP is required (via -DeviceIP or config file)" }
if (-not $Username) { $Username = "rokudev" }
if (-not $Password) { throw "Password is required (via -Password or config file)" }

# 1) Package
Write-Host "[build] Packaging..."
$compressScript = Join-Path $PSScriptRoot "compress_script.ps1"
if (-not (Test-Path -LiteralPath $compressScript)) { throw "compress_script.ps1 not found at $compressScript" }
powershell.exe -NoProfile -ExecutionPolicy Bypass -File $compressScript -SourceDir $SourceDir -OutDir $OutDir -ZipName $ZipName

# 2) Pick newest .zip from OutDir
$latest = Get-ChildItem -LiteralPath $OutDir -Filter *.zip | Sort-Object LastWriteTime -Descending | Select-Object -First 1
if (-not $latest) { throw "No ZIP found in $OutDir" }
$zipPath = $latest.FullName
Write-Host "[build] Using $zipPath"

# 3) Deploy to Roku
$deployScript = Join-Path $PSScriptRoot "roku_deploy.ps1"
if (-not (Test-Path -LiteralPath $deployScript)) { throw "Deploy script not found at $deployScript" }
powershell.exe -NoProfile -ExecutionPolicy Bypass -File $deployScript -DeviceIP $DeviceIP -Username $Username -Password $Password -ZipPath $zipPath -ConfigPath $ConfigPath