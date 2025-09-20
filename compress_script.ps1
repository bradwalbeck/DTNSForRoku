# Set the source directory to the current directory
$Source = Get-Location

# Set the destination directory
$Destination = Join-Path -Path $Source -ChildPath "builds"

# Create the destination directory if it doesn't exist
if (!(Test-Path -Path $Destination)) {
    New-Item -ItemType Directory -Path $Destination
}

# Generate a random four-digit hexadecimal string
$RandomHex = [string]::Format('{0:X4}', (Get-Random -Minimum 0 -Maximum 65535))

# Set the archive file name
$ArchiveName = "DTNSForRoku_" + $RandomHex + ".zip"

# Set the full path to the archive file
$ArchivePath = Join-Path -Path $Destination -ChildPath $ArchiveName

# Compress the files and folders
Compress-Archive -Path $Source\* -DestinationPath $ArchivePath -Force

Write-Host "Successfully compressed to: $ArchivePath"