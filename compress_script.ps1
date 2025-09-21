[CmdletBinding()]
param(
    [Parameter()][ValidateNotNullOrEmpty()][string]$SourceDir = "c:\Repository\DTNSForRoku\channel",
    [Parameter()][ValidateNotNullOrEmpty()][string]$OutDir    = "c:\Repository\DTNSForRoku\dist",
    [Parameter()][ValidateNotNullOrEmpty()][string]$ZipName   = "DTNSForRoku.zip"
)

$ErrorActionPreference = "Stop"

function Write-Info($msg) { Write-Host "[pack] $msg" }
function Write-Err($msg)  { Write-Host "[pack] ERROR: $msg" -ForegroundColor Red }

# Unique ZIP name: append 4-digit hex
$base = [IO.Path]::GetFileNameWithoutExtension($ZipName)
$ext  = [IO.Path]::GetExtension($ZipName)
if ([string]::IsNullOrWhiteSpace($ext)) { $ext = ".zip" }
$suffix = "{0:X4}" -f (Get-Random -Minimum 0 -Maximum 0x10000)
$zipNameWithSuffix = "$base-$suffix$ext"

# Validate source layout
if (-not (Test-Path -LiteralPath $SourceDir)) { throw "SourceDir not found: $SourceDir" }
$manifestPath = Join-Path $SourceDir "manifest"
if (-not (Test-Path -LiteralPath $manifestPath)) { throw "Manifest not found at: $manifestPath" }
$sourcePath = Join-Path $SourceDir "source"
if (-not (Test-Path -LiteralPath $sourcePath)) { throw "source/ folder not found: $sourcePath" }

# Prepare output
if (-not (Test-Path -LiteralPath $OutDir)) { New-Item -ItemType Directory -Path $OutDir | Out-Null }
$zipPath = Join-Path $OutDir $zipNameWithSuffix
if (Test-Path -LiteralPath $zipPath) { Remove-Item -LiteralPath $zipPath -Force }

# Exclusion patterns (regex on full path)
$excludeDirPatterns  = @('\.git(\\|$)', '\.vscode(\\|$)', '\.idea(\\|$)', '\.svn(\\|$)', 'node_modules(\\|$)', 'dist(\\|$)', 'build(\\|$)', 'out(\\|$)', 'tmp(\\|$)')
$excludeFilePatterns = @('\.DS_Store$', 'Thumbs\.db$', '\.zip$', '\.pkg$')

function ShouldSkip($fullPath) {
    foreach ($rx in $script:excludeDirPatterns)  { if ($fullPath -match $rx) { return $true } }
    foreach ($rx in $script:excludeFilePatterns) { if ($fullPath -match $rx) { return $true } }
    return $false
}

# Ensure ZipFile API available
Add-Type -AssemblyName System.IO.Compression.FileSystem

Write-Info "Creating archive: $zipPath"
$zip = [System.IO.Compression.ZipFile]::Open($zipPath, [System.IO.Compression.ZipArchiveMode]::Create)
try {
    $srcFull = (Resolve-Path -LiteralPath $SourceDir).Path
    $srcLen  = $srcFull.Length

    Get-ChildItem -LiteralPath $srcFull -Recurse -File | ForEach-Object {
        $full = $_.FullName
        if (ShouldSkip $full) { return }

        # Relative path inside ZIP (manifest and folders at archive root)
        $rel = $full.Substring($srcLen).TrimStart('\','/')
        $rel = $rel -replace '\\','/'

        [System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile(
            $zip, $full, $rel, [System.IO.Compression.CompressionLevel]::Optimal
        ) | Out-Null
    }
}
finally {
    $zip.Dispose()
}

# Validate Roku structure (manifest and source/ at root)
$hasManifest = $false
$hasSource   = $false
$zipRead = [System.IO.Compression.ZipFile]::OpenRead($zipPath)
try {
    foreach ($entry in $zipRead.Entries) {
        if ($entry.FullName -eq "manifest") { $hasManifest = $true }
        if ($entry.FullName.StartsWith("source/")) { $hasSource = $true }
        if ($hasManifest -and $hasSource) { break }
    }
}
finally {
    $zipRead.Dispose()
}

if (-not $hasManifest -or -not $hasSource) {
    Write-Err "Validation failed. Expect 'manifest' and 'source/' at ZIP root."
    throw "Roku ZIP structure invalid: $zipPath"
}

Write-Info "OK: $zipPath"
Write-Info "Upload via Roku Development Application Installer."