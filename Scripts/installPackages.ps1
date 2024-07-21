#This leverages the run command on the VM itself. 90 minute timeout.

#Download Files

$urls = @(
"https://steamcdn-a.akamaihd.net/client/installer/SteamSetup.exe",
"https://github.com/LizardByte/Sunshine/releases/latest/download/sunshine-windows-installer.exe",
"https://github.com/nomi-san/parsec-vdd/releases/download/v0.45.1/ParsecVDisplay-v0.45-setup.exe",
"https://raw.githubusercontent.com/bbabcock1990/cloud_gaming_vm/main/Scripts/config.zip",
"https://download.microsoft.com/download/9/1/e/91ed0d01-1a2c-46ad-b014-51ece3b1936c/amd-software-cloud-edition-23.q3-azure-ngads-v620.exe"
)

# Define the download directory
$downloadDir = "C:\Temp"

# Create the download directory if it doesn't exist
if (-not (Test-Path -Path $downloadDir)) {
    New-Item -ItemType Directory -Path $downloadDir
}

# Loop through each URL
foreach ($url in $urls) {
    # Extract the file name from the URL
    $fileName = [System.IO.Path]::GetFileName($url)
    # Define the full path to the downloaded file
    $filePath = Join-Path -Path $downloadDir -ChildPath $fileName
    # Download the file
    Invoke-WebRequest -Uri $url -OutFile $filePath
    # Install the file
    if ($fileName -ne "config.zip") {
        Start-Process -FilePath $filePath -ArgumentList "/S /silent" -Wait
    }
}

# Extract the Sunshine config ZIP file
Add-Type -AssemblyName System.IO.Compression.FileSystem
[System.IO.Compression.ZipFile]::ExtractToDirectory('C:\Temp\config.zip', 'C:\Temp') #Need to fix.

# Copy the extracted files to the destination folder, overwriting existing files
Copy-Item -Path "C:\Temp\config\*" -Destination 'C:\Program Files\Sunshine\config\' -Recurse -Force

Restart-Computer -Force