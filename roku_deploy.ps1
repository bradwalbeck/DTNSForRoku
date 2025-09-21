[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)][ValidatePattern('^\d{1,3}(\.\d{1,3}){3}$')][string]$DeviceIP,
    [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()][string]$Password,
    [Parameter(Mandatory=$true)][ValidateScript({ Test-Path -LiteralPath $_ })][string]$ZipPath,
    [int]$TimeoutSec = 120
)

$ErrorActionPreference = "Stop"

function Write-Info($msg){ Write-Host "[deploy] $msg" }

# Validate ZIP
$zipFull = (Resolve-Path -LiteralPath $ZipPath).Path
if ([IO.Path]::GetExtension($zipFull).ToLower() -ne ".zip") {
    throw "ZipPath must be a .zip file: $zipFull"
}

$uri = "http://$DeviceIP/plugin_install"
Write-Info "Target: $uri"
Write-Info "Package: $zipFull"

# Set up HttpClient with Digest-capable handler
$handler = New-Object System.Net.Http.HttpClientHandler
$handler.Credentials = New-Object System.Net.NetworkCredential("rokudev", $Password)
$handler.PreAuthenticate = $false
$handler.AllowAutoRedirect = $true
$client = New-Object System.Net.Http.HttpClient($handler)
$client.Timeout = [TimeSpan]::FromSeconds($TimeoutSec)

# Build multipart form: mysubmit=Install, archive=@file.zip
$multi = New-Object System.Net.Http.MultipartFormDataContent
$submit = New-Object System.Net.Http.StringContent("Install")
$multi.Add($submit, "mysubmit")

$fs = [System.IO.File]::OpenRead($zipFull)
try {
    $fileContent = New-Object System.Net.Http.StreamContent($fs)
    $fileContent.Headers.ContentType = [System.Net.Http.Headers.MediaTypeHeaderValue]::Parse("application/zip")
    $fileName = [IO.Path]::GetFileName($zipFull)
    $multi.Add($fileContent, "archive", $fileName)

    Write-Info "Uploading..."
    $resp = $client.PostAsync($uri, $multi).Result
    $body = $resp.Content.ReadAsStringAsync().Result

    Write-Info ("HTTP {0}" -f [int]$resp.StatusCode)

    if ($resp.IsSuccessStatusCode -and ($body -match "(?i)success|installed|application received")) {
        Write-Info "Install succeeded."
        exit 0
    } else {
        Write-Host $body
        throw "Install may have failed. See response above."
    }
}
finally {
    # Dispose in reverse order
    if ($multi) { $multi.Dispose() }
    if ($client) { $client.Dispose() }
    if ($fs)     { $fs.Dispose() }
}

<# Usage (Windows PowerShell):

powershell -ExecutionPolicy Bypass -File .\tools\roku_deploy.ps1 -DeviceIP 192.168.1.50 -Password your_dev_password -ZipPath .\dist\DTNSForRoku-1A2B.zip
Notes:

Auth user is always rokudev; password is your device’s dev password.
Script handles HTTP Digest automatically via HttpClientHandler.
Exits non-zero on failure so it can be used in CI.
 #>