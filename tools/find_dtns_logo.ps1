# =============================================================================
# Name: find_dtns_logo.ps1
# Path: tools\find_dtns_logo.ps1
# Purpose: Scan DTNS website and RSS feed for logo image URLs; optionally download.
# Usage:
#   .\tools\find_dtns_logo.ps1
#   .\tools\find_dtns_logo.ps1 -Download
# =============================================================================
[CmdletBinding()]
param(
    [switch]$Download,
    [string[]]$Sources = @(
        "https://dailytechnewsshow.com",
        "https://feeds.feedburner.com/daily_tech_news_show"
    ),
    [string]$OutDir = "c:\Repository\DTNSForRoku\channel\images"
)

$ErrorActionPreference = "Stop"

function Get-ImageUrlsFromHtml($html) {
    if (-not $html) { return @() }
    $rx = '(https?://[^\s"''<>]+?\.(?:png|jpg|jpeg|svg))'
    $opts = [Text.RegularExpressions.RegexOptions]::IgnoreCase
    [regex]::Matches($html, $rx, $opts) | ForEach-Object { $_.Groups[1].Value }
}

function Get-ImageUrlsFromRss($xmlText) {
    if (-not $xmlText) { return @() }
    $urls = @()
    try {
        [xml]$doc = $xmlText
        $u = $doc.rss.channel.image.url
        if ($u) { $urls += $u }
    } catch { }
    $urls += (Get-ImageUrlsFromHtml $xmlText)
    $urls
}

$all = New-Object System.Collections.Generic.List[string]
foreach ($src in $Sources) {
    try {
        Write-Host "[logo] Fetching $src"
        $r = Invoke-WebRequest -UseBasicParsing -Uri $src -TimeoutSec 30
        $text = $r.Content
        if ($src -match 'feeds|xml') {
            $all.AddRange((Get-ImageUrlsFromRss $text))
        } else {
            $all.AddRange((Get-ImageUrlsFromHtml $text))
        }
    } catch {
        Write-Warning ("Fetch failed for {0}: {1}" -f $src, $_.Exception.Message)
    }
}

# Filter for likely DTNS logo candidates
$candidates = $all `
    | Sort-Object -Unique `
    | Where-Object {
        $_ -match '(?i)(dtns|dailytechnews)' -or $_ -match '(?i)\blogo\b'
    }

if ($candidates.Count -eq 0) {
    Write-Host "[logo] No candidate image URLs found. Try adding more sources (e.g., specific pages)."
    return
}

Write-Host "[logo] Candidate image URLs:"
$candidates | ForEach-Object { Write-Host " - $_" }

if ($Download) {
    if (-not (Test-Path -LiteralPath $OutDir)) { New-Item -ItemType Directory -Path $OutDir | Out-Null }
    foreach ($u in $candidates) {
        try {
            $name = [IO.Path]::GetFileName((New-Object System.Uri($u)).AbsolutePath)
            if (-not $name) { $name = "dtns_logo" }
            $dest = Join-Path $OutDir $name
            Write-Host ("[logo] Downloading {0} -> {1}" -f $u, $dest)
            Invoke-WebRequest -UseBasicParsing -Uri $u -OutFile $dest -TimeoutSec 60
        } catch {
            Write-Warning ("Download failed for {0}: {1}" -f $u, $_.Exception.Message)
        }
    }
    Write-Host "[logo] Downloads complete. Review images in $OutDir and pick the rainbow DTNS logo."
    Write-Host "[logo] Update manifest icon paths after you choose the final files."
}

Write-Host "[logo] Note: Ensure you have rights to use the DTNS logo. Obtain permission if required."