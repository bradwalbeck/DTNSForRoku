<#
.SYNOPSIS
   Compresses the 'channel' directory into a zip archive.

.DESCRIPTION
   This script compresses the files and folders within the 'channel' directory into a zip archive.
   The archive is saved in the 'builds' folder, and the filename starts with "DTNSForRoku"
   followed by a random four-digit hexadecimal number.

.EXAMPLE
   .\compress_script.ps1
   Compresses the 'channel' directory and saves the archive in the 'builds' folder.

.NOTES
   - Requires PowerShell 3.0 or later.
   - The script must be run with appropriate permissions to access the source and destination directories.
   - If the destination directory does not exist, the script will create it.

#>
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

#region How to run the file
<#
HOW TO RUN THIS SCRIPT:

1.  Save the script to a file, for example, compress_script.ps1.
2.  Open PowerShell.
3.  Navigate to the directory where you saved the script using the cd command.
    For example: cd C:\Repository\DTNSForRoku
4.  Execute the script using: .\compress_script.ps1
5.  The compressed file will be located in the 'builds' folder within the same directory as the script.

#>
#endregion