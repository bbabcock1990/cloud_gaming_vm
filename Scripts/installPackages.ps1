#This leverages the run command on the VM itself. 90 minute timeout.

# Download Files
# Speed up downloads by removing the "progress bars"
$ProgressPreference = 'SilentlyContinue'

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
}

# Start the installs for the required client applications
Start-Process -FilePath "C:\Temp\SteamSetup.exe" -ArgumentList "/S" -Wait
Start-Process -FilePath "C:\Temp\sunshine-windows-installer.exe" -ArgumentList "/S" -Wait
Start-Process -FilePath "C:\Temp\ParsecVDisplay-v0.45-setup.exe" -ArgumentList "/silent" -Wait
Start-Process -FilePath "C:\Temp\amd-software-cloud-edition-23.q3-azure-ngads-v620.exe" -ArgumentList "-Install" -Wait

# Extract the Sunshine config ZIP file
Expand-Archive -Path 'C:\Temp\config.zip' -DestinationPath 'C:\Temp'

# Copy the extracted files to the destination folder, overwriting existing files
Copy-Item -Path "C:\Temp\config\*" -Destination 'C:\Program Files\Sunshine\config' -Recurse -Force

# Extract and install the Virtual Audio Drivers
Expand-Archive -Path 'C:\Temp\VBCABLE_Driver_Pack43.zip' -DestinationPath 'C:\Temp\VBCABLE_Driver_Pack43'
Start-Process -FilePath 'C:\Temp\VBCABLE_Driver_Pack43\VBCABLE_Setup_x64.exe' -ArgumentList "-i" -Wait

# Restart the computer
# Define the task name
$taskName = "ScheduledReboot"

# Define the action to reboot the computer
$action = New-ScheduledTaskAction -Execute "shutdown.exe" -Argument "/r /f /t 0"

# Define the trigger to start 1 minute after the script ends
$trigger = New-ScheduledTaskTrigger -Once -At ((Get-Date).AddMinutes(1))

# Register the scheduled task
Register-ScheduledTask -Action $action -Trigger $trigger -TaskName $taskName -Description "Reboots the computer 1 minute after the script ends" -User "SYSTEM" -RunLevel Highest

# Confirm the task has been created
Write-Output "Scheduled a reboot 1 minute after the script ends."