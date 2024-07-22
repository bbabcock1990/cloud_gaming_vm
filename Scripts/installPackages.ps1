# Set the progress preference to avoid displaying progress bars
$ProgressPreference = 'SilentlyContinue'

# Define the URLs to download
$urls = @(
    "https://steamcdn-a.akamaihd.net/client/installer/SteamSetup.exe",
    "https://github.com/LizardByte/Sunshine/releases/latest/download/sunshine-windows-installer.exe",
    "https://github.com/nomi-san/parsec-vdd/releases/download/v0.45.1/ParsecVDisplay-v0.45-setup.exe",
    "https://raw.githubusercontent.com/bbabcock1990/cloud_gaming_vm/main/Scripts/config.zip",
    "https://download.microsoft.com/download/9/1/e/91ed0d01-1a2c-46ad-b014-51ece3b1936c/amd-software-cloud-edition-23.q3-azure-ngads-v620.exe",
    "https://download.vb-audio.com/Download_CABLE/VBCABLE_Driver_Pack43.zip"
)

# Define the download directory
$downloadDir = "C:\Temp"

# Create the download directory if it doesn't exist
if (-not (Test-Path -Path $downloadDir)) {
    New-Item -ItemType Directory -Path $downloadDir -Force
}

# Function to download a file
function Download-File {
    param (
        [string]$url,
        [string]$outputPath
    )
    Invoke-WebRequest -Uri $url -OutFile $outputPath
}

# Start downloading files in parallel
$jobs = @()
foreach ($url in $urls) {
    $fileName = [System.IO.Path]::GetFileName($url)
    $filePath = Join-Path -Path $downloadDir -ChildPath $fileName
    $jobs += Start-Job -ScriptBlock { param($url, $filePath) Download-File -url $url -outputPath $filePath } -ArgumentList $url, $filePath
}

# Wait for all download jobs to complete
$jobs | ForEach-Object { Receive-Job -Job $_ -Wait }

# Start the installs for the required client applications in parallel
$installers = @(
    @{ Path = "C:\Temp\SteamSetup.exe"; Args = "/S" },
    @{ Path = "C:\Temp\sunshine-windows-installer.exe"; Args = "/S" },
    @{ Path = "C:\Temp\ParsecVDisplay-v0.45-setup.exe"; Args = "/silent" },
    @{ Path = "C:\Temp\amd-software-cloud-edition-23.q3-azure-ngads-v620.exe"; Args = "-Install" }
)

$installJobs = @()
foreach ($installer in $installers) {
    $installJobs += Start-Job -ScriptBlock { param($Path, $Args) Start-Process -FilePath $Path -ArgumentList $Args -Wait } -ArgumentList $installer.Path, $installer.Args
}

# Wait for all install jobs to complete
$installJobs | ForEach-Object { Receive-Job -Job $_ -Wait }

# Extract the Sunshine config ZIP file
Expand-Archive -Path "$downloadDir\config.zip" -DestinationPath "$downloadDir"

# Copy the extracted files to the destination folder, overwriting existing files
Copy-Item -Path "$downloadDir\config\*" -Destination 'C:\Program Files\Sunshine\config' -Recurse -Force

# Extract and install the Virtual Audio Drivers
Expand-Archive -Path "$downloadDir\VBCABLE_Driver_Pack43.zip" -DestinationPath "$downloadDir\VBCABLE_Driver_Pack43"
# Uncomment the line below if you want to install the driver automatically
# Start-Process -FilePath "$downloadDir\VBCABLE_Driver_Pack43\VBCABLE_Setup_x64.exe" -ArgumentList "-i" -Wait

# Schedule a reboot 1 minute after the script ends
$taskName = "ScheduledReboot"
$action = New-ScheduledTaskAction -Execute "shutdown.exe" -Argument "/r /f /t 0"
$trigger = New-ScheduledTaskTrigger -Once -At ((Get-Date).AddMinutes(1))
Register-ScheduledTask -Action $action -Trigger $trigger -TaskName $taskName -Description "Reboots the computer 1 minute after the script ends" -User "SYSTEM" -RunLevel Highest

# Confirm the task has been created
Write-Output "Scheduled a reboot 1 minute after the script ends."
