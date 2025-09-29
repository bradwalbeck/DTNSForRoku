# =============================================================================
# Name: roku_deploy.ps1
# Path: tools\roku_deploy.ps1
# Purpose: Upload a ZIP package to the Roku Development Application Installer using Digest auth.
# =============================================================================
[CmdletBinding()]
param(
    [string]$DeviceIP,
    [string]$Username,
    [string]$Password,
    [Parameter(Mandatory=$true)][ValidateScript({ Test-Path -LiteralPath $_ })][string]$ZipPath,
    [string]$ConfigPath,
    [int]$TimeoutSec = 180
)

$ErrorActionPreference = "Stop"
function Info($m){ Write-Host "[deploy] $m" }

# Default config path to repo root if not supplied
if ([string]::IsNullOrWhiteSpace($ConfigPath)) {
    $repoRoot = Split-Path $PSScriptRoot -Parent
    $ConfigPath = Join-Path $repoRoot "deploy.config.json"
}

# If config is missing at the expected path, show directions
if (-not (Test-Path -LiteralPath $ConfigPath)) {
    Write-Host "[deploy] Config file not found at: $ConfigPath"
    Write-Host "[deploy] Create the file at the project root with this content:"
    $example = @'
{
  "deviceIP": "192.168.1.50",
  "username": "rokudev",
  "password": "your_dev_password"
}
'@
    Write-Host $example
    Write-Host "[deploy] Or pass -DeviceIP and -Password on the command line."
}

# Load config (CLI overrides config)
if (Test-Path -LiteralPath $ConfigPath) {
    $cfg = Get-Content -LiteralPath $ConfigPath -Raw | ConvertFrom-Json
    if (-not $DeviceIP  -and $cfg.deviceIP) { $DeviceIP  = $cfg.deviceIP }
    if (-not $Username  -and $cfg.username) { $Username  = $cfg.username }
    if (-not $Password  -and $cfg.password) { $Password  = $cfg.password }
}
if (-not $DeviceIP) { throw "DeviceIP is required (via -DeviceIP or config file)" }
if (-not $Username) { $Username = "rokudev" }
if (-not $Password) { throw "Password is required (via -Password or config file)" }

$zipFull = (Resolve-Path -LiteralPath $ZipPath).Path
if ([IO.Path]::GetExtension($zipFull).ToLower() -ne ".zip") { throw "ZipPath must point to a .zip file" }

$uri = "http://$DeviceIP/plugin_install"
Info "Target: $uri"
Info "User: $Username"
Info "Package: $zipFull"

# Prefer curl.exe (fully compatible with Roku installer)
$curl = Get-Command curl.exe -ErrorAction SilentlyContinue
if ($curl) {
    Info "Uploading with curl (Digest auth)..."
    $args = @(
        "-sS", "-L",
        "--digest",
        "-u", "$Username`:$Password",
        "-F", "mysubmit=Install",
        "-F", "archive=@$zipFull;type=application/zip",
        "$uri"
    )
    $curlOut = & $curl.Path @args 2>&1
    # Check for common success markers
    if ($LASTEXITCODE -eq 0 -and ($curlOut -match '(?is)(Install Success|Application received|successfully installed|Install complete|Install Success\.)')) {
        Info "Install succeeded."
        return
    } else {
        Write-Host $curlOut
        Info "curl path failed; falling back to PowerShell web client..."
    }
}

# Fallback: Invoke-WebRequest with Digest and session
try {
    $cred = New-Object System.Management.Automation.PSCredential($Username, (ConvertTo-SecureString $Password -AsPlainText -Force))
    $sess = New-Object Microsoft.PowerShell.Commands.WebRequestSession

    # Prime auth and any cookies
    try { Invoke-WebRequest -UseBasicParsing -Method Get -Uri $uri -Authentication Digest -Credential $cred -WebSession $sess -TimeoutSec $TimeoutSec | Out-Null } catch {}

    $form = @{
        mysubmit = 'Install'
        archive  = Get-Item -LiteralPath $zipFull
    }
    Info "Uploading with Invoke-WebRequest (Digest auth)..."
    $resp = Invoke-WebRequest -Uri $uri -Method Post -Authentication Digest -Credential $cred -Form $form -WebSession $sess -TimeoutSec $TimeoutSec
    Info ("HTTP {0}" -f [int]$resp.StatusCode)
    $body = $resp.Content

    if ($resp.StatusCode -eq 200 -and ($body -match '(?is)(Install Success|Application received|successfully installed|Install complete|Install Success\.)')) {
        Info "Install succeeded."
    } else {
        Write-Host $body
        throw "Install failed or unknown response."
    }
} catch {
    throw
}