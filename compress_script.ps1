try {
    #region Configuration
    $Source = Join-Path -Path (Get-Location) -ChildPath "channel"
    $Destination = Join-Path -Path (Get-Location) -ChildPath "builds"
    $RandomHex = [string]::Format('{0:X4}', (Get-Random -Minimum 0 -Maximum 65535))
    $ArchiveName = "DTNSForRoku_" + $RandomHex + ".zip"
    $ArchivePath = Join-Path -Path $Destination -ChildPath $ArchiveName
    #endregion

    #region Logging
    Write-Host "Source directory: $Source"
    Write-Host "Destination directory: $Destination"
    Write-Host "Archive path: $ArchivePath"
    #endregion

    #region Compress Archive
    Write-Host "Starting compression..."
    try {
        Compress-Archive -Path $Source\* -DestinationPath $ArchivePath -Force -ErrorAction Stop
        Write-Host "Compression completed successfully. Archive saved to: $ArchivePath"
    }
    catch {
        Write-Error "Compression failed: $($_.Exception.Message)"
        throw
    }
    #endregion

} catch {
    Write-Host "An error occurred: $($_.Exception.Message)"
}