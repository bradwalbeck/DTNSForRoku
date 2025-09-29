# =============================================================================
# Name: compress_script.ps1
# Path: tools\compress_script.ps1
# Purpose: Create a Roku-compliant ZIP (manifest + source at archive root).
# Notes: Appends random 4-digit hex to output filename for uniqueness.
# =============================================================================
[CmdletBinding()]
param(
    [string]$SourceDir = "c:\Repository\DTNSForRoku\channel",
    [string]$OutDir    = "c:\Repository\DTNSForRoku\dist",
    [string]$ZipName   = "DTNSForRoku.zip"
)

$ErrorActionPreference = "Stop"

function Write-Info($msg) { Write-Host "[pack] $msg" }
function Write-Err($msg)  { Write-Host "[pack] ERROR: $msg" -ForegroundColor Red }

# Unique filename suffix (4-digit hex)
$base = [IO.Path]::GetFileNameWithoutExtension($ZipName)
$ext  = [IO.Path]::GetExtension($ZipName); if ([string]::IsNullOrWhiteSpace($ext)) { $ext = ".zip" }
$suffix = "{0:X4}" -f (Get-Random -Minimum 0 -Maximum 0x10000)
$ZipNameWithSuffix = "$base-$suffix$ext"

# Validate source structure
if (-not (Test-Path -LiteralPath $SourceDir)) { throw "SourceDir not found: $SourceDir" }
$manifestPath = Join-Path $SourceDir "manifest"
if (-not (Test-Path -LiteralPath $manifestPath)) { throw "Manifest not found at: $manifestPath" }

# Prepare output
if (-not (Test-Path -LiteralPath $OutDir)) { New-Item -ItemType Directory -Path $OutDir | Out-Null }
$zipPath = Join-Path $OutDir $ZipNameWithSuffix
if (Test-Path -LiteralPath $zipPath) { Remove-Item -LiteralPath $zipPath -Force }

# Try to load compression types; fallback to Compress-Archive
$hasZipTypes = $false
try {
    Add-Type -AssemblyName System.IO.Compression | Out-Null
    Add-Type -AssemblyName System.IO.Compression.FileSystem | Out-Null
    $null = [System.IO.Compression.ZipArchiveMode]
    $hasZipTypes = $true
} catch { $hasZipTypes = $false }

if ($hasZipTypes) {
    Write-Info "Creating archive: $zipPath"
    $excludeDirPatterns = @('\.git(\\|$)', '\.vscode(\\|$)', '\.idea(\\|$)', '\.svn(\\|$)', 'node_modules(\\|$)', 'dist(\\|$)', 'build(\\|$)', 'out(\\|$)', 'tmp(\\|$)')
    $excludeFilePatterns = @('\.DS_Store$', 'Thumbs\.db$', '\.zip$', '\.pkg$')

    $zip = [System.IO.Compression.ZipFile]::Open($zipPath, [System.IO.Compression.ZipArchiveMode]::Create)
    try {
        $srcFull = (Resolve-Path -LiteralPath $SourceDir).Path
        $srcLen  = $srcFull.Length
        Get-ChildItem -LiteralPath $srcFull -Recurse -File | ForEach-Object {
            $full = $_.FullName
            foreach ($rx in $excludeDirPatterns)  { if ($full -match $rx) { return } }
            foreach ($rx in $excludeFilePatterns) { if ($full -match $rx) { return } }
            $relPath = $full.Substring($srcLen).TrimStart('\','/') -replace '\\','/'
            [System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile(
                $zip, $full, $relPath, [System.IO.Compression.CompressionLevel]::Optimal
            ) | Out-Null
        }
    } finally { $zip.Dispose() }
} else {
    Write-Info "Creating archive via Compress-Archive: $zipPath"
    Compress-Archive -Path (Join-Path $SourceDir "*") -DestinationPath $zipPath -CompressionLevel Optimal -Force
}

# Validate ZIP contents
$ok = $false; $hasManifest = $false; $hasSource = $false
try {
    Add-Type -AssemblyName System.IO.Compression | Out-Null
    $zr = [System.IO.Compression.ZipFile]::OpenRead($zipPath)
    try {
        foreach ($e in $zr.Entries) {
            if ($e.FullName -eq "manifest") { $hasManifest = $true }
            if ($e.FullName.StartsWith("source/")) { $hasSource = $true }
            if ($hasManifest -and $hasSource) { $ok = $true; break }
        }
    } finally { $zr.Dispose() }
} catch { $ok = Test-Path -LiteralPath $zipPath }

if (-not $ok) {
    Write-Err "Validation failed. Expect 'manifest' and 'source/' at ZIP root."
    throw "Roku ZIP structure invalid."
}

Write-Info "OK: $zipPath"
Write-Info "Upload via Roku Development Application Installer."